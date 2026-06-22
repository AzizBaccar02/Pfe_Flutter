import 'package:flutter/material.dart';

import '../client/widgets/client_home_theme.dart';

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
    final primaryText = ClientHomeTheme.primaryText(isDarkMode);
    final accent = ClientHomeTheme.accent(isDarkMode);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (actionText != null && onActionTap != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onActionTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText!,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: accent,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
