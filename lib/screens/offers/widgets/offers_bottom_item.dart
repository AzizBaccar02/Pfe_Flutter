import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

import 'package:hugeicons/hugeicons.dart';

class OffersBottomItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;
  final bool showIndicatorDot;

  const OffersBottomItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
    this.showIndicatorDot = false,
  });

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.accent;

    final activeColor = isDarkMode ? Colors.white : Colors.black;
    final inactiveColor =
        isDarkMode ? Colors.white54 : Colors.black54;

    final color = selected ? activeColor : inactiveColor;

    final background = selected
        ? (isDarkMode
            ? accent.withOpacity(0.10)
            : accent.withOpacity(0.14))
        : Colors.transparent;

    final borderColor = selected
        ? accent.withOpacity(isDarkMode ? 0.28 : 0.34)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                HugeIcon(
                  icon: icon,
                  color: color,
                  size: 18,
                ),
                if (showIndicatorDot)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}