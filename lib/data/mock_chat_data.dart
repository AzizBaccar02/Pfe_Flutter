import '../models/chat_message_model.dart';

class MockChatData {
  static final List<ChatMessageModel> _messages = [
    ChatMessageModel(
      id: 1,
      agentId: 1,
      sender: ChatSenderType.agent,
      text: 'Hi Aziz, I can handle the kitchen leak today.',
      sentAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 10)),
      isRead: true,
    ),
    ChatMessageModel(
      id: 2,
      agentId: 1,
      sender: ChatSenderType.client,
      text: 'Perfect. Are you available this afternoon?',
      sentAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 2)),
      isRead: true,
    ),
    ChatMessageModel(
      id: 3,
      agentId: 1,
      sender: ChatSenderType.agent,
      text: 'Yes, around 4 PM works for me.',
      sentAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 55)),
      isRead: true,
    ),
    ChatMessageModel(
      id: 4,
      agentId: 1,
      sender: ChatSenderType.agent,
      text: 'I already prepared the materials needed.',
      sentAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 49)),
      isRead: false,
    ),
    ChatMessageModel(
      id: 5,
      agentId: 2,
      sender: ChatSenderType.agent,
      text: 'Hello, I saw your electrical issue offer.',
      sentAt: DateTime.now().subtract(const Duration(minutes: 42)),
      isRead: false,
    ),
    ChatMessageModel(
      id: 6,
      agentId: 2,
      sender: ChatSenderType.agent,
      text: 'I can come by this evening if needed.',
      sentAt: DateTime.now().subtract(const Duration(minutes: 35)),
      isRead: false,
    ),
  ];

  static List<ChatMessageModel> get allMessages =>
      List<ChatMessageModel>.from(_messages);

  static List<ChatMessageModel> getMessagesForAgent(int agentId) {
    final items = _messages.where((message) => message.agentId == agentId).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return items;
  }

  static ChatMessageModel? getLastMessageForAgent(int agentId) {
    final items = getMessagesForAgent(agentId);
    if (items.isEmpty) return null;
    return items.last;
  }

  static int getUnreadCountForAgent(int agentId) {
    return _messages
        .where(
          (message) =>
              message.agentId == agentId &&
              message.isFromAgent &&
              !message.isRead,
        )
        .length;
  }

  static bool hasConversation(int agentId) {
    return _messages.any((message) => message.agentId == agentId);
  }

  static void markConversationAsRead(int agentId) {
    for (var i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      if (message.agentId == agentId && message.isFromAgent && !message.isRead) {
        _messages[i] = message.copyWith(isRead: true);
      }
    }
  }

  static void sendClientMessage({
    required int agentId,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _messages.add(
      ChatMessageModel(
        id: DateTime.now().microsecondsSinceEpoch,
        agentId: agentId,
        sender: ChatSenderType.client,
        text: trimmed,
        sentAt: DateTime.now(),
        isRead: true,
      ),
    );
  }

  static void sendAgentAutoReply({
    required int agentId,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _messages.add(
      ChatMessageModel(
        id: DateTime.now().microsecondsSinceEpoch + 1,
        agentId: agentId,
        sender: ChatSenderType.agent,
        text: trimmed,
        sentAt: DateTime.now(),
        isRead: false,
      ),
    );
  }
}