import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../models/interested_agent_model.dart';

class InterestedAgentSwipeCard extends StatelessWidget {
  final InterestedAgentModel agent;
  final bool isDarkMode;
  final VoidCallback onLikeTap;
  final VoidCallback onDislikeTap;
  final VoidCallback onDetailsTap;
  final double dragDx;

  /// Use false for the card behind the main card.
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
    if (dragDx > 0) return const Color(0xFF16A34A);
    if (dragDx < 0) return const Color(0xFFDC2626);
    return Colors.transparent;
  }

  double _feedbackOpacity() {
    final value = (dragDx.abs() / 120).clamp(0.0, 1.0);
    return value * 0.16;
  }

  String _feedbackText() {
    if (dragDx > 25) return 'LIKE';
    if (dragDx < -25) return 'NOPE';
    return '';
  }

  Widget _buildFallbackImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF111111),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            agent.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return Container(
                color: isDarkMode
                    ? const Color(0xFF1C1C1C)
                    : const Color(0xFFEDEDED),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedUser,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.72)
                        : Colors.black.withOpacity(0.72),
                    size: 42,
                  ),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.04),
                  Colors.black.withOpacity(0.10),
                  Colors.black.withOpacity(0.42),
                  Colors.black.withOpacity(0.88),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 18,
            child: _CardCircleIconButton(
              onTap: onInfoTap,
              isDarkMode: true,
              compact: true,
              child: Transform.rotate(
                angle: math.pi,
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 78,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  agent.jobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  agent.city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
                    fontSize: 14,
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

  Widget _buildImage(String path) {
    if (path.trim().isEmpty) {
      return _buildFallbackImage();
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _buildFallbackImage();
        },
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _buildFallbackImage();
        },
      );
    }

    return Image.file(
      File(path),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return _buildFallbackImage();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF141414) : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(34),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              agent.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                return Container(
                  color: isDarkMode
                      ? const Color(0xFF1C1C1C)
                      : const Color(0xFFEDEDED),
                );
              },
            ),
            Container(
              color: Colors.black.withOpacity(0.42),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Opacity(
                opacity: opacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),

                      /// Swipe feedback color overlay.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: _feedbackColor().withValues(
                              alpha: _feedbackOpacity(),
                            ),
                          ),
                        ),
                      ),

                      /// Light full image overlay.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.06),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.08),
                                ],
                                stops: const [0.0, 0.18, 0.62, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                      /// Bottom shadow, around 30% of the card.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: constraints.maxHeight * 0.30,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.00),
                                  Colors.black.withValues(alpha: 0.25),
                                  Colors.black.withValues(alpha: 0.55),
                                  Colors.black.withValues(alpha: 0.82),
                                ],
                                stops: const [0.0, 0.28, 0.70, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                      /// Swipe label.
                      Positioned(
                        top: 42,
                        left: dragDx >= 0 ? 14 : null,
                        right: dragDx < 0 ? 14 : null,
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 120),
                            opacity: _feedbackText().isEmpty ? 0 : 1,
                            child: Transform.rotate(
                              angle: dragDx >= 0 ? -0.10 : 0.10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: dragDx >= 0
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFFEF4444),
                                    width: 1.8,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.black.withValues(alpha: 0.12),
                                ),
                                child: Text(
                                  _feedbackText(),
                                  style: TextStyle(
                                    color: dragDx >= 0
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFFEF4444),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      /// Bottom text, same structure as agent offer card.
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: IgnorePointer(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      agent.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        height: 1.12,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black87,
                                            blurRadius: 10,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      agent.jobTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.92),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black87,
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        HugeIcon(
                                          icon: HugeIcons
                                              .strokeRoundedLocation01,
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            agent.city,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              shadows: const [
                                                Shadow(
                                                  color: Colors.black87,
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            /// Details button.
                            if (showDetailsButton) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: onDetailsTap,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.16,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      size: 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          /// Buttons below the card, not inside the image.
          /// Solid background hides the preview card behind, same as agent side.
          if (showActions)
            Container(
              width: double.infinity,
              color: actionAreaBackground,
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleActionButton(
                    onTap: onDislikeTap,
                    backgroundColor: actionBackground,
                    iconColor: const Color(0xFFEF4444),
                    icon: HugeIcons.strokeRoundedCancel01,
                    shadowColor: shadowColor,
                  ),
                  const SizedBox(width: 22),
                  _CircleActionButton(
                    onTap: onLikeTap,
                    backgroundColor: actionBackground,
                    iconColor: const Color(0xFF10B981),
                    icon: HugeIcons.strokeRoundedFavourite,
                    shadowColor: shadowColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final Color shadowColor;
  final dynamic icon;

  const _CircleActionButton({
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: HugeIcon(
            icon: icon,
            color: iconColor,
            size: 22,
          ),
        ),
      ),
    );
  }
}