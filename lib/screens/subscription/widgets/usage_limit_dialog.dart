import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

import '../subscription_hub_screen.dart';

class UsageLimitDialog {
  static bool isUsageLimitMessage(String message) {
    final lower = message.toLowerCase();

    return lower.contains('free tries') ||
        lower.contains('no remaining subscription') ||
        lower.contains('subscription has expired') ||
        lower.contains('subscription is not active') ||
        lower.contains('subscription has not started') ||
        lower.contains('subscription usage limit') ||
        lower.contains('subscribe to continue') ||
        lower.contains('renew to continue') ||
        lower.contains('renew your subscription');
  }

  static Future<void> show(
    BuildContext context, {
    required bool isAgent,
    String? message,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bg = isDarkMode ? const Color(0xFF141414) : Colors.white;
    final primary = isDarkMode ? Colors.white : Colors.black;
    final secondary = isDarkMode
        ? Colors.white.withValues(alpha: 0.65)
        : Colors.black.withValues(alpha: 0.6);
    const accent = AppColors.accent;

    final actionLabel = isAgent ? 'offer reactions' : 'offer posts';
    final defaultMessage =
        'You have reached your free $actionLabel limit. Subscribe to JobMatch Plus to keep going.';

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Limit reached',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          message?.trim().isNotEmpty == true ? message!.trim() : defaultMessage,
          style: TextStyle(
            color: secondary,
            height: 1.5,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Not now',
              style: TextStyle(
                color: secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubscriptionHubScreen(isAgent: isAgent),
                ),
              );
            },
            child: const Text(
              'View plans',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
