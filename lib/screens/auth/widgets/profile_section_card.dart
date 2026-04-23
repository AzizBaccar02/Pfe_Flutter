import 'package:flutter/material.dart';

class ProfileSectionCard extends StatelessWidget {
  final bool isDarkMode;
  final String title;
  final Widget child;

  const ProfileSectionCard({
    super.key,
    required this.isDarkMode,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFF3F3F3);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}