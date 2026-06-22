// lib/screens/chats/widgets/chat_match_avatar.dart

import 'package:flutter/material.dart';

import '../../../models/chat_conversation_summary_model.dart';
import '../../../services/profile_service.dart';

class ChatMatchAvatar extends StatelessWidget {
  static const double listHeight = 94;

  final ChatConversationSummaryModel chat;
  final int currentUserId;
  final String viewerRole;
  final List<dynamic>? matchedAgents;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback? onTap;

  const ChatMatchAvatar({
    super.key,
    required this.chat,
    required this.currentUserId,
    this.viewerRole = '',
    this.matchedAgents,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final offerName = chat.offerTitle;
    final displayInitials = chat.peerDisplayInitialsForViewer(
      currentUserId,
      viewerRole: viewerRole,
    );
    final resolved = ProfileService.resolveMediaUrl(
      chat
          .resolvePeerPhotoUrl(
            viewerUserId: currentUserId,
            viewerRole: viewerRole,
          )
          .trim(),
    );

    const avatarSize = 56.0;
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);

    Widget initialsFace() {
      return Text(
        displayInitials,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: primaryTextColor.withOpacity(0.76),
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
      );
    }

    Widget avatarCore() {
      final innerBg = isDarkMode ? Colors.black : const Color(0xFFF3F4F6);
      if (resolved != null && resolved.isNotEmpty) {
        return ColoredBox(
          color: innerBg,
          child: Image.network(
            resolved,
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Center(child: initialsFace()),
          ),
        );
      }
      return ColoredBox(
        color: innerBg,
        child: Center(child: initialsFace()),
      );
    }

    return SizedBox(
      width: 82,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1),
              ),
              child: ClipOval(child: avatarCore()),
            ),
            const SizedBox(height: 6),
            Text(
              offerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
