import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../data/mock_client_data.dart';
import '../../../models/interested_agent_model.dart';
import '../widgets/match_created_dialog.dart';
import '../widgets/swipe_action_buttons.dart';
import '../widgets/swipe_deck.dart';
import '../widgets/interested_agent_swipe_card.dart';

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
  List<InterestedAgentModel> get _sourceAgents {
    if (widget.offerId == null) {
      return MockClientData.interestedAgents;
    }

    return MockClientData.interestedAgents
        .where((agent) => agent.offerId == widget.offerId)
        .toList();
  }

  List<InterestedAgentModel> get _agents {
    return _sourceAgents
        .where((agent) => !widget.hiddenAgentIds.contains(agent.id))
        .toList();
  }

  String get _subtitle {
    if (widget.offerId == null) {
      return 'Interested agents';
    }

    try {
      return MockClientData.offers
          .firstWhere((offer) => offer.id == widget.offerId)
          .title;
    } catch (_) {
      return 'Interested agents';
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
            widget.onStartChatting?.call(agent);
          },
        );
      },
    );
  }

  void _handleSwipe(InterestedAgentModel agent, bool liked) {
    widget.onProcessed?.call(agent);

    if (liked) {
      widget.onMatched?.call(agent);
      _showMatchDialog(agent);
    }
  }

  void _showAgentBottomSheet(
    InterestedAgentModel agent,
    bool isDarkMode,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AgentInfoBottomSheet(
          agent: agent,
          isDarkMode: isDarkMode,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);

    final agents = _agents;
    final currentAgent = agents.isNotEmpty ? agents.first : null;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.showBackButton)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Row(
                  children: [
                    _ScreenCircleIconButton(
                      onTap: widget.onBack ?? () => Navigator.pop(context),
                      isDarkMode: isDarkMode,
                      size: 50,
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
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  widget.showBackButton ? 8 : 14,
                  20,
                  0,
                ),
                child: SwipeDeck<InterestedAgentModel>(
                  items: agents,
                  isDarkMode: isDarkMode,
                  dismissKeyBuilder: (agent, remainingCount) =>
                      '${agent.id}_$remainingCount',
                  onSwiped: _handleSwipe,
                  topCardBuilder: (context, agent) {
                    return InterestedAgentSwipeCard(
                      agent: agent,
                      isDarkMode: isDarkMode,
                      onInfoTap: () => _showAgentBottomSheet(
                        agent,
                        isDarkMode,
                      ),
                    );
                  },
                  previewCardBuilder: (context, agent, scale, opacity) {
                    return InterestedAgentPreviewCard(
                      agent: agent,
                      scale: scale,
                      opacity: opacity,
                      isDarkMode: isDarkMode,
                    );
                  },
                  emptyState: _NoMoreAgentsState(
                    isDarkMode: isDarkMode,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    onRestart: null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (currentAgent != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: SwipeActionButtons(
                  isDarkMode: isDarkMode,
                  onDislike: () => _handleSwipe(currentAgent, false),
                  onLike: () => _handleSwipe(currentAgent, true),
                ),
              )
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ScreenCircleIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDarkMode;
  final bool compact;
  final Widget child;
  final double? size;

  const _ScreenCircleIconButton({
    required this.onTap,
    required this.isDarkMode,
    required this.child,
    this.compact = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? (compact ? 52.0 : 64.0);
    final buttonColor =
        isDarkMode ? const Color(0xFF161616) : Colors.white;

    return Material(
      color: buttonColor,
      shape: const CircleBorder(),
      elevation: compact ? 0 : 8,
      shadowColor: Colors.black.withOpacity(0.14),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: dimension,
          height: dimension,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _NoMoreAgentsState extends StatelessWidget {
  final bool isDarkMode;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback? onRestart;

  const _NoMoreAgentsState({
    required this.isDarkMode,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF141414) : const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ScreenCircleIconButton(
                onTap: () {},
                isDarkMode: isDarkMode,
                compact: true,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedUserSearch01,
                  color: isDarkMode ? Colors.white : Colors.black,
                  size: 20,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No more agents to review',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You reached the end of the current interested agents deck.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              if (onRestart != null) ...[
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onRestart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDarkMode ? Colors.white : Colors.black,
                      foregroundColor:
                          isDarkMode ? Colors.black : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Review Again',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
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

class _AgentInfoBottomSheet extends StatelessWidget {
  final InterestedAgentModel agent;
  final bool isDarkMode;

  const _AgentInfoBottomSheet({
    required this.agent,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
    final cardColor =
        isDarkMode ? const Color(0xFF1B1B1B) : const Color(0xFFF4F4F4);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);

    return FractionallySizedBox(
      heightFactor: 0.72,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.14)
                    : Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundImage: AssetImage(agent.imageUrl),
                        backgroundColor: cardColor,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agent.name,
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              agent.jobTitle,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _InfoRow(
                    icon: HugeIcons.strokeRoundedLocation01,
                    label: 'City',
                    value: agent.city,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: HugeIcons.strokeRoundedStar,
                    label: 'Rating',
                    value: agent.rating.toStringAsFixed(1),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: HugeIcons.strokeRoundedUserMultiple02,
                    label: 'Completed Jobs',
                    value: '${agent.completedJobs}',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: HugeIcons.strokeRoundedBriefcase01,
                    label: 'Interested Offer',
                    value: agent.offerTitle,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  final String value;
  final bool isDarkMode;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDarkMode ? const Color(0xFF1B1B1B) : const Color(0xFFF4F4F4);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: icon,
            color: primaryTextColor.withOpacity(0.72),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}