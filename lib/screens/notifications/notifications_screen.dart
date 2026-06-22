// lib/screens/notifications/notifications_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import '../../widgets/app_back_button.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../conf/theme_provider.dart';
import '../../models/app_notification_model.dart';
import '../../models/interested_agent_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_realtime_hub.dart';
import '../../services/tab_auto_refresh.dart';
import '../../services/client_interaction_state_service.dart';
import '../../services/interaction_notification_flow.dart';
import '../../services/notification_router.dart';
import '../../services/notification_service.dart';
import '../../services/notification_enrichment_service.dart';
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
  final Map<int, String> _reactionStatuses = {};
  late final TabAutoRefresh _autoRefresh;

  @override
  void initState() {
    super.initState();
    _hub.setInboxOpen(true);
    _autoRefresh = TabAutoRefresh(
      onRefresh: ({showLoader = true}) =>
          _loadNotifications(showLoader: showLoader),
      isTabActive: () => true,
      pollInterval: const Duration(seconds: 20),
      refreshWhenInactive: true,
    );
    _autoRefresh.attach();
    _bootstrapNotificationsScreen();
  }

  @override
  void dispose() {
    _autoRefresh.dispose();
    _hub.setInboxOpen(false);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _markAllAsRead() async {
    await _hub.markAllAsRead();
    widget.onNotificationsRead?.call();

    if (!mounted) return;

    setState(() {
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  Future<void> _markNotificationRead(AppNotificationModel notification) async {
    if (notification.isRead || notification.id <= 0) return;

    try {
      await NotificationService.markAsRead(notification.id);
    } catch (_) {
      // Still update UI locally if the API call fails.
    }

    if (!mounted) return;

    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index >= 0) {
        _notifications[index] =
            _notifications[index].copyWith(isRead: true);
      }
    });

    await _hub.syncUnreadCount();
    if (_hub.unreadCount == 0) {
      widget.onNotificationsRead?.call();
    }
  }

  Future<void> _bootstrapNotificationsScreen() async {
    await _hub.ensureStarted();

    _notificationSubscription = _hub.onNotification.listen(
      _handleIncomingNotification,
    );

    await _loadNotifications();
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
          _notifications = [enriched, ..._notifications];
        }
      });

      unawaited(_hub.syncUnreadCount());
    });
  }

  Future<void> _loadNotifications({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      var notifications = await _hub.fetchNotifications();
      notifications =
          await NotificationEnrichmentService.enrich(notifications);

      if (!mounted) return;

      setState(() {
        _notifications = notifications;
      });

      await _hub.syncUnreadCount();

      await _hydrateReactionStatuses();
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

  Future<void> _hydrateReactionStatuses() async {
    if (!await AuthService.isClientRole()) return;

    final hasClientInterestRows = _notifications.any(
      (n) => n.isAgentInterestNotification,
    );
    if (!hasClientInterestRows) return;

    await ClientInteractionStateService.ensureLoaded();

    final statuses = <int, String>{};

    for (final notification in _notifications) {
      if (!notification.isAgentInterestNotification) continue;

      final resolution =
          await InteractionNotificationFlow.resolveInterest(notification);
      final status = resolution.reaction?.status;
      if (status != null && status.trim().isNotEmpty) {
        statuses[notification.id] = status;
      } else if (resolution.isAccepted) {
        statuses[notification.id] = 'ACCEPTED';
      }
    }

    if (!mounted) return;

    setState(() {
      _reactionStatuses
        ..clear()
        ..addAll(statuses);
      for (final entry in statuses.entries) {
        if (InteractionNotificationFlow.isAccepted(entry.value)) {
          _localResponses[entry.key] = NotificationInboxResponse.accepted;
        } else if (InteractionNotificationFlow.isRejected(entry.value)) {
          _localResponses[entry.key] = NotificationInboxResponse.rejected;
        }
      }
    });
  }

  String? _statusNoteFor(AppNotificationModel notification) {
    final local =
        _localResponses[notification.id] ?? NotificationInboxResponse.none;

    if (local == NotificationInboxResponse.accepted) {
      return 'Match active · tap to open chat';
    }

    if (local == NotificationInboxResponse.rejected) {
      return 'You declined this agent';
    }

    final status = _reactionStatuses[notification.id];
    if (status == null) return null;

    if (InteractionNotificationFlow.isAccepted(status)) {
      return 'Match active · tap to open chat';
    }

    if (InteractionNotificationFlow.isRejected(status)) {
      return 'You declined this agent';
    }

    return null;
  }

  Future<void> _handleNotificationTap(AppNotificationModel notification) async {
    await _markNotificationRead(notification);

    final resolved =
        await NotificationEnrichmentService.enrichOne(notification);

    if (resolved.isAgentInterestNotification) {
      final handled = await InteractionNotificationFlow.handleClientAgentInterestTap(
        context,
        resolved,
        openReviewScreen: () async {
          if ((_localResponses[notification.id] ??
                  NotificationInboxResponse.none) !=
              NotificationInboxResponse.none) {
            return;
          }

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

          if (!mounted) return;

          final acceptedAgent = await Navigator.push<InterestedAgentModel>(
            context,
            MaterialPageRoute(
              builder: (_) => ClientAgentInterestScreen(
                offerId: offerId,
                agentId: agentId,
                agentName:
                    resolved.resolvedAgentName ?? resolved.agentName,
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
              _reactionStatuses[notification.id] = 'ACCEPTED';
            });
            widget.onAgentAccepted?.call(acceptedAgent);
          }
        },
      );

      if (handled && mounted) {
        final resolution =
            await InteractionNotificationFlow.resolveInterest(resolved);
        if (resolution.isAccepted) {
          setState(() {
            _reactionStatuses[notification.id] = 'ACCEPTED';
            _localResponses[notification.id] =
                NotificationInboxResponse.accepted;
          });
        } else if (resolution.isRejected) {
          setState(() {
            _reactionStatuses[notification.id] = 'REJECTED';
            _localResponses[notification.id] =
                NotificationInboxResponse.rejected;
          });
        }
      }

      return;
    }

    if (resolved.tapAction == NotificationTapAction.agentMatchAccepted ||
        resolved.tapAction == NotificationTapAction.openChat) {
      await InteractionNotificationFlow.openChatForNotification(
        context,
        resolved,
      );
      return;
    }

    if (resolved.tapAction == NotificationTapAction.agentMatchRejected) {
      await NotificationRouter.handle(context, resolved);
      return;
    }

    if (!notification.isActionable) return;

    if (!mounted) return;

    final acceptedAgent =
        await NotificationRouter.handle(context, resolved);

    if (acceptedAgent != null && mounted) {
      widget.onAgentAccepted?.call(acceptedAgent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor =
        isDarkMode ? const Color(0xFF000000) : const Color(0xFFF3F4F6);
    final primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDarkMode
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final dividerColor =
        isDarkMode ? const Color(0xFF1F1F1F) : const Color(0xFFE5E7EB);
    final avatarBackgroundColor =
        isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final accentGreen = isDarkMode
        ? AppColors.accentReadableOnDark
        : AppColors.accentReadable;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(isDarkMode: isDarkMode),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: accentGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(
        isDarkMode: isDarkMode,
        backgroundColor: backgroundColor,
        primaryTextColor: primaryTextColor,
        secondaryTextColor: secondaryTextColor,
        dividerColor: dividerColor,
        avatarBackgroundColor: avatarBackgroundColor,
        accentGreen: accentGreen,
      ),
    );
  }

  Widget _buildBody({
    required bool isDarkMode,
    required Color backgroundColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color dividerColor,
    required Color avatarBackgroundColor,
    required Color accentGreen,
  }) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: accentGreen,
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
            style: TextStyle(
              color: secondaryTextColor,
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
        color: accentGreen,
        onRefresh: _loadNotifications,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
            Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01,
                color: accentGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No notifications yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'When an agent likes your offer or responds to your request, updates will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
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
      color: accentGreen,
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 120),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 1,
          color: dividerColor,
        ),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          final localResponse =
              _localResponses[notification.id] ?? NotificationInboxResponse.none;

          final reactionStatus = _reactionStatuses[notification.id];

          return NotificationInboxTile(
            notification: notification,
            localResponse: localResponse,
            reactionStatus: reactionStatus,
            statusNote: _statusNoteFor(notification),
            accentGreen: accentGreen,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            avatarBackgroundColor: avatarBackgroundColor,
            isDarkMode: isDarkMode,
            onTap: () => _handleNotificationTap(notification),
          );
        },
      ),
    );
  }
}
