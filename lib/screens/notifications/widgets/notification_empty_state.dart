import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';


class NotificationEmptyState extends StatelessWidget {
  final bool isDarkMode;

  const NotificationEmptyState({
    super.key,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = AppColors.accent;

    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);

    final neutralIconColor = isDarkMode
        ? Colors.white.withOpacity(0.78)
        : Colors.black.withOpacity(0.78);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF141414) : const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(isDarkMode ? 0.10 : 0.14),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedNotification03,
                    color: neutralIconColor,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No notifications yet',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'When someone messages you, matches with you, or interacts with your offers, updates will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}