import 'package:flutter/material.dart';

class HomeSectionTitle extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final bool isDarkMode;

  const HomeSectionTitle({
    super.key,
    required this.title,
    required this.isDarkMode,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.68)
        : Colors.black.withOpacity(0.68);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actionText != null && onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionText!,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}