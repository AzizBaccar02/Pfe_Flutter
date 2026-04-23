import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class ProfileHeaderCard extends StatelessWidget {
  final bool isDarkMode;
  final String title;
  final String subtitle;
  final dynamic icon;

  const ProfileHeaderCard({
    super.key,
    required this.isDarkMode,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const accentYellow = Color(0xFFFFC107);
    const accentYellowDeep = Color(0xFF5D4200);

    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.68)
        : Colors.black.withOpacity(0.68);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isDarkMode
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A1A),
                  Color(0xFF111111),
                  Color(0xFF1E1E1E),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8F8F8),
                  Color(0xFFEFEFEF),
                  Color(0xFFF6F6F6),
                ],
              ),
        border: Border.all(
          color: accentYellow.withOpacity(isDarkMode ? 0.14 : 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? accentYellow.withOpacity(0.14)
                  : accentYellow.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accentYellow.withOpacity(0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: HugeIcon(
                icon: icon,
                color: accentYellowDeep,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                    height: 1.5,
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