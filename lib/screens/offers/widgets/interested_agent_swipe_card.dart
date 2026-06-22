import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../models/interested_agent_model.dart';
import '../../../widgets/agent_profile_avatar.dart';
import '../../../widgets/offer_cover_image.dart';
import 'elegant_swipe_action_button.dart';

class InterestedAgentSwipeCard extends StatelessWidget {
  final InterestedAgentModel agent;
  final bool isDarkMode;
  final VoidCallback onLikeTap;
  final VoidCallback onDislikeTap;
  final VoidCallback onDetailsTap;
  final double dragDx;

  final bool showActions;
  final bool showDetailsButton;

  const InterestedAgentSwipeCard({
    super.key,
    required this.agent,
    required this.isDarkMode,
    required this.onLikeTap,
    required this.onDislikeTap,
    required this.onDetailsTap,
    required this.dragDx,
    this.showActions = true,
    this.showDetailsButton = true,
  });

  Color _feedbackColor() {
    if (dragDx > 0) return AppColors.accent;
    if (dragDx < 0) return const Color(0xFFDC2626);
    return Colors.transparent;
  }

  double _feedbackOpacity() {
    return (dragDx.abs() / 120).clamp(0.0, 1.0) * 0.14;
  }

  String _feedbackText() {
    if (dragDx > 25) return 'ACCEPT';
    if (dragDx < -25) return 'DECLINE';
    return '';
  }

  Widget _buildOfferCover() {
    final cover = agent.coverImageUrl;

    if (cover.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1C1E), Color(0xFF0D0D0F)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedBriefcase01,
                color: Colors.white.withValues(alpha: 0.35),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Offer image',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return OfferCoverImage(
      imageUrl: cover,
      fit: BoxFit.cover,
      isDarkMode: isDarkMode,
    );
  }

  Widget _glassPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _agentChip() {
    final name = agent.displayAgentLabel;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AgentProfileAvatar(
                photoUrl: agent.imageUrl,
                displayName: agent.name,
                radius: 18,
                backgroundColor: const Color(0xFF2A2A2E),
                hidePhoto: agent.isPendingInterest,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Interested agent',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.12);

    return SizedBox.expand(
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(child: _buildOfferCover()),

                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.55),
                              ],
                              stops: const [0.0, 0.22, 0.55, 1.0],
                            ),
                          ),
                        ),
                      ),

                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: _feedbackColor().withValues(
                              alpha: _feedbackOpacity(),
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 14,
                        left: 14,
                        right: 14,
                        child: _agentChip(),
                      ),

                      if (_feedbackText().isNotEmpty)
                        Positioned(
                          top: 72,
                          left: dragDx >= 0 ? 18 : null,
                          right: dragDx < 0 ? 18 : null,
                          child: IgnorePointer(
                            child: Transform.rotate(
                              angle: dragDx >= 0 ? -0.08 : 0.08,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: dragDx >= 0
                                        ? AppColors.accent
                                        : const Color(0xFFEF4444),
                                    width: 2,
                                  ),
                                  color: Colors.black.withValues(alpha: 0.2),
                                ),
                                child: Text(
                                  _feedbackText(),
                                  style: TextStyle(
                                    color: dragDx >= 0
                                        ? AppColors.accent
                                        : const Color(0xFFEF4444),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: _glassPanel(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.18),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: const Text(
                                        'Liked your offer',
                                        style: TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      agent.displaySubtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    if (agent.displaySkillsLine != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        agent.displaySkillsLine!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.78,
                                          ),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        HugeIcon(
                                          icon: HugeIcons
                                              .strokeRoundedLocation01,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          size: 13,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            agent.displayCity,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.75,
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (showDetailsButton) ...[
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: onDetailsTap,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.22,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 19,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (showActions) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElegantSwipeActionButton(
                  onTap: onDislikeTap,
                  icon: HugeIcons.strokeRoundedCancel01,
                  iconColor: const Color(0xFFEF4444),
                  borderColor: const Color(0xFFEF4444).withValues(alpha: 0.35),
                  backgroundColor: isDarkMode
                      ? const Color(0xFF1A1A1A)
                      : Colors.white,
                  shadowColor: shadowColor,
                ),
                const SizedBox(width: 28),
                ElegantSwipeActionButton(
                  onTap: onLikeTap,
                  icon: HugeIcons.strokeRoundedFavourite,
                  iconColor: AppColors.accent,
                  borderColor: AppColors.accent.withValues(alpha: 0.45),
                  backgroundColor: isDarkMode
                      ? const Color(0xFF1A1A1A)
                      : Colors.white,
                  shadowColor: shadowColor,
                  filled: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
