import 'package:flutter/material.dart';

import '../../../conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';

class SettingsSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDarkMode;
  final ValueChanged<String>? onChanged;

  const SettingsSearchBar({
    super.key,
    required this.controller,
    required this.isDarkMode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.accent;

    final backgroundColor =
        isDarkMode ? const Color(0xFF151515) : const Color(0xFFF7F7F7);

    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    final hintColor = isDarkMode
        ? Colors.white.withOpacity(0.42)
        : Colors.black.withOpacity(0.42);

    final textColor = isDarkMode ? Colors.white : Colors.black;

    final neutralIconColor = isDarkMode
        ? Colors.white.withOpacity(0.78)
        : Colors.black.withOpacity(0.78);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: isDarkMode ? Colors.white : Colors.black,
        style: TextStyle(
          color: textColor,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search settings...',
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 10, right: 8),
            child: Center(
              widthFactor: 1,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDarkMode ? 0.10 : 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    color: neutralIconColor,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}