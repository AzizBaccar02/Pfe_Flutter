// lib/screens/offers/client/widgets/client_home_stats_strip.dart

import 'package:flutter/material.dart';

import 'client_home_theme.dart';

class ClientHomeStatItem {
  final String label;
  final String value;

  const ClientHomeStatItem({
    required this.label,
    required this.value,
  });
}

class ClientHomeStatsStrip extends StatelessWidget {
  final bool isDarkMode;
  final List<ClientHomeStatItem> items;

  const ClientHomeStatsStrip({
    super.key,
    required this.isDarkMode,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: ClientHomeTheme.cardBackground(isDarkMode),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientHomeTheme.cardBorder(isDarkMode)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 32,
                color: ClientHomeTheme.cardBorder(isDarkMode),
              ),
            Expanded(
              child: _StatCell(
                item: items[i],
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final ClientHomeStatItem item;
  final bool isDarkMode;

  const _StatCell({
    required this.item,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          item.value,
          style: TextStyle(
            color: ClientHomeTheme.primaryText(isDarkMode),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ClientHomeTheme.secondaryText(isDarkMode),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
