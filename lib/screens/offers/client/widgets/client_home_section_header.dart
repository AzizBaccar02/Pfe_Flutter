// lib/screens/offers/client/widgets/client_home_section_header.dart

import 'package:flutter/material.dart';

import 'client_home_theme.dart';

class ClientHomeSectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;
  final bool isDarkMode;

  const ClientHomeSectionHeader({
    super.key,
    required this.title,
    required this.isDarkMode,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ClientHomeTheme.primaryText(isDarkMode);
    final highlight = ClientHomeTheme.highlight(isDarkMode);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: primary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (actionText != null && onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            behavior: HitTestBehavior.opaque,
            child: Text(
              actionText!,
              style: TextStyle(
                color: highlight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
