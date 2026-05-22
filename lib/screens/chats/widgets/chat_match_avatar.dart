// lib/screens/chats/widgets/chat_match_avatar.dart

import 'package:flutter/material.dart';

import '../../../models/chat_conversation_summary_model.dart';
import '../../../services/profile_service.dart';

class ChatMatchAvatar extends StatelessWidget {
  final ChatConversationSummaryModel chat;
  final int currentUserId;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback? onTap;

  const ChatMatchAvatar({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF22C55E);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final offerName = chat.offerTitle;
    final displayInitials = chat.displayInitials;
    final isOnline = chat.peerOnlineForViewer(currentUserId);
    final resolved = ProfileService.resolveMediaUrl(
      chat.resolvePeerPhotoUrl(viewerUserId: currentUserId).trim(),
    );
    const radius = 33.0;
    final diameter = radius * 2;

    Widget initialsFace() {
      return Text(
        displayInitials,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: primaryTextColor.withOpacity(0.76),
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
      );
    }

    Widget avatarCore() {
      final innerBg = isDarkMode ? Colors.black : const Color(0xFFF3F4F6);
      if (resolved != null && resolved.isNotEmpty) {
        return ClipOval(
          child: Container(
            width: diameter,
            height: diameter,
            color: innerBg,
            child: Image.network(
              resolved,
              width: diameter,
              height: diameter,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Center(child: initialsFace()),
            ),
          ),
        );
      }
      return CircleAvatar(
        radius: radius,
        backgroundColor: innerBg,
        child: initialsFace(),
      );
    }

    /// Same soft ring for all states — unread is not shown on the avatar here.
    final ringGradient = [
      accentGreen.withOpacity(0.34),
      accentGreen.withOpacity(0.12),
    ];

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
                      colors: ringGradient,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF0B0F14) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: avatarCore(),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF0B0F14)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode
                            ? const Color(0xFF0B0F14)
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOnline ? accentGreen : secondaryTextColor,
                          shape: BoxShape.circle,
                        ),
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
          ],
        ),
      ),
    );
  }
}
