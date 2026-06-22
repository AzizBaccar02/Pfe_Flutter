import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/app_notification_model.dart';
import '../../../models/interested_agent_model.dart';
import '../../../services/agent_profile_resolver.dart';
import '../../../services/client_interaction_realtime.dart';
import '../../../services/tab_auto_refresh.dart';
import '../../../services/client_interaction_state_service.dart';
import '../../../services/client_match_persistence.dart';
import '../../../services/interaction_service.dart';
import '../../../services/notification_realtime_hub.dart';
import '../../../services/offer_service.dart';
import '../../../services/profile_service.dart';
import '../../../utils/agent_identity_privacy.dart';
import '../../../widgets/agent_profile_avatar.dart';
import '../widgets/match_created_dialog.dart';
import '../widgets/interested_agent_swipe_card.dart';

class InterestedAgentsScreen extends StatefulWidget {
  final int? offerId;
  final bool showBackButton;
  final bool isTabActive;
  final VoidCallback? onBack;
  final Set<int> hiddenReactionIds;
  final ValueChanged<InterestedAgentModel>? onProcessed;
  final ValueChanged<InterestedAgentModel>? onMatched;
  final ValueChanged<InterestedAgentModel>? onStartChatting;
  final ValueChanged<int>? onPendingCountChanged;

  const InterestedAgentsScreen({
    super.key,
    this.offerId,
    this.showBackButton = false,
    this.isTabActive = true,
    this.onBack,
    this.hiddenReactionIds = const <int>{},
    this.onProcessed,
    this.onMatched,
    this.onStartChatting,
    this.onPendingCountChanged,
  });

  @override
  State<InterestedAgentsScreen> createState() => _InterestedAgentsScreenState();
}

class _InterestedAgentsScreenState extends State<InterestedAgentsScreen>
    with WidgetsBindingObserver {
  Offset _dragOffset = Offset.zero;

  bool _isLoading = true;
  bool _isMutating = false;
  String? _errorMessage;

  List<InterestedAgentModel> _agents = [];
  final Set<int> _locallyProcessedReactionIds = {};

  late final TabAutoRefresh _autoRefresh;
  StreamSubscription<AppNotificationModel>? _agentInterestSubscription;

  List<InterestedAgentModel> get _visibleAgents {
    return _agents.where((agent) {
      if (!agent.isActionable) return false;
      if (!agent.isPendingForDeck) return false;
      if (agent.reactionId > 0 &&
          widget.hiddenReactionIds.contains(agent.reactionId)) {
        return false;
      }
      if (_locallyProcessedReactionIds.contains(agent.reactionId)) return false;
      if (widget.offerId != null &&
          widget.offerId! > 0 &&
          agent.offerId != widget.offerId) {
        return false;
      }
      return true;
    }).toList();
  }

  void _notifyPendingCount() {
    widget.onPendingCountChanged?.call(_visibleAgents.length);
  }

  bool get _isEmpty => _visibleAgents.isEmpty;

  String get _subtitle {
    if (widget.offerId == null) {
      return 'Interested agents';
    }

    final firstMatchingOffer = _agents.where(
      (agent) => agent.offerId == widget.offerId,
    );

    if (firstMatchingOffer.isNotEmpty) {
      return firstMatchingOffer.first.offerTitle;
    }

    return 'Interested agents';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bindAgentInterestPush();
    _autoRefresh = TabAutoRefresh(
      onRefresh: ({showLoader = true}) =>
          _loadInterestedAgents(showLoader: showLoader),
      isTabActive: () => widget.isTabActive,
      pollInterval: const Duration(seconds: 10),
    );
    _autoRefresh.attach();
    _loadInterestedAgents();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefresh.dispose();
    _agentInterestSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadInterestedAgents(showLoader: false);
    }
  }

  void _bindAgentInterestPush() {
    final hub = ClientInteractionRealtime.instance;
    hub.ensureStarted();
    _agentInterestSubscription = hub.onAgentInterest.listen((notification) {
      if (!mounted) return;
      unawaited(_handleAgentInterestNotification(notification));
    });
  }

  Future<void> _handleAgentInterestNotification(
    AppNotificationModel notification,
  ) async {
    await _prependFromNotification(notification);
    unawaited(ClientInteractionStateService.invalidate());
    await _loadInterestedAgents(showLoader: false);
  }

  Future<void> _prependFromNotification(
    AppNotificationModel notification,
  ) async {
    var incoming = InterestedAgentModel.fromNotification(notification);

    if (widget.offerId != null &&
        widget.offerId! > 0 &&
        incoming.offerId > 0 &&
        incoming.offerId != widget.offerId) {
      return;
    }

    if (!incoming.isActionable && notification.interactionId != null) {
      final hydrated = await InteractionService.fetchInterestedAgentByReaction(
        reactionId: notification.interactionId!,
        offerId: notification.offerId,
        agentId: notification.agentId,
      );
      if (hydrated != null) {
        incoming = incoming.mergeWith(hydrated);
      }
    }

    incoming = await _ensureOfferContext(incoming);

    if (!incoming.isActionable) return;

    final alreadyVisible = _agents.any(
      (agent) =>
          (incoming.reactionId > 0 && agent.reactionId == incoming.reactionId) ||
          (incoming.id > 0 &&
              agent.id == incoming.id &&
              agent.offerId == incoming.offerId),
    );
    if (alreadyVisible) return;

    if (!mounted) return;

    setState(() {
      _agents.insert(0, incoming);
      _isLoading = false;
      _errorMessage = null;
    });
    _notifyPendingCount();

    unawaited(_hydrateAgentCard(incoming));
  }

  Future<void> _hydrateAgentCard(InterestedAgentModel stub) async {
    if (stub.reactionId <= 0 && stub.id <= 0) return;

    InterestedAgentModel merged = stub;

    if (stub.reactionId > 0) {
      final fromReaction = await InteractionService.fetchInterestedAgentByReaction(
        reactionId: stub.reactionId,
        offerId: stub.offerId > 0 ? stub.offerId : null,
        agentId: stub.id > 0 ? stub.id : null,
      );
      if (fromReaction != null) {
        merged = _mergeAgentLists([fromReaction], [merged]).first;
      }
    }

    try {
      final profile = await AgentProfileResolver.resolve(
        agentProfileId: merged.id,
        agentUserId: merged.id,
        interactionId: merged.reactionId > 0 ? merged.reactionId : null,
        fallbackName: merged.name,
        fallbackPhotoUrl: merged.isPendingInterest ? null : merged.imageUrl,
      );
      merged = merged.enrichedWithProfile(profile);
    } catch (_) {
      // Keep reaction-level data if public profile is unavailable.
    }

    merged = await _ensureOfferContext(merged);

    if (!mounted) return;

    setState(() {
      final index = _agents.indexWhere(
        (agent) =>
            (merged.reactionId > 0 && agent.reactionId == merged.reactionId) ||
            (merged.id > 0 &&
                agent.id == merged.id &&
                agent.offerId == merged.offerId),
      );
      if (index >= 0) {
        _agents[index] = merged;
      } else {
        _agents.insert(0, merged);
      }
    });
    _notifyPendingCount();
  }

  Future<List<InterestedAgentModel>> _resolveOfferTitles(
    List<InterestedAgentModel> agents,
  ) async {
    final resolved = <InterestedAgentModel>[];
    for (final agent in agents) {
      resolved.add(await _ensureOfferContext(agent));
    }
    return resolved;
  }

  Future<InterestedAgentModel> _ensureOfferContext(
    InterestedAgentModel agent,
  ) async {
    if (agent.offerId <= 0) return agent;

    final needsTitle = agent.offerTitle.trim().isEmpty;
    final needsImage = agent.offerImageUrl.trim().isEmpty;
    if (!needsTitle && !needsImage) return agent;

    final media = await OfferService.resolveOfferMedia(agent.offerId);
    if (media == null) return agent;

    return agent.copyWith(
      offerTitle: needsTitle ? media.title : agent.offerTitle,
      offerImageUrl: needsImage ? media.imageUrl : agent.offerImageUrl,
    );
  }

  Future<void> _enrichVisibleAgents() async {
    final targets = _visibleAgents.where((a) => a.needsProfileEnrichment).toList();
    for (final agent in targets) {
      if (!mounted) break;
      await _hydrateAgentCard(agent);
    }
  }

  @override
  void didUpdateWidget(covariant InterestedAgentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.offerId != widget.offerId) {
      _loadInterestedAgents();
    }

    if (widget.isTabActive && !oldWidget.isTabActive) {
      _autoRefresh.onTabBecameActive();
    }
  }

  List<InterestedAgentModel> _mergeAgentLists(
    List<InterestedAgentModel> primary,
    List<InterestedAgentModel> secondary,
  ) {
    final merged = <String, InterestedAgentModel>{};

    for (final agent in [...primary, ...secondary]) {
      final key = agent.reactionId > 0
          ? 'reaction:${agent.reactionId}'
          : 'agent:${agent.id}:offer:${agent.offerId}';
      final existing = merged[key];
      merged[key] =
          existing == null ? agent : existing.mergeWith(agent);
    }

    return merged.values.toList()
      ..sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;
        if (ad != null && bd != null) return bd.compareTo(ad);
        if (ad != null) return -1;
        if (bd != null) return 1;
        return b.reactionId.compareTo(a.reactionId);
      });
  }

  Future<List<InterestedAgentModel>> _agentsFromInterestNotifications() async {
    try {
      final items = await NotificationRealtimeHub.instance.fetchNotifications();
      final agents = <InterestedAgentModel>[];

      for (final notification in items) {
        if (!notification.isAgentInterestNotification) continue;

        final stub = InterestedAgentModel.fromNotification(notification);
        if (stub.offerId <= 0) continue;
        if (stub.id <= 0 && stub.reactionId <= 0) continue;

        agents.add(stub);
      }

      return agents;
    } catch (e) {
      debugPrint('[INTERESTED] notification seed failed: $e');
      return const [];
    }
  }

  Future<List<InterestedAgentModel>> _hydrateMissingReactionIds(
    List<InterestedAgentModel> agents,
  ) async {
    final updated = <InterestedAgentModel>[];

    for (final agent in agents) {
      if (agent.reactionId > 0 || agent.id <= 0 || agent.offerId <= 0) {
        updated.add(agent);
        continue;
      }

      final lookup = await InteractionService.lookupClientReaction(
        offerId: agent.offerId,
        agentId: agent.id,
      );

      if (lookup != null && lookup.id > 0) {
        updated.add(InterestedAgentModel.fromInteraction(lookup));
      } else {
        updated.add(agent);
      }
    }

    return updated;
  }

  Future<void> _loadInterestedAgents({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final previousVisibleCount = _visibleAgents.length;
      final locallyKnown = List<InterestedAgentModel>.from(_agents);

      if (showLoader) {
        await ClientInteractionStateService.invalidate();
      }

      final agents = await InteractionService.fetchInterestedAgents(
        offerId: widget.offerId,
      );
      final fromNotifications = await _agentsFromInterestNotifications();

      if (!mounted) return;

      var merged = _mergeAgentLists(
        agents,
        _mergeAgentLists(fromNotifications, locallyKnown),
      );
      merged = await _hydrateMissingReactionIds(merged);
      merged = await _resolveOfferTitles(merged);

      final trustedReactionIds = agents
          .map((agent) => agent.reactionId)
          .where((id) => id > 0)
          .toSet();
      merged = await InteractionService.filterUnresolvedInterestedAgents(
        merged,
        trustedReactionIds: trustedReactionIds,
      );

      if (!mounted) return;

      setState(() {
        _agents = merged;
        _errorMessage = null;
      });
      _notifyPendingCount();
      unawaited(_enrichVisibleAgents());

      if (!showLoader && mounted) {
        final newVisibleCount = _visibleAgents.length;
        if (newVisibleCount > previousVisibleCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newVisibleCount - previousVisibleCount == 1
                    ? 'A new agent is interested in your offer'
                    : '${newVisibleCount - previousVisibleCount} new agents are interested',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF151515),
            ),
          );
        }
      }
    } on InteractionServiceException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load interested agents. Please try again.';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        if (showLoader) {
          _isLoading = false;
        }
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isMutating) return;

    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isMutating) return;

    const threshold = 120.0;

    if (_dragOffset.dx > threshold) {
      _commitSwipe(isLike: true);
      return;
    }

    if (_dragOffset.dx < -threshold) {
      _commitSwipe(isLike: false);
      return;
    }

    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  Future<void> _commitSwipe({required bool isLike}) async {
    final agents = _visibleAgents;
    if (agents.isEmpty || _isMutating) return;

    final agent = agents.first;

    if (agent.reactionId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This profile is still syncing. Pull down to refresh, then try again.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      unawaited(_loadInterestedAgents(showLoader: false));
      return;
    }

    setState(() {
      _isMutating = true;
      _dragOffset = Offset.zero;
    });

    try {
      await InteractionService.respondToReaction(
        reactionId: agent.reactionId,
        accept: isLike,
        offerId: agent.offerId,
      );

      if (isLike) {
        await ClientInteractionStateService.recordAccepted(
          offerId: agent.offerId,
          agentId: agent.id,
          reactionId: agent.reactionId,
        );
      } else {
        await ClientMatchPersistence.markRejected(
          offerId: agent.offerId,
          agentId: agent.id,
        );
      }
      ClientInteractionRealtime.instance.notifyRefresh();

      if (!mounted) return;

      setState(() {
        _locallyProcessedReactionIds.add(agent.reactionId);
      });
      _notifyPendingCount();

      widget.onProcessed?.call(agent);

      if (isLike) {
        await _showMatchDialog(agent);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${agent.name} was declined — the agent has been notified.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF151515),
          ),
        );
      }
    } on InteractionServiceException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to respond to this agent. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _showMatchDialog(InterestedAgentModel agent) async {
    var agentPhoto = '';
    var agentName = agent.name.trim();

    try {
      final profile = await AgentProfileResolver.resolve(
        agentProfileId: agent.id,
        agentUserId: agent.id,
        interactionId: agent.reactionId > 0 ? agent.reactionId : null,
        fallbackName: agent.name,
      );
      agentPhoto =
          ProfileService.resolveMediaUrl(profile.photoUrl)?.trim() ?? '';
      if (profile.displayName.trim().isNotEmpty) {
        agentName = profile.displayName.trim();
      }
    } catch (_) {
      // Dialog falls back to initials if photo unavailable.
    }

    if (!mounted) return;

    final matchedAgent = agent.copyWith(
      name: agentName,
      imageUrl: agentPhoto,
      status: 'ACCEPTED',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return MatchCreatedDialog(
          agentImagePath: agentPhoto,
          backgroundImagePath: 'assets/images/match_bg.gif',
          agentName: agentName,
          agentId: agent.id,
          reactionId: agent.reactionId,
          onContinue: () {
            Navigator.of(dialogContext).pop();
          },
          onStartChat: () {
            Navigator.of(dialogContext).pop();
            widget.onMatched?.call(matchedAgent);
            widget.onStartChatting?.call(matchedAgent);
          },
        );
      },
    );
  }

  void _showAgentBottomSheet(
    InterestedAgentModel agent,
    bool isDarkMode,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (_) {
        return _AgentInfoBottomSheet(
          agent: agent,
          isDarkMode: isDarkMode,
        );
      },
    );
  }

  Widget _buildHeader(
    bool isDarkMode,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    if (!widget.showBackButton) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        children: [
          _ScreenCircleIconButton(
            onTap: widget.onBack ?? () => Navigator.pop(context),
            isDarkMode: isDarkMode,
            child: AppBackButton.icon(context, isDarkMode: isDarkMode),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interested Agents',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Center(
      child: CircularProgressIndicator(
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildErrorState(bool isDarkMode) {
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.68)
        : Colors.black.withValues(alpha: 0.62);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load agents',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _loadInterestedAgents,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: isDarkMode ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.68)
        : Colors.black.withValues(alpha: 0.62);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => _loadInterestedAgents(showLoader: false),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No pending interests',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'When an agent likes your offer, they appear here so you can accept or decline. New likes also show up automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeck(bool isDarkMode) {
    final agents = _visibleAgents;
    final topAgent = agents.first;

    final rotation = _dragOffset.dx / 420;
    final overlayColor = _dragOffset.dx > 0
        ? AppColors.accent
        : const Color(0xFFDC2626);

    return SizedBox.expand(
      child: Stack(
        // Keep the deck clean: do not show the next card peeking underneath.
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: _dragOffset.dx.abs() > 18 ? 0.10 : 0,
              child: Container(color: overlayColor),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _isMutating,
              child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Transform.translate(
                  offset: _dragOffset,
                  child: Transform.rotate(
                    angle: rotation,
                    child: InterestedAgentSwipeCard(
                      agent: topAgent,
                      isDarkMode: isDarkMode,
                      onLikeTap: () => _commitSwipe(isLike: true),
                      onDislikeTap: () => _commitSwipe(isLike: false),
                      onDetailsTap: () => _showAgentBottomSheet(
                        topAgent,
                        isDarkMode,
                      ),
                      dragDx: _dragOffset.dx,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isMutating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.10),
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.62)
        : Colors.black.withValues(alpha: 0.58);

    Widget body;

    if (_isLoading) {
      body = _buildLoadingState(isDarkMode);
    } else if (_errorMessage != null && _agents.isEmpty) {
      body = _buildErrorState(isDarkMode);
    } else if (_isEmpty) {
      body = _buildEmptyState(isDarkMode);
    } else {
      body = _buildDeck(isDarkMode);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        top: widget.showBackButton,
        bottom: false,
        child: Column(
          children: [
            _buildHeader(
              isDarkMode,
              primaryTextColor,
              secondaryTextColor,
            ),
            Expanded(
              child: body,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenCircleIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDarkMode;
  final Widget child;

  const _ScreenCircleIconButton({
    required this.onTap,
    required this.isDarkMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = isDarkMode ? const Color(0xFF161616) : Colors.white;

    return Material(
      color: buttonColor,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _AgentInfoBottomSheet extends StatelessWidget {
  final InterestedAgentModel agent;
  final bool isDarkMode;

  const _AgentInfoBottomSheet({
    required this.agent,
    required this.isDarkMode,
  });

  Widget _buildAvatar(Color cardColor) {
    return AgentProfileAvatar(
      photoUrl: agent.imageUrl,
      displayName: agent.name,
      radius: 34,
      backgroundColor: cardColor,
      hidePhoto: agent.isPendingInterest,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.68)
        : Colors.black.withValues(alpha: 0.62);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _buildAvatar(cardColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AgentIdentityPrivacy.publicLabel(agent.name),
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          agent.jobTitle,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (agent.completedJobs > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${agent.completedJobs} completed jobs',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Location: ${agent.city.isEmpty ? 'Not specified' : agent.city}',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Interested in: ${agent.offerTitle}',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (agent.proposedPrice.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Proposed price',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    '${agent.proposedPrice} DT',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (agent.message.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Agent message',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    agent.message,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}