// lib/services/chat_local_read_cursor.dart

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_conversation_summary_model.dart';

/// Per-device read position for inbox UI (independent of server / other clients).
class ChatLocalReadCursor {
  ChatLocalReadCursor._();

  static final ChatLocalReadCursor instance = ChatLocalReadCursor._();

  static const _prefsPrefix = 'chat_last_read_message_id_';

  final Map<int, int> _lastReadMessageIdByChat = {};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefsPrefix));

    for (final key in keys) {
      final id = int.tryParse(key.substring(_prefsPrefix.length));
      final value = prefs.getInt(key);
      if (id != null && id > 0 && value != null && value > 0) {
        _lastReadMessageIdByChat[id] = value;
      }
    }

    _loaded = true;
  }

  int lastReadMessageId(int chatId) => _lastReadMessageIdByChat[chatId] ?? 0;

  Future<void> setLastReadMessageId(int chatId, int messageId) async {
    if (chatId <= 0 || messageId <= 0) return;

    await ensureLoaded();

    final previous = _lastReadMessageIdByChat[chatId] ?? 0;
    if (messageId <= previous) return;

    _lastReadMessageIdByChat[chatId] = messageId;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefsPrefix$chatId', messageId);
  }

  /// True when there are peer messages not read on this device.
  bool hasIncomingUnread(
    ChatConversationSummaryModel chat,
    int viewerUserId,
  ) {
    if (viewerUserId <= 0) return false;

    final last = chat.lastMessage;
    final cursor = lastReadMessageId(chat.id);
    final serverUnread = chat.unreadCount;

    if (last != null && !chat.isLastMessageFromViewer(viewerUserId)) {
      if (last.id <= cursor) return false;
      if (serverUnread > 0) return true;
      if (last.isRead) return false;
      return true;
    }

    // Last preview is yours, but peer messages may still be unread above it.
    if (serverUnread > 0) {
      return true;
    }

    return false;
  }

  int displayUnreadCount(
    ChatConversationSummaryModel chat,
    int viewerUserId,
  ) {
    if (!hasIncomingUnread(chat, viewerUserId)) return 0;

    final serverUnread = chat.unreadCount;
    return serverUnread > 0 ? serverUnread : 1;
  }

  /// Show ✓✓ on the list when the peer has read your last outgoing message.
  bool showPeerReadReceiptOnList(
    ChatConversationSummaryModel chat,
    int viewerUserId,
  ) {
    final last = chat.lastMessage;
    if (last == null || viewerUserId <= 0) return false;
    if (!chat.isLastMessageFromViewer(viewerUserId)) return false;

    return last.isRead;
  }

  ChatConversationSummaryModel applyToSummary(
    ChatConversationSummaryModel chat,
    int viewerUserId,
  ) {
    final incomingUnread = hasIncomingUnread(chat, viewerUserId);
    final unread = incomingUnread ? displayUnreadCount(chat, viewerUserId) : 0;
    var result = chat.copyWith(unreadCount: unread);

    final last = result.lastMessage;
    if (last == null) return result;

    // Incoming preview: do not show server "read" while this device still has unread.
    if (incomingUnread && last.isRead) {
      result = result.copyWith(
        lastMessage: ChatLastMessageSummary(
          id: last.id,
          content: last.content,
          senderId: last.senderId,
          isRead: false,
          sentAt: last.sentAt,
        ),
      );
    }

    return result;
  }
}
