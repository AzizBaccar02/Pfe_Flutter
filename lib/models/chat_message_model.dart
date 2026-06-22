enum ChatSenderType {
  client,
  agent,
}

class ChatMessageModel {
  final int id;
  final int chatId;
  final int senderId;
  final int agentId;
  final ChatSenderType sender;
  final String text;
  final DateTime sentAt;
  final bool isRead;
  final bool isEdited;

  const ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.agentId,
    required this.sender,
    required this.text,
    required this.sentAt,
    required this.isRead,
    this.isEdited = false,
  });

  bool get isFromClient => sender == ChatSenderType.client;
  bool get isFromAgent => sender == ChatSenderType.agent;

  factory ChatMessageModel.fromJson({
    required Map<String, dynamic> json,
    required int clientId,
    required int agentId,
    int? clientUserId,
    int? agentUserId,
  }) {
    final senderId = _parseSenderId(json);

    return ChatMessageModel(
      id: _parseInt(json['id']) ?? 0,
      chatId: _parseInt(json['chat']) ??
          _parseInt(json['chatId']) ??
          _parseInt(json['chat_id']) ??
          0,
      senderId: senderId,
      agentId: agentId,
      sender: _resolveSenderType(
        senderId: senderId,
        clientId: clientId,
        agentId: agentId,
        clientUserId: clientUserId,
        agentUserId: agentUserId,
      ),
      text: json['content']?.toString() ?? json['text']?.toString() ?? '',
      sentAt: _parseDate(json['sentAt']) ??
          _parseDate(json['sent_at']) ??
          DateTime.now(),
      isRead: _parseBool(json['isRead']) ??
          _parseBool(json['is_read']) ??
          _parseBool(json['read']) ??
          _parseBool(json['read_by_peer']) ??
          _parseBool(json['readByPeer']) ??
          false,
      isEdited: _parseBool(json['isEdited']) ??
          _parseBool(json['is_edited']) ??
          false,
    );
  }

  ChatMessageModel copyWith({
    int? id,
    int? chatId,
    int? senderId,
    int? agentId,
    ChatSenderType? sender,
    String? text,
    DateTime? sentAt,
    bool? isRead,
    bool? isEdited,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      agentId: agentId ?? this.agentId,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  static ChatMessageModel temporary({
    required int chatId,
    required int senderId,
    required int clientId,
    required int agentId,
    required String text,
    int? clientUserId,
    int? agentUserId,
  }) {
    final tempId = -DateTime.now().microsecondsSinceEpoch;

    return ChatMessageModel(
      id: tempId,
      chatId: chatId,
      senderId: senderId,
      agentId: agentId,
      sender: _resolveSenderType(
        senderId: senderId,
        clientId: clientId,
        agentId: agentId,
        clientUserId: clientUserId,
        agentUserId: agentUserId,
      ),
      text: text,
      sentAt: DateTime.now(),
      isRead: false,
    );
  }
}

ChatSenderType _resolveSenderType({
  required int senderId,
  required int clientId,
  required int agentId,
  int? clientUserId,
  int? agentUserId,
}) {
  if (senderId <= 0) return ChatSenderType.agent;

  if (clientId > 0 && senderId == clientId) {
    return ChatSenderType.client;
  }

  final resolvedClientUserId = clientUserId ?? 0;
  if (resolvedClientUserId > 0 && senderId == resolvedClientUserId) {
    return ChatSenderType.client;
  }

  if (agentId > 0 && senderId == agentId) {
    return ChatSenderType.agent;
  }

  final resolvedAgentUserId = agentUserId ?? 0;
  if (resolvedAgentUserId > 0 && senderId == resolvedAgentUserId) {
    return ChatSenderType.agent;
  }

  return ChatSenderType.agent;
}

int _parseSenderId(Map<String, dynamic> json) {
  final sender = json['sender'];

  if (sender is Map) {
    return _parseInt(sender['id']) ?? 0;
  }

  return _parseInt(sender) ??
      _parseInt(json['senderId']) ??
      _parseInt(json['sender_id']) ??
      _parseInt(json['sender_id_id']) ??
      0;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;

  final normalized = value.toString().trim().toLowerCase();

  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }

  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }

  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}