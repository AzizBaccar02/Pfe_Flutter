// lib/screens/chats/widgets/chat_notification_listener.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../models/chat_conversation_summary_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_conversation_display_name_service.dart';
import '../../../services/chat_service.dart';
import '../chat_conversation_screen.dart';

class ChatNotificationListener extends StatefulWidget {
  final Widget child;
  final bool isChatsTabActive;
  final ValueChanged<int>? onUnreadCountChanged;
  final Future<void> Function()? onChatOpened;

  const ChatNotificationListener({
    super.key,
    required this.child,
    required this.isChatsTabActive,
    this.onUnreadCountChanged,
    this.onChatOpened,
  });

  @override
  State<ChatNotificationListener> createState() =>
      _ChatNotificationListenerState();
}

class _ChatNotificationListenerState extends State<ChatNotificationListener> {
  Timer? _hideTimer;

  bool _isSyncing = false;
  bool _hasSeededInitialState = false;
  bool _isBannerVisible = false;

  int _currentUserId = 0;

  ChatConversationSummaryModel? _activeNotificationChat;

  final Map<int, _ChatNotificationSnapshot> _snapshots = {};

  @override
  void initState() {
    super.initState();
    _bootstrapListener();
  }

  @override
  void didUpdateWidget(covariant ChatNotificationListener oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isChatsTabActive && !oldWidget.isChatsTabActive) {
      _hideBanner();
      _syncChats();
    }

    if (!widget.isChatsTabActive && oldWidget.isChatsTabActive) {
      _syncChats();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrapListener() async {
    final storedUserId = await AuthService.getStoredUserId();

    if (!mounted) return;

    setState(() {
      _currentUserId = storedUserId ?? 0;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncChats();
    });
  }

  Future<void> _syncChats() async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      final response = await ChatService.getCurrentUserChats();
      final chats = response.chats;
      final totalUnreadCount = _sumUnread(chats);

      widget.onUnreadCountChanged?.call(totalUnreadCount);

      final unreadIncomingChats = chats.where((chat) {
        final lastMessage = chat.lastMessage;

        if (chat.unreadCount <= 0) return false;
        if (lastMessage == null) return false;

        return lastMessage.senderId != _currentUserId;
      }).toList();

      if (!_hasSeededInitialState) {
        _seedSnapshots(chats);
        _hasSeededInitialState = true;

        if (!mounted) return;

        if (!widget.isChatsTabActive && unreadIncomingChats.isNotEmpty) {
          await _showBanner(_latestChat(unreadIncomingChats));
        }

        return;
      }

      final newMessageChats = <ChatConversationSummaryModel>[];

      for (final chat in chats) {
        final lastMessage = chat.lastMessage;

        if (lastMessage == null) continue;
        if (chat.unreadCount <= 0) continue;
        if (lastMessage.senderId == _currentUserId) continue;

        final previous = _snapshots[chat.id];

        final currentUnread = chat.unreadCount;
        final currentLastMessageId = lastMessage.id;

        final previousUnread = previous?.unreadCount ?? 0;
        final previousLastMessageId = previous?.lastMessageId ?? 0;

        final unreadIncreased = currentUnread > previousUnread;
        final lastMessageChanged =
            currentLastMessageId != 0 &&
            currentLastMessageId != previousLastMessageId;

        final isNewChatForListener = previous == null;

        if (unreadIncreased || lastMessageChanged || isNewChatForListener) {
          newMessageChats.add(chat);
        }
      }

      _seedSnapshots(chats);

      if (!mounted) return;

      if (newMessageChats.isNotEmpty && !widget.isChatsTabActive) {
        await _showBanner(_latestChat(newMessageChats));
      }
    } catch (_) {
      // Global notification sync should stay silent.
    } finally {
      _isSyncing = false;
    }
  }

  ChatConversationSummaryModel _latestChat(
    List<ChatConversationSummaryModel> chats,
  ) {
    final sortedChats = [...chats];

    sortedChats.sort((a, b) {
      final aDate = a.lastActivityDate;
      final bDate = b.lastActivityDate;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return sortedChats.first;
  }

  void _seedSnapshots(List<ChatConversationSummaryModel> chats) {
    _snapshots
      ..clear()
      ..addEntries(
        chats.map(
          (chat) => MapEntry(
            chat.id,
            _ChatNotificationSnapshot(
              unreadCount: chat.unreadCount,
              lastMessageId: chat.lastMessage?.id ?? 0,
            ),
          ),
        ),
      );
  }

  Future<void> _showBanner(ChatConversationSummaryModel chat) async {
    _hideTimer?.cancel();

    await ChatConversationDisplayNameService.instance.ensureLoaded();
    if (!mounted) return;

    setState(() {
      _activeNotificationChat = chat;
      _isBannerVisible = true;
    });

    _hideTimer = Timer(const Duration(seconds: 6), () {
      _hideBanner();
    });
  }

  void _hideBanner() {
    if (!mounted) return;

    _hideTimer?.cancel();

    setState(() {
      _isBannerVisible = false;
    });
  }

  Future<void> _openNotificationChat() async {
    final chat = _activeNotificationChat;

    if (chat == null) return;

    _hideBanner();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(chat: chat),
      ),
    );

    if (!mounted) return;

    await widget.onChatOpened?.call();
    await _syncChats();
  }

  @override
  Widget build(BuildContext context) {
    final chat = _activeNotificationChat;

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: IgnorePointer(
            ignoring: !_isBannerVisible || chat == null,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              offset: _isBannerVisible && chat != null
                  ? Offset.zero
                  : const Offset(0, -1.35),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _isBannerVisible && chat != null ? 1 : 0,
                child: chat == null
                    ? const SizedBox.shrink()
                    : _NewMessageBanner(
                        chat: chat,
                        peerTitle:
                            ChatConversationDisplayNameService.instance
                                .resolve(chat.id, chat.displayName),
                        onTap: _openNotificationChat,
                        onClose: _hideBanner,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static int _sumUnread(List<ChatConversationSummaryModel> chats) {
    return chats.fold<int>(
      0,
      (total, chat) => total + chat.unreadCount,
    );
  }
}

class _NewMessageBanner extends StatelessWidget {
  final ChatConversationSummaryModel chat;
  final String peerTitle;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _NewMessageBanner({
    required this.chat,
    required this.peerTitle,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF22C55E);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDarkMode ? const Color(0xFF111827) : Colors.white;

    final primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF111827);

    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.56);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentGreen.withOpacity(isDarkMode ? 0.24 : 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.32 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(isDarkMode ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedMessage02,
                    color: accentGreen,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'New message',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 14.8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: accentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$peerTitle • ${chat.offerTitle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chat.previewText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryTextColor.withOpacity(
                          isDarkMode ? 0.82 : 0.76,
                        ),
                        fontSize: 13.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatNotificationSnapshot {
  final int unreadCount;
  final int lastMessageId;

  const _ChatNotificationSnapshot({
    required this.unreadCount,
    required this.lastMessageId,
  });
}