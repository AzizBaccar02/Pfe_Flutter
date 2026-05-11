// lib/screens/chats/widgets/chat_tile.dart

import 'package:flutter/material.dart';

import '../../../models/chat_conversation_summary_model.dart';

class ChatTile extends StatelessWidget {
  final ChatConversationSummaryModel chat;
  final int currentUserId;
  final String trailingText;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback? onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.trailingText,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF22C55E);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final cardColor =
        isDarkMode ? const Color(0xFF111827) : Colors.white;

    final avatarColor =
        isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

    final hasUnread = chat.unreadCount > 0;
    final lastMessage = chat.lastMessage;
    final isLastMessageMine =
        lastMessage != null && lastMessage.senderId == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: hasUnread
                    ? accentGreen.withOpacity(0.26)
                    : (isDarkMode
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.14 : 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: hasUnread
                          ? accentGreen.withOpacity(0.14)
                          : avatarColor,
                      child: Text(
                        chat.displayInitials,
                        style: TextStyle(
                          color: hasUnread
                              ? accentGreen
                              : primaryTextColor.withOpacity(0.82),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: accentGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: cardColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 16.2,
                                fontWeight:
                                    hasUnread ? FontWeight.w900 : FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            trailingText,
                            style: TextStyle(
                              color: hasUnread
                                  ? accentGreen
                                  : secondaryTextColor,
                              fontSize: 12,
                              fontWeight:
                                  hasUnread ? FontWeight.w900 : FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (isLastMessageMine) ...[
                            Icon(
                              lastMessage!.isRead
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 15,
                              color: lastMessage.isRead
                                  ? accentGreen
                                  : secondaryTextColor.withOpacity(0.82),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              chat.previewText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasUnread
                                    ? primaryTextColor.withOpacity(0.86)
                                    : secondaryTextColor,
                                fontSize: 13.8,
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accentGreen.withOpacity(
                                  isDarkMode ? 0.12 : 0.09,
                                ),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: accentGreen.withOpacity(0.18),
                                ),
                              ),
                              child: Text(
                                chat.offerTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.84)
                                      : const Color(0xFF166534),
                                  fontSize: 11.4,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (hasUnread)
                            Container(
                              constraints: const BoxConstraints(
                                minWidth: 22,
                                minHeight: 22,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              decoration: const BoxDecoration(
                                color: accentGreen,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                chat.unreadCount > 9
                                    ? '9+'
                                    : '${chat.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}