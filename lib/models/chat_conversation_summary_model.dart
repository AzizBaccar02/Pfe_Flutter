class ChatUserSummary {
  final int id;
  /// Django `User.id` when different from [id] (e.g. profile row id vs user id).
  final int? userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  /// Raw path or URL from API; resolve to a full URL in the UI layer when needed.
  final String phone;
  final String photoUrl;
  final bool isOnline;

  const ChatUserSummary({
    required this.id,
    this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.phone,
    required this.photoUrl,
    this.isOnline = false,
  });

  factory ChatUserSummary.fromJson(Map<String, dynamic> json) {
    String pickPhone() {
      const keys = [
        'phone',
        'phoneNumber',
        'phone_number',
        'contactNumber',
        'contact_number',
        'mobile',
        'mobile_phone',
        'mobilePhone',
        'telephone',
        'cell',
        'tel',
        'gsm',
        'whatsapp',
      ];
      for (final map in _userJsonMapLayers(json)) {
        for (final key in keys) {
          final s = map[key]?.toString().trim() ?? '';
          if (s.isNotEmpty) return s;
        }
      }
      return '';
    }

    String pickPhoto() {
      const keys = [
        'photo',
        'photoUrl',
        'photo_url',
        'avatar',
        'profilePhoto',
        'profile_photo',
        'image',
        'picture',
      ];
      for (final map in _userJsonMapLayers(json)) {
        for (final key in keys) {
          final s = map[key]?.toString().trim() ?? '';
          if (s.isNotEmpty) return s;
        }
      }
      return '';
    }

    return ChatUserSummary(
      id: _parseInt(json['id']) ?? 0,
      userId: _extractLinkedUserId(json),
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      phone: pickPhone(),
      photoUrl: pickPhoto(),
      isOnline: _parseBool(json['isOnline']) ??
          _parseBool(json['is_online']) ??
          _pickOnlineFromLayers(json) ??
          false,
    );
  }

  static bool? _pickOnlineFromNestedMap(Map<String, dynamic> map) {
    const directKeys = [
      'isOnline',
      'is_online',
      'online',
      'isConnected',
      'is_connected',
      'connected',
      'isActive',
      'is_active',
    ];
    for (final key in directKeys) {
      if (!map.containsKey(key)) continue;
      final b = _parseBool(map[key]);
      if (b != null) return b;
    }

    final pres = map['presence'];
    if (pres is Map) {
      final m = Map<String, dynamic>.from(pres);
      for (final key in const ['online', 'isOnline', 'is_online']) {
        if (!m.containsKey(key)) continue;
        final b = _parseBool(m[key]);
        if (b != null) return b;
      }
      final status = m['status']?.toString().trim().toLowerCase();
      if (status != null && status.isNotEmpty) {
        if (status == 'online' || status == 'away' || status == 'busy') {
          return true;
        }
        if (status == 'offline' ||
            status == 'invisible' ||
            status == 'disconnected') {
          return false;
        }
      }
    }
    return null;
  }

  static bool? _pickOnlineFromLayers(Map<String, dynamic> json) {
    for (final map in _userJsonMapLayers(json)) {
      final b = _pickOnlineFromNestedMap(map);
      if (b != null) return b;
    }
    return null;
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

  ChatUserSummary copyWith({
    int? id,
    int? userId,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? phone,
    String? photoUrl,
    bool? isOnline,
  }) {
    return ChatUserSummary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// Merges root user JSON with common nested profile blobs (Django / DRF shapes).
List<Map<String, dynamic>> _userJsonMapLayers(Map<String, dynamic> json) {
  final layers = <Map<String, dynamic>>[json];

  void addLayer(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      layers.add(raw);
    } else if (raw is Map) {
      layers.add(Map<String, dynamic>.from(raw));
    }
  }

  addLayer(json['profile']);
  addLayer(json['user']);
  addLayer(json['clientProfile']);
  addLayer(json['agentProfile']);
  addLayer(json['client_profile']);
  addLayer(json['agent_profile']);

  return layers;
}

int? _extractLinkedUserId(Map<String, dynamic> json) {
  final direct = _parseInt(json['userId']) ?? _parseInt(json['user_id']);
  if (direct != null && direct > 0) return direct;
  final u = json['user'];
  if (u is Map) {
    final id = _parseInt(u['id']);
    if (id != null && id > 0) return id;
  }
  return null;
}

bool _chatPersonMatches(ChatUserSummary? person, int ref) {
  if (person == null || ref == 0) return false;
  final uid = person.userId;
  if (uid != null && uid > 0 && uid == ref) return true;
  return person.id == ref;
}

int _peerRefFromOther(ChatUserSummary? otherUser) {
  if (otherUser == null) return 0;
  final uid = otherUser.userId;
  if (uid != null && uid > 0) return uid;
  return otherUser.id;
}

String _readFlatPeerPhone(Map<String, dynamic> json) {
  const keys = [
    'peerPhone',
    'peer_phone',
    'otherUserPhone',
    'other_user_phone',
    'counterpartPhone',
    'counterpart_phone',
  ];
  for (final k in keys) {
    final s = json[k]?.toString().trim() ?? '';
    if (s.isNotEmpty) return s;
  }
  return '';
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
  /// Phone at chat root (some APIs expose it here instead of nested user).
  final String flatPeerPhone;

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
    required this.flatPeerPhone,
  });

  factory ChatConversationSummaryModel.fromJson(Map<String, dynamic> json) {
    final client =
        _parseNestedObject(json['client'], ChatUserSummary.fromJson);
    final agent =
        _parseNestedObject(json['agent'], ChatUserSummary.fromJson);
    var otherUser =
        _parseNestedObject(json['otherUser'], ChatUserSummary.fromJson) ??
            _parseNestedObject(json['other_user'], ChatUserSummary.fromJson);

    final rootPeerOnline = _parseBool(json['peerOnline']) ??
        _parseBool(json['peer_is_online']) ??
        _parseBool(json['otherUserOnline']) ??
        _parseBool(json['other_user_online']) ??
        _parseBool(json['counterparty_online']) ??
        _parseBool(json['counterpartyOnline']);

    if (rootPeerOnline == true && otherUser != null && !otherUser.isOnline) {
      otherUser = otherUser.copyWith(isOnline: true);
    }

    return ChatConversationSummaryModel(
      id: _parseInt(json['id']) ?? 0,
      status: json['status']?.toString() ?? '',
      client: client,
      agent: agent,
      otherUser: otherUser,
      offreReaction: _parseNestedObject(
        json['offreReaction'],
        ChatReactionSummary.fromJson,
      ),
      offer: _parseNestedObject(json['offer'], ChatOfferSummary.fromJson),
      lastMessage: _parseNestedObject(
        json['lastMessage'],
        ChatLastMessageSummary.fromJson,
      ),
      unreadCount: _parseInt(json['unreadCount']) ??
          _parseInt(json['unread_count']) ??
          0,
      flatPeerPhone: _readFlatPeerPhone(json),
    );
  }

  String get displayName {
    return otherUser?.fullName ?? 'Unknown user';
  }

  String get displayInitials {
    return otherUser?.initials ?? '?';
  }

  /// True when the counterparty appears online in API payloads.
  ///
  /// Merges flags from [otherUser] and matching [client]/[agent] rows (some APIs
  /// only set `is_online` on one of them). When [otherUser] is missing, uses
  /// [viewerUserId] to pick the non-viewer participant.
  bool peerOnlineForViewer(int viewerUserId) {
    bool uOn(ChatUserSummary? u) => u?.isOnline ?? false;

    ChatUserSummary? peer;
    if (otherUser != null) {
      peer = otherUser;
    } else if (viewerUserId > 0) {
      if (_chatPersonMatches(client, viewerUserId) ||
          (client?.id ?? 0) == viewerUserId) {
        peer = agent;
      } else if (_chatPersonMatches(agent, viewerUserId) ||
          (agent?.id ?? 0) == viewerUserId) {
        peer = client;
      }
    }

    if (peer == null) return false;

    final ref = peer.userId ?? peer.id;
    var online = uOn(peer);
    if (ref > 0) {
      if (client != null && _chatPersonMatches(client, ref)) {
        online = online || uOn(client);
      }
      if (agent != null && _chatPersonMatches(agent, ref)) {
        online = online || uOn(agent);
      }
    }
    return online;
  }

  /// Best-effort when the signed-in user id is unknown (prefers [otherUser]).
  bool get isPeerOnline => peerOnlineForViewer(0);

  /// Whether [lastMessage] was sent by the signed-in user (matches profile or user id).
  bool isLastMessageFromViewer(int viewerUserId) {
    final last = lastMessage;
    if (last == null || viewerUserId <= 0) return false;

    if (last.senderId == viewerUserId) return true;

    if (_chatPersonMatches(client, viewerUserId)) {
      final c = client!;
      if (last.senderId == c.id) return true;
      final uid = c.userId;
      if (uid != null && uid > 0 && last.senderId == uid) return true;
    }

    if (_chatPersonMatches(agent, viewerUserId)) {
      final a = agent!;
      if (last.senderId == a.id) return true;
      final uid = a.userId;
      if (uid != null && uid > 0 && last.senderId == uid) return true;
    }

    return false;
  }

  /// True when the list should show an unread indicator for this viewer.
  bool hasUnreadIncomingForViewer(int viewerUserId) {
    return effectiveUnreadCountForViewer(viewerUserId) > 0;
  }

  int effectiveUnreadCountForViewer(int viewerUserId) {
    // Server unread count is the source of truth for how many are unopened.
    if (unreadCount > 0) return unreadCount;

    final last = lastMessage;
    if (last == null || viewerUserId <= 0) return 0;
    if (isLastMessageFromViewer(viewerUserId)) return 0;
    if (last.isRead) return 0;
    return 1;
  }

  ChatConversationSummaryModel copyWith({
    ChatUserSummary? client,
    ChatUserSummary? agent,
    ChatUserSummary? otherUser,
    ChatLastMessageSummary? lastMessage,
    int? unreadCount,
  }) {
    return ChatConversationSummaryModel(
      id: id,
      status: status,
      client: client ?? this.client,
      agent: agent ?? this.agent,
      otherUser: otherUser ?? this.otherUser,
      offreReaction: offreReaction,
      offer: offer,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      flatPeerPhone: flatPeerPhone,
    );
  }

  /// Applies [isOnline] to whichever of [client]/[agent]/[otherUser] matches [userId]
  /// (matches [ChatUserSummary.id] or [ChatUserSummary.userId]).
  ChatConversationSummaryModel withUserOnlineState({
    required int userId,
    required bool isOnline,
  }) {
    if (userId <= 0) return this;

    ChatUserSummary? patch(ChatUserSummary? u) {
      if (u == null) return null;
      if (u.id == userId || u.userId == userId) {
        return u.copyWith(isOnline: isOnline);
      }
      return u;
    }

    return copyWith(
      client: patch(client),
      agent: patch(agent),
      otherUser: patch(otherUser),
    );
  }

  /// Phone for the person you are chatting with; falls back to [client]/[agent].
  /// Pass [viewerUserId] (signed-in user) when both parties have a phone so the
  /// counterparty's number is chosen.
  String resolvePeerPhone({int viewerUserId = 0}) {
    final fromOther = otherUser?.phone.trim() ?? '';
    if (fromOther.isNotEmpty) return fromOther;

    if (flatPeerPhone.trim().isNotEmpty) return flatPeerPhone.trim();

    final ref = _peerRefFromOther(otherUser);
    if (ref != 0) {
      if (_chatPersonMatches(client, ref)) {
        final p = client?.phone.trim() ?? '';
        if (p.isNotEmpty) return p;
      }
      if (_chatPersonMatches(agent, ref)) {
        final p = agent?.phone.trim() ?? '';
        if (p.isNotEmpty) return p;
      }
    }

    if (viewerUserId > 0) {
      if (_chatPersonMatches(client, viewerUserId)) {
        final p = agent?.phone.trim() ?? '';
        if (p.isNotEmpty) return p;
      }
      if (_chatPersonMatches(agent, viewerUserId)) {
        final p = client?.phone.trim() ?? '';
        if (p.isNotEmpty) return p;
      }
    }

    final a = agent?.phone.trim() ?? '';
    final c = client?.phone.trim() ?? '';
    if (a.isNotEmpty && c.isEmpty) return a;
    if (c.isNotEmpty && a.isEmpty) return c;
    if (a.isNotEmpty && c.isNotEmpty && viewerUserId > 0) {
      if (client?.id == viewerUserId) return a;
      if (agent?.id == viewerUserId) return c;
      if (_chatPersonMatches(client, viewerUserId)) return a;
      if (_chatPersonMatches(agent, viewerUserId)) return c;
    }
    return '';
  }

  String get peerPhone => resolvePeerPhone();

  /// Profile photo path/URL for the peer; same fallback rules as [resolvePeerPhone].
  String resolvePeerPhotoUrl({int viewerUserId = 0}) {
    final fromOther = otherUser?.photoUrl.trim() ?? '';
    if (fromOther.isNotEmpty) return fromOther;

    final ref = _peerRefFromOther(otherUser);
    if (ref != 0) {
      if (_chatPersonMatches(client, ref)) {
        final p = client?.photoUrl.trim() ?? '';
        if (p.isNotEmpty) return p;
      }
      if (_chatPersonMatches(agent, ref)) {
        final p = agent?.photoUrl.trim() ?? '';
        if (p.isNotEmpty) return p;
      }
    }

    if (viewerUserId > 0) {
      if (_chatPersonMatches(client, viewerUserId)) {
        final p = agent?.photoUrl.trim() ?? '';
        if (p.isNotEmpty) return p;
      }
      if (_chatPersonMatches(agent, viewerUserId)) {
        final p = client?.photoUrl.trim() ?? '';
        if (p.isNotEmpty) return p;
      }
    }

    final ap = agent?.photoUrl.trim() ?? '';
    final cp = client?.photoUrl.trim() ?? '';
    if (ap.isNotEmpty && cp.isEmpty) return ap;
    if (cp.isNotEmpty && ap.isEmpty) return cp;
    if (ap.isNotEmpty && cp.isNotEmpty && viewerUserId > 0) {
      if (client?.id == viewerUserId) return ap;
      if (agent?.id == viewerUserId) return cp;
      if (_chatPersonMatches(client, viewerUserId)) return ap;
      if (_chatPersonMatches(agent, viewerUserId)) return cp;
    }
    return '';
  }

  String get peerPhotoUrl => resolvePeerPhotoUrl();

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