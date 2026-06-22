import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';

import '../client/widgets/client_home_theme.dart';

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
    final primaryText = ClientHomeTheme.primaryText(isDarkMode);
    final secondaryText = ClientHomeTheme.secondaryText(isDarkMode);
    final accent = ClientHomeTheme.accent(isDarkMode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: ClientHomeTheme.cardBackground(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientHomeTheme.cardBorder(isDarkMode)),
        boxShadow: ClientHomeTheme.cardShadow(isDarkMode),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : AppColors.accentSurface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: HugeIcon(
                icon: icon,
                color: accent,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.1,
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
