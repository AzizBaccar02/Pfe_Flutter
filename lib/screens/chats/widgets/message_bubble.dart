// lib/screens/chats/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

import '../../../models/chat_message_model.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isDarkMode;
  final bool isMine;
  final String avatarInitials;
  /// Resolved absolute URL for the peer's profile photo (incoming rows only).
  final String? avatarPhotoUrl;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isDarkMode,
    required this.isMine,
    required this.avatarInitials,
    this.avatarPhotoUrl,
    this.onAvatarTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? (isDarkMode ? const Color(0xFF1A2E22) : const Color(0xFFD9FDD3))
        : (isDarkMode ? const Color(0xFF1A1A1A) : Colors.white);

    final messageColor = isMine
        ? (isDarkMode ? Colors.white : const Color(0xFF173D24))
        : (isDarkMode ? Colors.white : const Color(0xFF111827));

    final metaColor = isMine
        ? (isDarkMode
            ? Colors.white.withOpacity(0.72)
            : const Color(0xFF1F6B37).withOpacity(0.72))
        : (isDarkMode
            ? Colors.white.withOpacity(0.48)
            : Colors.black.withOpacity(0.42));

    final shadowColor = isDarkMode
        ? Colors.black.withOpacity(0.18)
        : Colors.black.withOpacity(0.06);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            GestureDetector(
              onTap: onAvatarTap,
              behavior: HitTestBehavior.opaque,
              child: _IncomingAvatar(
                photoUrl: avatarPhotoUrl,
                initials: avatarInitials,
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 292),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(13, 9, 11, 7),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMine ? 14 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.isEdited) ...[
                        Text(
                          'edited',
                          style: TextStyle(
                            color: metaColor,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        message.text,
                        style: TextStyle(
                          color: messageColor,
                          fontSize: 14,
                          height: 1.36,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.sentAt),
                            style: TextStyle(
                              color: metaColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 5),
                            Icon(
                              message.isRead
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 15,
                              color: message.isRead
                                  ? AppColors.accent
                                  : metaColor,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _IncomingAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final bool isDarkMode;

  const _IncomingAvatar({
    this.photoUrl,
    required this.initials,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 10.0;
    final diameter = radius * 2;
    final baseBg =
        isDarkMode ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final resolved = photoUrl?.trim();

    Widget letter() {
      return Text(
        initials.isNotEmpty ? initials.substring(0, 1) : '?',
        style: TextStyle(
          color: isDarkMode ? Colors.white : const Color(0xFF4B5563),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    if (resolved != null && resolved.isNotEmpty) {
      return ClipOval(
        child: Container(
          width: diameter,
          height: diameter,
          color: baseBg,
          child: Image.network(
            resolved,
            width: diameter,
            height: diameter,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Center(child: letter()),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: baseBg,
      child: letter(),
    );
  }
}