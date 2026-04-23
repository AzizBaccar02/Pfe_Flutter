import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../models/interested_agent_model.dart';

class InterestedAgentSwipeCard extends StatelessWidget {
  final InterestedAgentModel agent;
  final bool isDarkMode;
  final VoidCallback onInfoTap;

  const InterestedAgentSwipeCard({
    super.key,
    required this.agent,
    required this.isDarkMode,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF141414) : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.34 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            agent.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
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
}

class InterestedAgentPreviewCard extends StatelessWidget {
  final InterestedAgentModel agent;
  final double scale;
  final double opacity;
  final bool isDarkMode;

  const InterestedAgentPreviewCard({
    super.key,
    required this.agent,
    required this.scale,
    required this.opacity,
    required this.isDarkMode,
  });

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
              errorBuilder: (_, __, ___) {
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agent.jobTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardCircleIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDarkMode;
  final bool compact;
  final Widget child;

  const _CardCircleIconButton({
    required this.onTap,
    required this.isDarkMode,
    required this.child,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final dimension = compact ? 52.0 : 64.0 ;
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