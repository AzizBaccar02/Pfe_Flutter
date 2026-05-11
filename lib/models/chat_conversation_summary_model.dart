class ChatUserSummary {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;

  const ChatUserSummary({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory ChatUserSummary.fromJson(Map<String, dynamic> json) {
    return ChatUserSummary(
      id: _parseInt(json['id']) ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }

  String get fullName {
    final name = '$firstName $lastName'.trim();

    if (name.isNotEmpty) return name;
    if (username.isNotEmpty) return username;
    if (email.isNotEmpty) return email;

    return 'Unknown user';
  }

  String get initials {
    final cleanName = fullName.trim();

    if (cleanName.isEmpty || cleanName == 'Unknown user') return '?';

    final parts = cleanName.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class ChatReactionSummary {
  final int id;
  final String status;
  final bool react;
  final String message;
  final double? proposedPrice;
  final DateTime? createdAt;
  final int agentId;
  final int offreId;

  const ChatReactionSummary({
    required this.id,
    required this.status,
    required this.react,
    required this.message,
    required this.proposedPrice,
    required this.createdAt,
    required this.agentId,
    required this.offreId,
  });

  factory ChatReactionSummary.fromJson(Map<String, dynamic> json) {
    return ChatReactionSummary(
      id: _parseInt(json['id']) ?? 0,
      status: json['status']?.toString() ?? '',
      react: _parseBool(json['react']) ?? false,
      message: json['message']?.toString() ?? '',
      proposedPrice: _parseDouble(json['proposedPrice']),
      createdAt: _parseDate(json['createdAt']),
      agentId: _parseInt(json['agentId']) ?? 0,
      offreId: _parseInt(json['offreId']) ?? 0,
    );
  }
}

class ChatOfferSummary {
  final int id;
  final String title;
  final String description;
  final double budget;
  final String status;
  final String category;
  final String city;
  final String address;
  final String postalCode;

  const ChatOfferSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.budget,
    required this.status,
    required this.category,
    required this.city,
    required this.address,
    required this.postalCode,
  });

  factory ChatOfferSummary.fromJson(Map<String, dynamic> json) {
    return ChatOfferSummary(
      id: _parseInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      budget: _parseDouble(json['budget']) ?? 0,
      status: json['status']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
    );
  }
}

class ChatLastMessageSummary {
  final int id;
  final String content;
  final int senderId;
  final bool isRead;
  final DateTime? sentAt;

  const ChatLastMessageSummary({
    required this.id,
    required this.content,
    required this.senderId,
    required this.isRead,
    required this.sentAt,
  });

  factory ChatLastMessageSummary.fromJson(Map<String, dynamic> json) {
    return ChatLastMessageSummary(
      id: _parseInt(json['id']) ?? 0,
      content: json['content']?.toString() ?? '',
      senderId: _parseInt(json['senderId']) ?? 0,
      isRead: _parseBool(json['isRead']) ?? false,
      sentAt: _parseDate(json['sentAt']),
    );
  }
}

class ChatConversationSummaryModel {
  final int id;
  final String status;
  final ChatUserSummary? client;
  final ChatUserSummary? agent;
  final ChatUserSummary? otherUser;
  final ChatReactionSummary? offreReaction;
  final ChatOfferSummary? offer;
  final ChatLastMessageSummary? lastMessage;
  final int unreadCount;

  const ChatConversationSummaryModel({
    required this.id,
    required this.status,
    required this.client,
    required this.agent,
    required this.otherUser,
    required this.offreReaction,
    required this.offer,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory ChatConversationSummaryModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationSummaryModel(
      id: _parseInt(json['id']) ?? 0,
      status: json['status']?.toString() ?? '',
      client: _parseNestedObject(json['client'], ChatUserSummary.fromJson),
      agent: _parseNestedObject(json['agent'], ChatUserSummary.fromJson),
      otherUser: _parseNestedObject(json['otherUser'], ChatUserSummary.fromJson),
      offreReaction: _parseNestedObject(
        json['offreReaction'],
        ChatReactionSummary.fromJson,
      ),
      offer: _parseNestedObject(json['offer'], ChatOfferSummary.fromJson),
      lastMessage: _parseNestedObject(
        json['lastMessage'],
        ChatLastMessageSummary.fromJson,
      ),
      unreadCount: _parseInt(json['unreadCount']) ?? 0,
    );
  }

  String get displayName {
    return otherUser?.fullName ?? 'Unknown user';
  }

  String get displayInitials {
    return otherUser?.initials ?? '?';
  }

  String get offerTitle {
    final title = offer?.title.trim() ?? '';
    return title.isNotEmpty ? title : 'JobMatch conversation';
  }

  String get previewText {
    final content = lastMessage?.content.trim() ?? '';
    return content.isNotEmpty ? content : 'Start the conversation now.';
  }

  DateTime? get lastActivityDate {
    return lastMessage?.sentAt ?? offreReaction?.createdAt;
  }
}

class ChatListResponse {
  final String currentUserRole;
  final int count;
  final List<ChatConversationSummaryModel> chats;

  const ChatListResponse({
    required this.currentUserRole,
    required this.count,
    required this.chats,
  });

  factory ChatListResponse.fromJson(Map<String, dynamic> json) {
    final rawChats = json['chats'];

    return ChatListResponse(
      currentUserRole: json['currentUserRole']?.toString() ?? '',
      count: _parseInt(json['count']) ?? 0,
      chats: rawChats is List
          ? rawChats
              .whereType<Map>()
              .map(
                (item) => ChatConversationSummaryModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : [],
    );
  }
}

T? _parseNestedObject<T>(
  dynamic value,
  T Function(Map<String, dynamic>) builder,
) {
  if (value is Map<String, dynamic>) return builder(value);
  if (value is Map) return builder(Map<String, dynamic>.from(value));
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
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