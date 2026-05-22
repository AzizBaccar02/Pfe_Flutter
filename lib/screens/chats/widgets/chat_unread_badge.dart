// lib/screens/chats/widgets/chat_unread_badge.dart

import 'package:flutter/material.dart';

/// Solid green pill used on chat list rows and the bottom nav.
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

    return Container(
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1.1,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
