// lib/screens/chats/widgets/chat_match_avatar.dart

import 'package:flutter/material.dart';

import '../../../models/chat_conversation_summary_model.dart';

class ChatMatchAvatar extends StatelessWidget {
  final ChatConversationSummaryModel chat;
  final Color primaryTextColor;
  final bool hasUnread;
  final VoidCallback? onTap;

  const ChatMatchAvatar({
    super.key,
    required this.chat,
    required this.primaryTextColor,
    required this.hasUnread,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF22C55E);
    const accentGreenSoft = Color(0xFF86EFAC);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final offerName = chat.offerTitle;
    final initials = _buildInitials(offerName);

    return SizedBox(
      width: 96,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: hasUnread
                          ? const [
                              accentGreenSoft,
                              accentGreen,
                            ]
                          : [
                              accentGreen.withOpacity(0.34),
                              accentGreen.withOpacity(0.12),
                            ],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF0B0F14) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 33,
                      backgroundColor:
                          isDarkMode ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                      child: Text(
                        initials,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: hasUnread
                              ? accentGreen
                              : primaryTextColor.withOpacity(0.76),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 3,
                    top: 4,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: accentGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF0B0F14)
                              : Colors.white,
                          width: 2.4,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              offerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 12.8,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              chat.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor.withOpacity(0.48),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildInitials(String value) {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty) return '?';

    final parts = cleanValue
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      final word = parts.first;

      if (word.length >= 2) {
        return word.substring(0, 2).toUpperCase();
      }

      return word.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}