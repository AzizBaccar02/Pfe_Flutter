import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

import '../client/widgets/client_home_theme.dart';

class HomeInfoPill extends StatelessWidget {
  final String text;
  final bool isDarkMode;

  const HomeInfoPill({
    super.key,
    required this.text,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.accent.withValues(alpha: 0.1)
            : AppColors.accentSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: ClientHomeTheme.accent(isDarkMode),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
