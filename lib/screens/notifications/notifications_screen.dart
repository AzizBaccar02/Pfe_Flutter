// lib/screens/notifications/notifications_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../models/app_notification_model.dart';
import '../../models/interested_agent_model.dart';
import '../../services/interaction_service.dart';
import '../../services/notification_realtime_hub.dart';
import '../../services/notification_router.dart';
import '../../services/notification_service.dart';
import '../../services/notification_enrichment_service.dart';
import '../../services/offer_reaction_service.dart';
import '../offers/client/client_agent_interest_screen.dart';
import 'widgets/notification_inbox_tile.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onNotificationsRead;
  final ValueChanged<InterestedAgentModel>? onAgentAccepted;

  const NotificationsScreen({
    super.key,
    this.onNotificationsRead,
    this.onAgentAccepted,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRealtimeHub _hub = NotificationRealtimeHub.instance;

  StreamSubscription<AppNotificationModel>? _notificationSubscription;

  bool _isLoading = true;
  String? _errorMessage;
  List<AppNotificationModel> _notifications = [];
  final Map<int, NotificationInboxResponse> _localResponses = {};
  final Set<int> _respondingIds = {};

  static const _accentGreen = Color(0xFF22C55E);
  static const _backgroundColor = Colors.black;
  static const _primaryTextColor = Colors.white;
  static const _secondaryTextColor = Color(0xFF9CA3AF);
  static const _dividerColor = Color(0xFF1F1F1F);

  @override
  void initState() {
    super.initState();
    _hub.setInboxOpen(true);
    _bootstrapNotificationsScreen();
  }

  @override
  void dispose() {
    _hub.setInboxOpen(false);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bootstrapNotificationsScreen() async {
    await _hub.ensureStarted();

    _notificationSubscription = _hub.onNotification.listen(
      _handleIncomingNotification,
    );

    await _loadNotifications(markRead: false);
  }

  void _handleIncomingNotification(AppNotificationModel notification) {
    if (!mounted) return;

    NotificationEnrichmentService.enrichOne(notification).then((enriched) {
      if (!mounted) return;

      setState(() {
        final alreadyExists = _notifications.any(
          (item) => item.id == enriched.id,
        );

        if (!alreadyExists) {
          _notifications = [
            enriched.copyWith(isRead: true),
            ..._notifications,
          ];
        }
      });

      widget.onNotificationsRead?.call();
    });
  }

  Future<void> _loadNotifications({bool markRead = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      var notifications = await _hub.fetchNotifications();
      notifications =
          await NotificationEnrichmentService.enrich(notifications);

      if (markRead && notifications.any((item) => !item.isRead)) {
        await _hub.markAllAsRead();
        widget.onNotificationsRead?.call();
      }

      if (!mounted) return;

      setState(() {
        _notifications = notifications
            .map((item) => item.copyWith(isRead: true))
            .toList();
      });
    } on NotificationServiceException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load notifications.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleNotificationTap(AppNotificationModel notification) async {
    final resolved =
        await NotificationEnrichmentService.enrichOne(notification);

    if (resolved.isAgentInterestNotification &&
        (_localResponses[notification.id] ?? NotificationInboxResponse.none) ==
            NotificationInboxResponse.none) {
      final offerId = resolved.offerId;
      final agentId = resolved.agentId;

      if (offerId == null || agentId == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Missing offer or agent info in this notification.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final acceptedAgent = await Navigator.push<InterestedAgentModel>(
        context,
        MaterialPageRoute(
          builder: (_) => ClientAgentInterestScreen(
            offerId: offerId,
            agentId: agentId,
            agentName: resolved.resolvedAgentName ?? resolved.agentName,
            agentEmail: resolved.agentEmail,
            offerTitle: resolved.offerTitle,
            interactionId: resolved.interactionId,
            interestMessage: resolved.body,
            avatarUrl: resolved.avatarUrl,
          ),
        ),
      );

      if (acceptedAgent != null && mounted) {
        setState(() {
          _localResponses[notification.id] =
              NotificationInboxResponse.accepted;
        });
        widget.onAgentAccepted?.call(acceptedAgent);
      }

      return;
    }

    if (!notification.isActionable) return;

    final acceptedAgent =
        await NotificationRouter.handle(context, notification);

    if (acceptedAgent != null && mounted) {
      widget.onAgentAccepted?.call(acceptedAgent);
    }
  }

  Future<void> _respondInline(
    AppNotificationModel notification, {
    required bool accept,
  }) async {
    if (_respondingIds.contains(notification.id)) return;

    final resolved =
        await NotificationEnrichmentService.enrichOne(notification);

    setState(() {
      _respondingIds.add(notification.id);
    });

    try {
      await _respondToNotification(resolved, accept: accept);

      if (!mounted) return;

      setState(() {
        _localResponses[notification.id] = accept
            ? NotificationInboxResponse.accepted
            : NotificationInboxResponse.rejected;
      });

      if (accept) {
        final agent = _resolveAgent(resolved);
        if (agent != null) {
          widget.onAgentAccepted?.call(agent);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1A1A1A),
            content: Text(
              accept
                  ? 'Interest accepted.'
                  : 'Interest declined.',
            ),
          ),
        );
      }
    } on InteractionServiceException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(e.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Unable to update this interest.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _respondingIds.remove(notification.id);
        });
      }
    }
  }

  Future<void> _respondToNotification(
    AppNotificationModel notification, {
    required bool accept,
  }) async {
    var interactionId = notification.interactionId;

    if (interactionId == null || interactionId <= 0) {
      final offerId = notification.offerId;
      final agentId = notification.agentId;

      if (offerId == null || agentId == null) {
        throw const InteractionServiceException('Missing offer or agent info.');
      }

      final pending = await InteractionService.getPendingForOffer(offerId);
      final matches = pending
          .where(
            (item) =>
                item.agentId == agentId || item.agentUserId == agentId,
          )
          .toList();
      interactionId = matches.isNotEmpty ? matches.first.id : null;
    }

    if (interactionId == null || interactionId <= 0) {
      throw const InteractionServiceException(
        'Could not find a pending interest for this notification.',
      );
    }

    await InteractionService.respondToInteraction(
      interactionId: interactionId,
      accept: accept,
      offerId: notification.offerId,
    );
  }

  InterestedAgentModel? _resolveAgent(AppNotificationModel notification) {
    final offerId = notification.offerId;
    final agentId = notification.agentId;

    if (offerId == null || agentId == null) return null;

    return OfferReactionService.findInterestedAgent(
          offerId: offerId,
          agentId: agentId,
        ) ??
        InterestedAgentModel(
          id: agentId,
          name: notification.resolvedAgentName ??
              notification.agentName ??
              notification.actorDisplayName,
          jobTitle: 'Interested agent',
          city: '—',
          rating: 4.5,
          completedJobs: 0,
          imageUrl: 'assets/images/agent1.jpg',
          offerId: offerId,
          offerTitle: notification.offerTitle ?? '',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _accentGreen,
            size: 18,
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: _primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _accentGreen,
          strokeWidth: 2.4,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _secondaryTextColor,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return RefreshIndicator(
        color: _accentGreen,
        onRefresh: () => _loadNotifications(markRead: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
            const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01,
                color: _accentGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No notifications yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'When an agent likes your offer or responds to your request, updates will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _accentGreen,
      onRefresh: () => _loadNotifications(markRead: false),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 120),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          thickness: 1,
          color: _dividerColor,
        ),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final localResponse =
              _localResponses[notification.id] ?? NotificationInboxResponse.none;
          final isResponding = _respondingIds.contains(notification.id);

          return NotificationInboxTile(
            notification: notification,
            localResponse: localResponse,
            isResponding: isResponding,
            accentGreen: _accentGreen,
            primaryTextColor: _primaryTextColor,
            secondaryTextColor: _secondaryTextColor,
            onTap: () => _handleNotificationTap(notification),
            onAccept: notification.canRespondInline
                ? () => _respondInline(notification, accept: true)
                : null,
            onReject: notification.canRespondInline
                ? () => _respondInline(notification, accept: false)
                : null,
          );
        },
      ),
    );
  }
}
