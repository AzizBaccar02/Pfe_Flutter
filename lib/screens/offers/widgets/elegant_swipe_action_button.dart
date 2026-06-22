import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Shared accept / decline controls for swipe decks (client Interested + agent Offers).
class ElegantSwipeActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final dynamic icon;
  final Color iconColor;
  final Color borderColor;
  final Color backgroundColor;
  final Color shadowColor;
  final bool filled;

  const ElegantSwipeActionButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    required this.backgroundColor,
    required this.shadowColor,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: filled ? iconColor.withValues(alpha: 0.12) : backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: HugeIcon(
            icon: icon,
            color: iconColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}
