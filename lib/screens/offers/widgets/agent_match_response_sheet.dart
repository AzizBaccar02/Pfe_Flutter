// lib/screens/offers/widgets/agent_match_response_sheet.dart

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/app_notification_model.dart';

class AgentMatchResponseSheet {
  static Future<void> show(
    BuildContext context, {
    required AppNotificationModel notification,
    required VoidCallback onStartChat,
  }) async {
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        const accentGreen = Color(0xFF22C55E);

        final backgroundColor =
            isDarkMode ? const Color(0xFF111827) : Colors.white;
        final primaryTextColor =
            isDarkMode ? Colors.white : const Color(0xFF111827);
        final secondaryTextColor = isDarkMode
            ? Colors.white.withOpacity(0.62)
            : Colors.black.withOpacity(0.58);

        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: secondaryTextColor.withOpacity(0.34),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: accentGreen.withOpacity(isDarkMode ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedFavourite,
                      color: accentGreen,
                      size: 29,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  notification.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  notification.body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      onStartChat();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Start conversation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryTextColor,
                      side: BorderSide(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.14)
                            : Colors.black.withOpacity(0.12),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Not now',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
