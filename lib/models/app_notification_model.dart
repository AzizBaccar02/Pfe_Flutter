// lib/models/app_notification_model.dart

import '../utils/agent_identity_privacy.dart';

enum AppNotificationType {
  message,
  match,
  offer,
  agentLikedOffer,
  clientRejected,
  agentRated,
  system,
}

enum NotificationTapAction {
  none,
  reviewAgentInterest,
  agentMatchAccepted,
  agentMatchRejected,
  openChat,
}

class AppNotificationModel {
  final int id;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final NotificationTapAction tapAction;
  final int? offerId;
  final int? agentId;
  final int? clientId;
  final int? chatId;
  final int? interactionId;
  final String? agentName;
  final String? agentEmail;
  final String? clientName;
  final String? offerTitle;
  final String? avatarUrl;
  final int? ratingStars;
  final String? ratingComment;

  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.tapAction = NotificationTapAction.none,
    this.offerId,
    this.agentId,
    this.clientId,
    this.chatId,
    this.interactionId,
    this.agentName,
    this.agentEmail,
    this.clientName,
    this.offerTitle,
    this.avatarUrl,
    this.ratingStars,
    this.ratingComment,
  });

  bool get isActionable => tapAction != NotificationTapAction.none;

  bool get isAgentRatingNotification => type == AppNotificationType.agentRated;

  bool get isAgentInterestNotification =>
      tapAction == NotificationTapAction.reviewAgentInterest ||
      type == AppNotificationType.agentLikedOffer;

  bool get isClientMatchNotification =>
      tapAction == NotificationTapAction.agentMatchAccepted ||
      type == AppNotificationType.match;

  bool get canRespondInline =>
      isAgentInterestNotification && offerId != null && agentId != null;

  String get actorDisplayName {
    if (isAgentInterestNotification) {
      return AgentIdentityPrivacy.publicLabel(resolvedAgentName);
    }
    if (isAgentRatingNotification) {
      if (clientName?.trim().isNotEmpty == true) return clientName!.trim();
      final fromTitle = _parseNameBeforeVerb(title);
      if (_isUsablePersonName(fromTitle)) return fromTitle!;
      return 'A client';
    }
    if (clientName?.trim().isNotEmpty == true) return clientName!;
    return resolvedAgentName ?? 'Someone';
  }

  /// Best agent name from data, title, or email (excludes generic placeholders).
  String? get resolvedAgentName {
    if (_isUsablePersonName(agentName)) return agentName!.trim();

    final fromTitle = _parseNameBeforeVerb(title);
    if (_isUsablePersonName(fromTitle)) return fromTitle;

    final fromEmail = _nameFromEmail(agentEmail);
    if (_isUsablePersonName(fromEmail)) return fromEmail;

    return null;
  }

  String inboxActionLabel({String? reactionStatus}) {
    if (isAgentInterestNotification) {
      final offer = resolvedOfferTitle;
      final normalized = reactionStatus?.trim().toUpperCase() ?? '';

      if (normalized == 'ACCEPTED') {
        if (offer != null && offer.isNotEmpty) {
          return 'is your matched agent on "$offer".';
        }
        return 'is your matched agent.';
      }

      if (normalized == 'REJECTED') {
        if (offer != null && offer.isNotEmpty) {
          return 'was declined for "$offer".';
        }
        return 'was declined for your offer.';
      }

      if (offer != null && offer.isNotEmpty) {
        return 'liked your offer "$offer".';
      }
      return 'liked your offer.';
    }

    if (isAgentRatingNotification) {
      final offer = resolvedOfferTitle;
      final stars = ratingStars ?? 0;
      final starLabel = stars > 0 ? '$stars★' : 'a rating';
      if (offer != null && offer.isNotEmpty) {
        return 'left you $starLabel for "$offer".';
      }
      return 'left you $starLabel.';
    }

    return actionLabel;
  }

  String get actionLabel {
    if (isAgentInterestNotification) {
      final offer = resolvedOfferTitle;
      if (offer != null && offer.isNotEmpty) {
        return 'liked your offer "$offer".';
      }
      return 'liked your offer.';
    }

    switch (type) {
      case AppNotificationType.match:
        final offer = offerTitle?.trim();
        if (offer != null && offer.isNotEmpty) {
          return 'accepted your interest on "$offer".';
        }
        return 'accepted your interest.';
      case AppNotificationType.clientRejected:
        final offer = offerTitle?.trim();
        if (offer != null && offer.isNotEmpty) {
          return 'declined your interest on "$offer".';
        }
        return 'declined your interest.';
      case AppNotificationType.message:
        return 'sent you a message.';
      case AppNotificationType.offer:
        return body.trim().isNotEmpty ? body.trim() : 'updated an offer.';
      case AppNotificationType.agentLikedOffer:
        return 'liked your offer.';
      case AppNotificationType.agentRated:
        final stars = ratingStars ?? 0;
        final starLabel = stars > 0 ? '$stars★' : 'a new rating';
        final offer = offerTitle?.trim();
        if (offer != null && offer.isNotEmpty) {
          return 'rated you $starLabel for "$offer".';
        }
        return 'rated you $starLabel.';
      case AppNotificationType.system:
        return body.trim().isNotEmpty ? body.trim() : title.trim();
    }
  }

  /// Offer title from payload or parsed from notification text.
  String? get resolvedOfferTitle {
    final fromField = offerTitle?.trim();
    if (fromField != null && fromField.isNotEmpty) return fromField;
    return _parseOfferFromBody(body) ?? _parseOfferFromBody(title);
  }

  static bool _isUsablePersonName(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    const blocked = {'agent', 'someone', 'user', 'client', 'unknown'};
    return !blocked.contains(trimmed.toLowerCase());
  }

  static String? _parseNameBeforeVerb(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final match = RegExp(
      r'^(.+?)\s+(is interested|has liked|liked|accepted|declined|is)\b',
      caseSensitive: false,
    ).firstMatch(text);

    final candidate = match?.group(1)?.trim();
    return _isUsablePersonName(candidate) ? candidate : null;
  }

  static String? _parseOfferFromBody(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final someone = RegExp(
      r'^someone\s+liked\s+(.+?)\.?$',
      caseSensitive: false,
    ).firstMatch(text);
    if (someone != null) return someone.group(1)?.trim();

    final match = RegExp(
      r'liked\s+(?:your\s+offer\s+)?["\u201c]?([^"\u201d]+)["\u201d]?\.?$',
      caseSensitive: false,
    ).firstMatch(text);

    return match?.group(1)?.trim();
  }

  static String? _nameFromEmail(String? email) {
    if (email == null || !email.contains('@')) return null;

    final local = email.split('@').first.trim();
    if (local.isEmpty) return null;

    return local
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String get avatarInitials {
    if (isAgentInterestNotification) {
      return AgentIdentityPrivacy.initials(resolvedAgentName);
    }

    final parts = actorDisplayName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);

    final offerId       = _pi(data['offer_id'])       ?? _pi(data['offerId']);
    final agentId       = _pi(data['agent_id'])       ?? _pi(data['agentId']);
    final clientId      = _pi(data['client_id'])      ?? _pi(data['clientId']);
    final chatId        = _pi(data['chat_id'])        ?? _pi(data['chatId']);
    final interactionId = _pi(data['interaction_id']) ??
        _pi(data['interactionId']) ??
        _pi(data['reaction_id']) ??
        _pi(data['reactionId']);
    final agentName     = _str(data['agent_name'])    ?? _str(data['agentName']);
    final agentEmail    = _str(data['agent_email'])   ?? _str(data['agentEmail']);
    final clientName    = _str(data['client_name'])   ?? _str(data['clientName']);
    final offerTitle    = _str(data['offer_title'])   ?? _str(data['offerTitle']);
    final avatarUrl     = _str(data['avatar_url'])    ?? _str(data['avatarUrl'])
                       ?? _str(data['agent_photo'])   ?? _str(data['client_photo']);
    final ratingStars   = _pi(data['stars']) ?? _pi(data['rating_stars']);
    final ratingComment = _str(data['comment']) ?? _str(data['rating_comment']);

    final action    = _str(data['action'])?.toLowerCase() ?? '';
    final type      = _resolveType(json['type'], action);
    final tapAction = _resolveTapAction(action, type);

    return AppNotificationModel(
      id:             _pi(json['id']) ?? 0,
      type:           type,
      title:          json['title']?.toString() ?? '',
      body:           json['body']?.toString()  ?? '',
      createdAt:      _parseDate(json['created_at']) ?? _parseDate(json['createdAt']) ?? DateTime.now(),
      isRead:         _parseBool(json['isRead']) ?? _parseBool(json['is_read']) ?? false,
      tapAction:      tapAction,
      offerId:        offerId,
      agentId:        agentId,
      clientId:       clientId,
      chatId:         chatId,
      interactionId:  interactionId,
      agentName:      agentName,
      agentEmail:     agentEmail,
      clientName:     clientName,
      offerTitle:     offerTitle,
      avatarUrl:      avatarUrl,
      ratingStars:    ratingStars,
      ratingComment:  ratingComment,
    );
  }

  AppNotificationModel copyWith({
    int? id,
    AppNotificationType? type,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    NotificationTapAction? tapAction,
    int? offerId,
    int? agentId,
    int? clientId,
    int? chatId,
    int? interactionId,
    String? agentName,
    String? agentEmail,
    String? clientName,
    String? offerTitle,
    String? avatarUrl,
    int? ratingStars,
    String? ratingComment,
  }) {
    return AppNotificationModel(
      id:             id            ?? this.id,
      type:           type          ?? this.type,
      title:          title         ?? this.title,
      body:           body          ?? this.body,
      createdAt:      createdAt     ?? this.createdAt,
      isRead:         isRead        ?? this.isRead,
      tapAction:      tapAction     ?? this.tapAction,
      offerId:        offerId       ?? this.offerId,
      agentId:        agentId       ?? this.agentId,
      clientId:       clientId      ?? this.clientId,
      chatId:         chatId        ?? this.chatId,
      interactionId:  interactionId ?? this.interactionId,
      agentName:      agentName     ?? this.agentName,
      agentEmail:     agentEmail    ?? this.agentEmail,
      clientName:     clientName    ?? this.clientName,
      offerTitle:     offerTitle    ?? this.offerTitle,
      avatarUrl:      avatarUrl     ?? this.avatarUrl,
      ratingStars:    ratingStars   ?? this.ratingStars,
      ratingComment:  ratingComment ?? this.ratingComment,
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return const {};
}

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

int? _pi(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

bool? _parseBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  final s = v.toString().trim().toLowerCase();
  if (s == 'true'  || s == '1' || s == 'yes') return true;
  if (s == 'false' || s == '0' || s == 'no')  return false;
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

AppNotificationType _resolveType(dynamic rawType, String action) {
  switch (action) {
    case 'agent_liked_offer':
    case 'review_agent_interest':
      return AppNotificationType.agentLikedOffer;
    case 'client_accepted':
      return AppNotificationType.match;
    case 'client_rejected':
      return AppNotificationType.clientRejected;
    case 'open_chat':
      return AppNotificationType.message;
    case 'agent_received_rating':
    case 'client_rated_agent':
      return AppNotificationType.agentRated;
  }
  switch (rawType?.toString().trim().toUpperCase() ?? '') {
    case 'NEW_MESSAGE':
    case 'MESSAGE':
      return AppNotificationType.message;
    case 'MATCH_CREATED':
    case 'MATCH':
      return AppNotificationType.match;
    case 'AGENT_LIKED_OFFER':
      return AppNotificationType.agentLikedOffer;
    case 'CLIENT_REJECTED':
      return AppNotificationType.clientRejected;
    case 'PROPOSAL_STATUS':
    case 'OFFER':
      return AppNotificationType.offer;
    case 'AGENT_RATED':
    case 'AGENT_RATING':
    case 'CLIENT_RATED_AGENT':
      return AppNotificationType.agentRated;
    default:
      return AppNotificationType.system;
  }
}

NotificationTapAction _resolveTapAction(String action, AppNotificationType type) {
  switch (action) {
    case 'agent_liked_offer':
    case 'review_agent_interest':
      return NotificationTapAction.reviewAgentInterest;
    case 'client_accepted':
    case 'agent_match_accepted':
      return NotificationTapAction.agentMatchAccepted;
    case 'client_rejected':
    case 'agent_match_rejected':
      return NotificationTapAction.agentMatchRejected;
    case 'open_chat':
      return NotificationTapAction.openChat;
    case 'agent_received_rating':
    case 'client_rated_agent':
      return NotificationTapAction.none;
  }
  switch (type) {
    case AppNotificationType.agentLikedOffer:
      return NotificationTapAction.reviewAgentInterest;
    case AppNotificationType.match:
      return NotificationTapAction.agentMatchAccepted;
    case AppNotificationType.clientRejected:
      return NotificationTapAction.agentMatchRejected;
    case AppNotificationType.agentRated:
      return NotificationTapAction.none;
    default:
      return NotificationTapAction.none;
  }
}