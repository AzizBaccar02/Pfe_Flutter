// lib/services/chat_active_conversation_tracker.dart

/// Tracks which chat is actively open on this device.
///
/// Used to gate read-all API calls and to avoid clearing local unread when
/// another client (e.g. web) marks the same account's messages as read.
class ChatActiveConversationTracker {
  ChatActiveConversationTracker._();

  static final ChatActiveConversationTracker instance =
      ChatActiveConversationTracker._();

  int? _chatId;
  bool _visible = false;

  void setActive(int? chatId, {required bool visible}) {
    _chatId = chatId;
    _visible = visible;
  }

  bool isViewing(int chatId) =>
      _visible && _chatId != null && _chatId == chatId;
}
