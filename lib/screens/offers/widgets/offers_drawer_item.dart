import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class OffersDrawerItem extends StatelessWidget {
  final dynamic icon;
  final String title;
  final bool isDarkMode;
  final Color? color;
  final VoidCallback onTap;

  const OffersDrawerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isDarkMode,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        isDarkMode ? const Color(0xFF171717) : const Color(0xFFF0F0F0);

    final itemColor = color ??
        (isDarkMode
            ? Colors.white.withOpacity(0.7)
            : Colors.black.withOpacity(0.7));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              color: itemColor,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: itemColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}