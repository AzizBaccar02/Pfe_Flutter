import 'package:flutter/material.dart';

class HomeEmptyCard extends StatelessWidget {
  final String text;
  final bool isDarkMode;

  const HomeEmptyCard({
    super.key,
    required this.text,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF161616) : const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDarkMode
              ? Colors.white.withOpacity(0.68)
              : Colors.black.withOpacity(0.68),
          fontSize: 14,
        ),
      ),
    );
  }
}