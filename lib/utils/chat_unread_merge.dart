// lib/utils/chat_unread_merge.dart

import '../models/chat_conversation_summary_model.dart';
import '../services/chat_local_read_cursor.dart';

/// Applies device-local read state on top of server chat list payloads.
class ChatUnreadMerge {
  /// Chat ids for which the next merge accepts server [unreadCount] after visit.
  static final Set<int> trustServerUnreadOnce = {};

  static void trustServerUnreadForChat(int chatId) {
    if (chatId > 0) {
      trustServerUnreadOnce.add(chatId);
    }
  }

  static List<ChatConversationSummaryModel> mergeLists({
    required List<ChatConversationSummaryModel> serverChats,
    required List<ChatConversationSummaryModel> previousChats,
    required int viewerUserId,
  }) {
    final previousById = {for (final c in previousChats) c.id: c};

    return serverChats
        .map(
          (server) => mergeChat(
            server: server,
            previous: previousById[server.id],
            viewerUserId: viewerUserId,
          ),
        )
        .toList();
  }

  static ChatConversationSummaryModel mergeChat({
    required ChatConversationSummaryModel server,
    required ChatConversationSummaryModel? previous,
    required int viewerUserId,
  }) {
    trustServerUnreadOnce.remove(server.id);
    return ChatLocalReadCursor.instance.applyToSummary(server, viewerUserId);
  }

  /// Patches a single row after a realtime inbox event.
  static ChatConversationSummaryModel mergeInboxRow({
    required ChatConversationSummaryModel chat,
    required ChatLastMessageSummary? lastMessage,
    required int viewerUserId,
  }) {
    final patched = chat.copyWith(
      lastMessage: lastMessage ?? chat.lastMessage,
    );

    return ChatLocalReadCursor.instance.applyToSummary(patched, viewerUserId);
  }
}
