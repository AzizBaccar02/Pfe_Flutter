import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../client/widgets/client_home_theme.dart';

class HomeEmptyCard extends StatelessWidget {
  final String text;
  final bool isDarkMode;
  final dynamic icon;

  const HomeEmptyCard({
    super.key,
    required this.text,
    required this.isDarkMode,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryText = ClientHomeTheme.secondaryText(isDarkMode);
    final accent = ClientHomeTheme.accent(isDarkMode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: ClientHomeTheme.cardBackground(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientHomeTheme.cardBorder(isDarkMode)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ClientHomeTheme.elevatedSurface(isDarkMode),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: HugeIcon(
                icon: icon ?? HugeIcons.strokeRoundedInformationCircle,
                color: accent.withValues(alpha: 0.85),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: secondaryText,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
