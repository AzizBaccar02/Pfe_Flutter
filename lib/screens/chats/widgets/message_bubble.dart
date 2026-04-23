import 'package:flutter/material.dart';

import '../../../models/chat_message_model.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isDarkMode;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = message.isFromClient;

    final bubbleColor = isMine
        ? const Color.fromARGB(255, 139, 107, 1)
        : (isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF1F1F1));

    final messageColor = isMine
        ? Colors.white
        : (isDarkMode ? Colors.white : Colors.black);

    final metaColor = isMine
        ? Colors.white.withOpacity(0.82)
        : (isDarkMode
              ? Colors.white.withOpacity(0.56)
              : Colors.black.withOpacity(0.50));

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(22),
                topRight: const Radius.circular(22),
                bottomLeft: Radius.circular(isMine ? 22 : 8),
                bottomRight: Radius.circular(isMine ? 8 : 22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: messageColor,
                    fontSize: 14.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.sentAt),
                      style: TextStyle(
                        color: metaColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      Text(
                        message.isRead ? 'Seen' : 'Sent',
                        style: TextStyle(
                          color: metaColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}