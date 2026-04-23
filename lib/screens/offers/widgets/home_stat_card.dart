import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class HomeStatCard extends StatelessWidget {
  final bool isDarkMode;
  final String title;
  final String value;
  final dynamic icon;

  const HomeStatCard({
    super.key,
    required this.isDarkMode,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const accentYellow = Color(0xFFFFC107);

    final backgroundColor =
        isDarkMode ? const Color(0xFF141414) : const Color(0xFFF8F8F8);

    final borderColor = isDarkMode
        ? accentYellow.withOpacity(0.10)
        : accentYellow.withOpacity(0.16);

    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.58)
        : Colors.black.withOpacity(0.56);

    final neutralIconColor = isDarkMode
        ? Colors.white.withOpacity(0.78)
        : Colors.black.withOpacity(0.78);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.16 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentYellow.withOpacity(isDarkMode ? 0.10 : 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: HugeIcon(
                icon: icon,
                color: neutralIconColor,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}