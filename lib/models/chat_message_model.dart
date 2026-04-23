enum ChatSenderType {
  client,
  agent,
}

class ChatMessageModel {
  final int id;
  final int agentId;
  final ChatSenderType sender;
  final String text;
  final DateTime sentAt;
  final bool isRead;

  const ChatMessageModel({
    required this.id,
    required this.agentId,
    required this.sender,
    required this.text,
    required this.sentAt,
    required this.isRead,
  });

  bool get isFromClient => sender == ChatSenderType.client;
  bool get isFromAgent => sender == ChatSenderType.agent;

  ChatMessageModel copyWith({
    int? id,
    int? agentId,
    ChatSenderType? sender,
    String? text,
    DateTime? sentAt,
    bool? isRead,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
    );
  }
}