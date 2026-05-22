// lib/screens/chats/widgets/chat_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../models/chat_conversation_summary_model.dart';
import '../../../services/profile_service.dart';
import 'chat_offer_label.dart';
import 'chat_unread_badge.dart';

class ChatTile extends StatelessWidget {
  final ChatConversationSummaryModel chat;
  final int currentUserId;
  /// Resolved title (local nickname or server display name).
  final String conversationTitle;
  final String trailingText;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback? onTap;
  final VoidCallback? onCloseOffer;
  final VoidCallback? onDeleteChat;
  final VoidCallback? onArchiveChat;
  final VoidCallback? onUnarchive;
  /// Distinct [Slidable] group so archived and main lists do not auto-close each other.
  final String slidableGroupTag;

  const ChatTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.conversationTitle,
    required this.trailingText,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    this.onTap,
    this.onCloseOffer,
    this.onDeleteChat,
    this.onArchiveChat,
    this.onUnarchive,
    this.slidableGroupTag = 'chats_screen',
  });

  static const _accentGreen = Color(0xFF22C55E);
  static const _closeOfferColor = Color(0xFFC9A227);
  static const _deleteColor = Color(0xFFE53935);
  static const _archiveColor = Color(0xFF6B7280);
  static const _unarchiveColor = Color(0xFF15803D);

  Widget _buildAvatar({
    required bool isDarkMode,
    required bool isPeerOnline,
  }) {
    final resolved = ProfileService.resolveMediaUrl(
      chat.resolvePeerPhotoUrl(viewerUserId: currentUserId).trim(),
    );
    const radius = 26.0;
    final diameter = radius * 2;
    final initials = chat.displayInitials;
    final ringColor = isDarkMode ? Colors.black : Colors.white;

    Widget initialsLabel() {
      return Text(
        initials,
        style: TextStyle(
          color: primaryTextColor.withOpacity(0.82),
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    Widget avatarFace() {
      final baseBg = isDarkMode ? Colors.black : const Color(0xFFE5E7EB);
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
              errorBuilder: (context, error, stackTrace) =>
                  Center(child: initialsLabel()),
            ),
          ),
        );
      }
      return CircleAvatar(
        radius: radius,
        backgroundColor: baseBg,
        child: initialsLabel(),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatarFace(),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: ringColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: ringColor,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isPeerOnline ? _accentGreen : secondaryTextColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final hasUnread = chat.hasUnreadIncomingForViewer(currentUserId);
    final unreadCount = chat.effectiveUnreadCountForViewer(currentUserId);
    final lastMessage = chat.lastMessage;
    final isLastMessageMine = chat.isLastMessageFromViewer(currentUserId);
    final isPeerOnline = chat.peerOnlineForViewer(currentUserId);

    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(
                isDarkMode: isDarkMode,
                isPeerOnline: isPeerOnline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversationTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 16.5,
                        fontWeight: hasUnread
                            ? FontWeight.w900
                            : FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLastMessageMine && lastMessage != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              lastMessage.isRead
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 14,
                              color: lastMessage.isRead
                                  ? _accentGreen
                                  : secondaryTextColor.withOpacity(0.82),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              chat.previewText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasUnread
                                    ? primaryTextColor.withOpacity(0.95)
                                    : secondaryTextColor,
                                fontSize: 13.5,
                                height: 1.15,
                                fontWeight: hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ChatOfferLabel(
                              offerTitle: chat.offerTitle,
                              color: secondaryTextColor,
                              maxWidth: 148,
                              textAlign: TextAlign.end,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  trailingText,
                                  style: TextStyle(
                                    color: hasUnread
                                        ? _accentGreen
                                        : secondaryTextColor,
                                    fontSize: 12,
                                    fontWeight: hasUnread
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                                  ),
                                ),
                                if (hasUnread) ...[
                                  const SizedBox(width: 6),
                                  ChatUnreadBadge(count: unreadCount),
                                ],
                              ],
                            ),
                          ],
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
    );

    final hasActions = onCloseOffer != null ||
        onDeleteChat != null ||
        onArchiveChat != null ||
        onUnarchive != null;

    if (!hasActions) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: tile,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        key: ValueKey('chat_slidable_${chat.id}'),
        groupTag: slidableGroupTag,
        closeOnScroll: true,
        endActionPane: ActionPane(
          extentRatio: 0.46,
          motion: const DrawerMotion(),
          children: [
            if (onCloseOffer != null)
              SlidableAction(
                onPressed: (_) => onCloseOffer!(),
                backgroundColor: _closeOfferColor,
                foregroundColor: Colors.white,
                icon: Icons.work_off_outlined,
                label: 'Close offer',
              ),
            if (onDeleteChat != null)
              SlidableAction(
                onPressed: (_) => onDeleteChat!(),
                backgroundColor: _deleteColor,
                foregroundColor: Colors.white,
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
              ),
            if (onArchiveChat != null)
              SlidableAction(
                onPressed: (_) => onArchiveChat!(),
                backgroundColor: _archiveColor,
                foregroundColor: Colors.white,
                icon: Icons.archive_outlined,
                label: 'Archive',
              ),
            if (onUnarchive != null)
              SlidableAction(
                onPressed: (_) => onUnarchive!(),
                backgroundColor: _unarchiveColor,
                foregroundColor: Colors.white,
                icon: Icons.unarchive_outlined,
                label: 'Unarchive',
              ),
          ],
        ),
        child: tile,
      ),
    );
  }
}
