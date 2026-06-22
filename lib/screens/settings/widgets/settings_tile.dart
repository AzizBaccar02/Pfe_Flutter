import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';


class SettingsTile extends StatelessWidget {
  final bool isDarkMode;
  final String title;
  final String subtitle;
  final dynamic icon;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool danger;

  const SettingsTile({
    super.key,
    required this.isDarkMode,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.accent;
    const dangerColor = Color(0xFFE53935);

    final neutralIconColor = isDarkMode
        ? Colors.white.withOpacity(0.78)
        : Colors.black.withOpacity(0.78);

    final primaryTextColor = danger
        ? dangerColor
        : (isDarkMode ? Colors.white : Colors.black);

    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.60)
        : Colors.black.withOpacity(0.56);

    final iconBackgroundColor = danger
        ? dangerColor.withOpacity(isDarkMode ? 0.12 : 0.14)
        : accent.withValues(alpha: isDarkMode ? 0.10 : 0.14);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  color: danger ? dangerColor : neutralIconColor,
                  size: 18,
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
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: danger ? dangerColor : secondaryTextColor,
                  size: 18,
                ),
          ],
        ),
      ),
    );
  }
}