import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/interested_agent_model.dart';
import '../../../models/offer_interaction_model.dart';
import '../../../services/interaction_service.dart';
import '../../../services/offer_reaction_service.dart';
import '../widgets/match_created_dialog.dart';
import '../widgets/swipe_action_buttons.dart';
import '../widgets/swipe_deck.dart';
import '../widgets/interested_agent_swipe_card.dart';
import '../widgets/match_created_dialog.dart';

class InterestedAgentsScreen extends StatefulWidget {
  final int? offerId;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Set<int> hiddenAgentIds;
  final ValueChanged<InterestedAgentModel>? onProcessed;
  final ValueChanged<InterestedAgentModel>? onMatched;
  final ValueChanged<InterestedAgentModel>? onStartChatting;

  const InterestedAgentsScreen({
    super.key,
    this.offerId,
    this.showBackButton = false,
    this.onBack,
    this.hiddenAgentIds = const <int>{},
    this.onProcessed,
    this.onMatched,
    this.onStartChatting,
  });

  @override
  State<InterestedAgentsScreen> createState() => _InterestedAgentsScreenState();
}

class _InterestedAgentsScreenState extends State<InterestedAgentsScreen> {
  Offset _dragOffset = Offset.zero;

  bool _isLoading = true;
  bool _isMutating = false;
  String? _errorMessage;

  List<InterestedAgentModel> _agents = [];
  final Set<int> _locallyProcessedReactionIds = {};

  List<InterestedAgentModel> get _visibleAgents {
    return _agents.where((agent) {
      if (widget.hiddenAgentIds.contains(agent.id)) return false;
      if (_locallyProcessedReactionIds.contains(agent.reactionId)) return false;
      return true;
    }).toList();
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
    _loadInterestedAgents();
  }

  @override
  void didUpdateWidget(covariant InterestedAgentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.offerId != widget.offerId) {
      _loadInterestedAgents();
    }
  }

  Future<void> _loadInterestedAgents({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final agents = await InteractionService.fetchInterestedAgents(
        offerId: widget.offerId,
      );

      if (!mounted) return;

      setState(() {
        _agents = agents;
        _errorMessage = null;
      });
    } on InteractionException catch (e) {
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
      if (mounted && showLoader) {
        setState(() {
          _isLoading = false;
        });
      }
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

    setState(() {
      _isMutating = true;
      _dragOffset = Offset.zero;
    });

    try {
      await InteractionService.respondToReaction(
        reactionId: agent.reactionId,
        accept: isLike,
      );

      if (!mounted) return;

      setState(() {
        _locallyProcessedReactionIds.add(agent.reactionId);
      });

      widget.onProcessed?.call(agent);

      if (isLike) {
        _showMatchDialog(agent);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You skipped ${agent.name}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF151515),
          ),
        );
      }
    } on InteractionException catch (e) {
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

  void _showMatchDialog(InterestedAgentModel agent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return MatchCreatedDialog(
          clientImagePath: 'assets/images/Profil.jpg',
          agentImagePath: agent.imageUrl,
          backgroundImagePath: 'assets/images/match_bg.gif',
          agentName: agent.name,
          onContinue: () {
            Navigator.of(dialogContext).pop();
          },
          onStartChat: () {
            Navigator.of(dialogContext).pop();
            widget.onMatched?.call(agent);
            widget.onStartChatting?.call(agent);
          },
        );
      },
    );
  }

  Future<void> _handleSwipe(InterestedAgentModel agent, bool liked) async {
    widget.onProcessed?.call(agent);

    try {
      if (liked) {
        final pending = await InteractionService.getPendingForOffer(
          agent.offerId,
        );
        final interaction = pending.firstWhere(
          (item) => item.agentId == agent.id,
          orElse: () => OfferInteractionModel(
            id: 0,
            offerId: agent.offerId,
            offerTitle: agent.offerTitle,
            agentId: agent.id,
            message: '',
            status: 'PENDING',
            react: true,
          ),
        );

        if (interaction.id > 0) {
          await OfferReactionService.clientAcceptAgent(
            interaction: interaction,
          );
        }

        if (!mounted) return;

        widget.onMatched?.call(agent);
        _showMatchDialog(agent);
        return;
      }

      final pendingReject = await InteractionService.getPendingForOffer(
        agent.offerId,
      );
      OfferInteractionModel? rejectInteraction;
      try {
        rejectInteraction = pendingReject.firstWhere(
          (item) => item.agentId == agent.id,
        );
      } catch (_) {
        rejectInteraction = null;
      }

      if (rejectInteraction != null && rejectInteraction.id > 0) {
        await OfferReactionService.clientRejectAgent(
          interaction: rejectInteraction,
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send your response right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: isDarkMode ? Colors.white : Colors.black,
              size: 20,
            ),
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
    final cardColor =
        isDarkMode ? const Color(0xFF151515) : const Color(0xFFF5F5F5);

    return RefreshIndicator(
      onRefresh: () => _loadInterestedAgents(showLoader: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.64,
            child: Center(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.zero,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No interested agents for now',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'When agents react positively to your offers, they will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
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
    final nextAgent = agents.length > 1 ? agents[1] : null;

    final rotation = _dragOffset.dx / 420;
    final overlayColor = _dragOffset.dx > 0
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: _dragOffset.dx.abs() > 18 ? 0.10 : 0,
              child: Container(color: overlayColor),
            ),
          ),
          if (nextAgent != null)
            Positioned.fill(
              child: Transform.scale(
                scale: 1.0,
                child: Opacity(
                  opacity: 0.45,
                  child: InterestedAgentSwipeCard(
                    agent: nextAgent,
                    isDarkMode: isDarkMode,
                    onLikeTap: () {},
                    onDislikeTap: () {},
                    onDetailsTap: () => _showAgentBottomSheet(
                      nextAgent,
                      isDarkMode,
                    ),
                    dragDx: 0,
                    showActions: false,
                    showDetailsButton: false,
                  ),
                ),
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
              child: SizedBox.expand(
                child: body,
              ),
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
    final fallback = CircleAvatar(
      radius: 34,
      backgroundColor: cardColor,
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedUser,
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.72)
            : Colors.black.withValues(alpha: 0.72),
        size: 22,
      ),
    );

    final imagePath = agent.imageUrl;

    if (imagePath.trim().isEmpty) return fallback;

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CircleAvatar(
        radius: 34,
        backgroundColor: cardColor,
        backgroundImage: NetworkImage(imagePath),
      );
    }

    if (imagePath.startsWith('assets/')) {
      return CircleAvatar(
        radius: 34,
        backgroundColor: cardColor,
        backgroundImage: AssetImage(imagePath),
      );
    }

    return CircleAvatar(
      radius: 34,
      backgroundColor: cardColor,
      backgroundImage: FileImage(File(imagePath)),
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
                          agent.name,
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
                  '${agent.rating.toStringAsFixed(1)} rating · ${agent.completedJobs} completed jobs',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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