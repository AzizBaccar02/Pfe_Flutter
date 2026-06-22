// lib/screens/chats/widgets/chat_unread_badge.dart

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

/// Compact unread count pill on chat list rows (beside time label).
class ChatUnreadBadge extends StatelessWidget {
  final int count;

  const ChatUnreadBadge({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final label = count > 9 ? '9+' : '$count';
    final isSingleDigit = label.length == 1;

    return Container(
      height: 15,
      constraints: BoxConstraints(
        minWidth: isSingleDigit ? 15 : 19,
      ),
      padding: EdgeInsets.symmetric(horizontal: isSingleDigit ? 0 : 4),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: -0.25,
        ),
      ),
    );
  }
}
