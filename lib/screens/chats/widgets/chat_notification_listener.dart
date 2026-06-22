// lib/screens/chats/widgets/chat_notification_listener.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';

import '../../../models/chat_conversation_summary_model.dart';
import '../../../models/chat_message_model.dart';
import '../../../services/app_navigator.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_active_conversation_tracker.dart';
import '../../../services/chat_conversation_display_name_service.dart';
import '../../../services/chat_local_read_cursor.dart';
import '../../../services/chat_realtime_hub.dart';
import '../../../services/chat_service.dart';
import '../../../utils/chat_unread_merge.dart';
import '../chat_conversation_screen.dart';

typedef ChatsTabActivePredicate = bool Function();

class ChatNotificationListener extends StatefulWidget {
  final Widget child;
  final ChatsTabActivePredicate isChatsTabActive;
  final ValueChanged<int>? onUnreadCountChanged;
  final Future<void> Function()? onChatOpened;
  final bool useGlobalTopInset;

  const ChatNotificationListener({
    super.key,
    required this.child,
    required this.isChatsTabActive,
    this.onUnreadCountChanged,
    this.onChatOpened,
    this.useGlobalTopInset = false,
  });

  @override
  State<ChatNotificationListener> createState() =>
      _ChatNotificationListenerState();
}

class _ChatNotificationListenerState extends State<ChatNotificationListener> {
  Timer? _hideTimer;
  StreamSubscription<Map<String, dynamic>>? _hubSubscription;

  bool _isSyncing = false;
  bool _hasSeededInitialState = false;
  bool _isBannerVisible = false;

  int _currentUserId = 0;

  ChatConversationSummaryModel? _activeNotificationChat;

  final Map<int, _ChatNotificationSnapshot> _snapshots = {};
  List<ChatConversationSummaryModel> _cachedChats = [];

  @override
  void initState() {
    super.initState();
    _bootstrapListener();
    _hubSubscription = ChatRealtimeHub.instance.onInboxEvent.listen(
      _handleInboxEvent,
    );
    unawaited(ChatRealtimeHub.instance.ensureStarted());
  }

  @override
  void didUpdateWidget(covariant ChatNotificationListener oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isChatsTabActive()) {
      _hideBanner();
      _syncChats();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hubSubscription?.cancel();
    super.dispose();
  }

  void _handleInboxEvent(Map<String, dynamic> data) {
    if (!ChatRealtimeHub.isMessageRelatedEvent(data)) return;

    if (!widget.isChatsTabActive()) {
      unawaited(_tryShowBannerFromInboxEvent(data));
    }

    unawaited(_syncChats());
  }

  Future<void> _tryShowBannerFromInboxEvent(Map<String, dynamic> data) async {
    if (_currentUserId <= 0) return;

    final rawChat = data['chat'];
    ChatConversationSummaryModel? chat;

    if (rawChat is Map) {
      try {
        chat = ChatConversationSummaryModel.fromJson(
          Map<String, dynamic>.from(rawChat),
        );
      } catch (_) {
        chat = null;
      }
    }

    final rawMessage = data['message'];
    if (chat != null && rawMessage is Map) {
      try {
        final message = ChatMessageModel.fromJson(
          json: Map<String, dynamic>.from(rawMessage),
          clientId: chat.client?.id ?? 0,
          agentId: chat.agent?.id ?? 0,
          clientUserId: chat.client?.userId,
          agentUserId: chat.agent?.userId,
        );

        if (message.senderId == _currentUserId) return;

        final lastSummary = ChatLastMessageSummary(
          id: message.id,
          content: message.text,
          senderId: message.senderId,
          isRead: false,
          sentAt: message.sentAt,
        );

        chat = ChatLocalReadCursor.instance.applyToSummary(
          chat.copyWith(lastMessage: lastSummary),
          _currentUserId,
        );
      } catch (_) {
        // Fall back to summary-only banner below.
      }
    }

    if (chat == null || chat.id <= 0) return;
    if (chat.lastMessage?.senderId == _currentUserId) return;
    if (ChatActiveConversationTracker.instance.isViewing(chat.id)) return;

    await _showBanner(chat);
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
      await ChatLocalReadCursor.instance.ensureLoaded();

      final response = await ChatService.getCurrentUserChats();
      final chats = ChatUnreadMerge.mergeLists(
        serverChats: response.chats,
        previousChats: _cachedChats,
        viewerUserId: _currentUserId,
      );
      _cachedChats = chats;
      final totalUnreadCount = _sumUnread(chats, _currentUserId);

      widget.onUnreadCountChanged?.call(totalUnreadCount);

      final cursor = ChatLocalReadCursor.instance;
      final unreadIncomingChats = chats
          .where((chat) => cursor.hasIncomingUnread(chat, _currentUserId))
          .toList();

      if (!_hasSeededInitialState) {
        _seedSnapshots(chats);
        _hasSeededInitialState = true;

        if (!mounted) return;

        if (!widget.isChatsTabActive() && unreadIncomingChats.isNotEmpty) {
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

      if (newMessageChats.isNotEmpty && !widget.isChatsTabActive()) {
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
    if (widget.isChatsTabActive()) return;
    if (ChatActiveConversationTracker.instance.isViewing(chat.id)) return;

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

    final navContext = AppNavigator.context;
    if (navContext == null || !navContext.mounted) return;

    await Navigator.of(navContext).push(
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(chat: chat),
      ),
    );

    if (!mounted) return;

    ChatUnreadMerge.trustServerUnreadForChat(chat.id);
    await widget.onChatOpened?.call();
    await _syncChats();
  }

  @override
  Widget build(BuildContext context) {
    final chat = _activeNotificationChat;
    final topInset = widget.useGlobalTopInset
        ? MediaQuery.paddingOf(context).top + 10
        : 16.0;

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 16,
          right: 16,
          top: topInset,
          child: IgnorePointer(
            ignoring: !_isBannerVisible || chat == null,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              offset: _isBannerVisible && chat != null
                  ? Offset.zero
                  : const Offset(0, -1.25),
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

  static int _sumUnread(
    List<ChatConversationSummaryModel> chats,
    int viewerUserId,
  ) {
    final cursor = ChatLocalReadCursor.instance;

    return chats.fold<int>(
      0,
      (total, chat) => total + cursor.displayUnreadCount(chat, viewerUserId),
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
    const accentGreen = AppColors.accent;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    final backgroundColor =
        isDarkMode ? const Color(0xFF141414) : Colors.white;
    final primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDarkMode
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF4B5563);
    final tertiaryTextColor = isDarkMode
        ? const Color(0xFF6B7280)
        : const Color(0xFF9CA3AF);
    final labelColor = isDarkMode
        ? AppColors.accentReadableOnDark.withValues(alpha: 0.92)
        : AppColors.accentReadable;
    final dividerColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final closeButtonColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final shadowColor = isDarkMode
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.10);

    final preview = chat.previewText.trim();
    final offer = chat.offerTitle.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentGreen.withValues(alpha: isDarkMode ? 0.22 : 0.20),
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentGreen.withValues(alpha: isDarkMode ? 0.12 : 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedMessage02,
                    color: accentGreen,
                    size: 22,
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
                        Text(
                          'NEW MESSAGE',
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: dividerColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      peerTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.25,
                        height: 1.15,
                      ),
                    ),
                    if (offer.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        offer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tertiaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: closeButtonColor,
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