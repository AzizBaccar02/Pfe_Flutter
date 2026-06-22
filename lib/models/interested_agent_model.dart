import '../utils/agent_identity_privacy.dart';
import '../utils/media_url_resolver.dart';
import 'agent_profile_model.dart';
import 'app_notification_model.dart';
import 'offer_interaction_model.dart';

class InterestedAgentModel {
  final int id; // agent id
  final int reactionId;

  final String name;
  final String jobTitle;
  final String city;
  final double rating;
  final int completedJobs;
  /// Agent profile photo (small avatar on the card).
  final String imageUrl;

  /// Primary cover image for the liked offer.
  final String offerImageUrl;

  final int offerId;
  final String offerTitle;

  final String message;
  final String proposedPrice;
  final String status;
  final DateTime? createdAt;
  final bool hasRated;

  const InterestedAgentModel({
    required this.id,
    this.reactionId = 0,
    required this.name,
    required this.jobTitle,
    required this.city,
    required this.rating,
    required this.completedJobs,
    required this.imageUrl,
    this.offerImageUrl = '',
    required this.offerId,
    required this.offerTitle,
    this.message = '',
    this.proposedPrice = '',
    this.status = 'PENDING',
    this.createdAt,
    this.hasRated = false,
  });

  /// Builds a pending card from a live notification (WebSocket push).
  factory InterestedAgentModel.fromNotification(AppNotificationModel notification) {
    return InterestedAgentModel(
      id: notification.agentId ?? 0,
      reactionId: notification.interactionId ?? 0,
      name: notification.resolvedAgentName ?? notification.actorDisplayName,
      jobTitle: 'Interested agent',
      city: '',
      rating: 0,
      completedJobs: 0,
      imageUrl: '',
      offerImageUrl: '',
      offerId: notification.offerId ?? 0,
      offerTitle: notification.resolvedOfferTitle ?? '',
      status: 'PENDING',
      createdAt: notification.createdAt,
    );
  }

  factory InterestedAgentModel.fromInteraction(OfferInteractionModel interaction) {
    return InterestedAgentModel(
      id: interaction.agentId,
      reactionId: interaction.id,
      name: interaction.agentName ?? interaction.agentEmail ?? 'Agent',
      jobTitle: interaction.agentSkills?.trim().isNotEmpty == true
          ? interaction.agentSkills!.trim()
          : 'Interested agent',
      city: interaction.agentCity ?? '',
      rating: 0,
      completedJobs: 0,
      imageUrl: AgentIdentityPrivacy.shouldHidePhoto(interaction.status)
          ? ''
          : (MediaUrlResolver.resolve(interaction.agentPhotoUrl) ?? ''),
      offerImageUrl: '',
      offerId: interaction.offerId,
      offerTitle: interaction.offerTitle,
      message: interaction.message,
      proposedPrice: interaction.proposedPrice?.toString() ?? '',
      status: interaction.status,
    );
  }

  /// True when this card can be shown or acted on in the Interested deck.
  bool get isActionable =>
      (reactionId > 0 && (id > 0 || offerId > 0)) || (id > 0 && offerId > 0);

  bool get isResolvedForDeck {
    final normalized = status.trim().toUpperCase();
    return normalized == 'ACCEPTED' ||
        normalized == 'REJECTED' ||
        normalized == 'MATCHED' ||
        normalized == 'DECLINED';
  }

  bool get isPendingForDeck {
    if (isResolvedForDeck) return false;

    final normalized = status.trim().toUpperCase();
    if (normalized.isEmpty) return false;

    return normalized == 'PENDING' ||
        normalized == 'WAITING' ||
        normalized == 'NEW' ||
        normalized == 'INTERESTED';
  }

  bool get hasGenericJobTitle {
    final normalized = jobTitle.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'interested agent';
  }

  /// Primary line under the agent name — the offer they liked (matches notifications).
  String get displaySubtitle {
    if (offerTitle.trim().isNotEmpty) return offerTitle.trim();
    if (!hasGenericJobTitle) return jobTitle.trim();
    return 'Interested in your offer';
  }

  /// Agent skills / category (secondary line when offer title is shown).
  String? get displaySkillsLine {
    if (hasGenericJobTitle) return null;
    final skills = jobTitle.trim();
    if (skills.isEmpty) return null;
    if (offerTitle.trim().isNotEmpty &&
        skills.toLowerCase() == offerTitle.trim().toLowerCase()) {
      return null;
    }
    return skills;
  }

  String get displayCity {
    if (city.trim().isNotEmpty) return city.trim();
    return 'Location not set';
  }

  /// Hero image on the swipe card — always the client's offer.
  String get coverImageUrl => offerImageUrl.trim();

  bool get isPendingInterest => AgentIdentityPrivacy.shouldHidePhoto(status);

  String get displayAgentLabel => AgentIdentityPrivacy.publicLabel(name);

  String get displayAgentInitials => AgentIdentityPrivacy.initials(name);

  bool get needsProfileEnrichment =>
      offerTitle.trim().isEmpty ||
      offerImageUrl.trim().isEmpty ||
      city.trim().isEmpty;

  /// Merges two records of the same reaction/agent without losing offer context.
  InterestedAgentModel mergeWith(InterestedAgentModel other) {
    final preferReaction = reactionId > 0 ? this : other;
    final fallback = preferReaction == this ? other : this;

    return preferReaction.copyWith(
      id: preferReaction.id > 0 ? preferReaction.id : fallback.id,
      reactionId: preferReaction.reactionId > 0
          ? preferReaction.reactionId
          : fallback.reactionId,
      offerId: preferReaction.offerId > 0 ? preferReaction.offerId : fallback.offerId,
      offerTitle: preferReaction.offerTitle.isNotEmpty
          ? preferReaction.offerTitle
          : fallback.offerTitle,
      offerImageUrl: preferReaction.offerImageUrl.isNotEmpty
          ? preferReaction.offerImageUrl
          : fallback.offerImageUrl,
      name: preferReaction.name.isNotEmpty ? preferReaction.name : fallback.name,
      jobTitle: preferReaction.jobTitle.isNotEmpty
          ? preferReaction.jobTitle
          : fallback.jobTitle,
      city: preferReaction.city.isNotEmpty ? preferReaction.city : fallback.city,
      imageUrl: preferReaction.isPendingInterest || fallback.isPendingInterest
          ? ''
          : (preferReaction.imageUrl.isNotEmpty
              ? preferReaction.imageUrl
              : fallback.imageUrl),
      message: preferReaction.message.isNotEmpty
          ? preferReaction.message
          : fallback.message,
      proposedPrice: preferReaction.proposedPrice.isNotEmpty
          ? preferReaction.proposedPrice
          : fallback.proposedPrice,
      createdAt: preferReaction.createdAt ?? fallback.createdAt,
      rating: preferReaction.rating > 0 ? preferReaction.rating : fallback.rating,
      completedJobs: preferReaction.completedJobs > 0
          ? preferReaction.completedJobs
          : fallback.completedJobs,
      status: _mergeStatus(preferReaction.status, fallback.status),
    );
  }

  static String _mergeStatus(String primary, String secondary) {
    const resolved = {'ACCEPTED', 'REJECTED', 'MATCHED', 'DECLINED'};

    final primaryNorm = primary.trim().toUpperCase();
    final secondaryNorm = secondary.trim().toUpperCase();

    if (resolved.contains(primaryNorm)) return primary;
    if (resolved.contains(secondaryNorm)) return secondary;
    if (primaryNorm.isNotEmpty) return primary;
    return secondary;
  }

  InterestedAgentModel enrichedWithProfile(AgentProfileModel profile) {
    final skills = profile.skills.trim();
    final profileCity = profile.city.trim();

    return copyWith(
      id: id > 0 ? id : (profile.userId ?? profile.profileId ?? id),
      name: profile.displayName.trim().isNotEmpty ? profile.displayName : name,
      jobTitle: skills.isNotEmpty ? skills : jobTitle,
      city: profileCity.isNotEmpty ? profileCity : city,
      rating: profile.averageRating > 0 ? profile.averageRating : rating,
      completedJobs:
          profile.ratingCount > 0 ? profile.ratingCount : completedJobs,
      // Photo stays hidden until acceptance; offer fields unchanged.
    );
  }

  factory InterestedAgentModel.fromJson(Map<String, dynamic> json) {
    final agent = _asMap(json['agent']);
    final offer = _asMap(json['offer'] ?? json['offre']);
    final source = <String, dynamic>{
      ...json,
      ...?agent,
    };

    // ClientInterestedAgentSerializer: `reactionId` + `id` (agent).
    // OffreReactionSerializer: `id` (reaction) + `agent` (user id).
    final hasExplicitReactionId = json.containsKey('reactionId') ||
        json.containsKey('reaction_id') ||
        json.containsKey('interactionId') ||
        json.containsKey('interaction_id');

    final reactionId = hasExplicitReactionId
        ? (_parseInt(
              _firstValue(json, const [
                'reactionId',
                'reaction_id',
                'interactionId',
                'interaction_id',
              ]),
            ) ??
            0)
        : (_parseInt(json['id']) ?? 0);

    final agentId = _resolveAgentId(json, agent, hasExplicitReactionId);

    final status = _parseString(_firstValue(source, const ['status'])).isEmpty
        ? 'PENDING'
        : _parseString(_firstValue(source, const ['status']));
    final pending = AgentIdentityPrivacy.shouldHidePhoto(status);

    return InterestedAgentModel(
      id: agentId,
      reactionId: reactionId,
      name: _parseString(
        _firstValue(source, const ['name', 'agentName', 'agent_name']),
      ),
      jobTitle: _parseString(
        _firstValue(source, const ['jobTitle', 'job_title', 'skills']),
      ),
      city: _parseString(_firstValue(source, const ['city', 'location'])),
      rating: _parseDouble(_firstValue(source, const ['rating', 'avg_rating'])),
      completedJobs:
          _parseInt(_firstValue(source, const ['completedJobs', 'completed_jobs'])) ??
              0,
      imageUrl: pending
          ? ''
          : (MediaUrlResolver.resolve(
                _parseString(
                  _firstValue(source, const [
                    'imageUrl',
                    'image_url',
                    'photo',
                    'photo_url',
                  ]),
                ),
              ) ??
              ''),
      offerId: _parseOfferId(json, offer),
      offerTitle: _parseOfferTitle(json, offer),
      offerImageUrl: _parseOfferImageUrl(json, offer),
      message: _parseString(_firstValue(source, const ['message', 'note'])),
      proposedPrice: _parseString(
        _firstValue(source, const ['proposedPrice', 'proposed_price', 'price']),
      ),
      status: status,
      createdAt: _parseDateTime(
        _firstValue(source, const ['createdAt', 'created_at']),
      ),
      hasRated: _parseBool(
        _firstValue(source, const ['hasRated', 'has_rated']),
      ),
    );
  }

  static dynamic _firstValue(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) {
        return map[key];
      }
    }
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static int _parseOfferId(
    Map<String, dynamic> json,
    Map<String, dynamic>? offer,
  ) {
    final direct = _parseInt(
      _firstValue(json, const ['offerId', 'offer_id']),
    );
    if (direct != null && direct > 0) return direct;

    final offre = _parseInt(json['offre']);
    if (offre != null && offre > 0) return offre;

    if (offer != null) {
      final nested = _parseInt(offer['id']);
      if (nested != null && nested > 0) return nested;
    }

    return 0;
  }

  static String _parseOfferTitle(
    Map<String, dynamic> json,
    Map<String, dynamic>? offer,
  ) {
    for (final map in [offer, json]) {
      if (map == null) continue;
      for (final key in const [
        'offerTitle',
        'offer_title',
        'offre_title',
      ]) {
        final value = map[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
    }

    if (offer != null) {
      final title = offer['title'];
      if (title != null && title.toString().trim().isNotEmpty) {
        return title.toString().trim();
      }
    }

    return '';
  }

  static String _parseOfferImageUrl(
    Map<String, dynamic> json,
    Map<String, dynamic>? offer,
  ) {
    for (final map in [offer, json]) {
      if (map == null) continue;
      final urls = MediaUrlResolver.parseImageList(
        map['images'] ?? map['photos'] ?? map['image_urls'],
      );
      if (urls.isNotEmpty) return urls.first;
      final single = map['image'] ?? map['cover'] ?? map['cover_url'];
      final resolved = MediaUrlResolver.resolve(single?.toString());
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }
    return '';
  }

  /// Resolves the agent user id without confusing reaction `id` fields.
  static int _resolveAgentId(
    Map<String, dynamic> json,
    Map<String, dynamic>? agent,
    bool hasExplicitReactionId,
  ) {
    final explicit = _parseInt(
      _firstValue(json, const ['agentId', 'agent_id']),
    );
    if (explicit != null && explicit > 0) return explicit;

    if (json['agent'] is int) {
      return json['agent'] as int;
    }

    if (agent != null) {
      final nested = _parseInt(
        _firstValue(agent, const ['id', 'user_id', 'agentId', 'agent_id']),
      );
      if (nested != null && nested > 0) return nested;

      final user = agent['user'];
      if (user is Map) {
        final userMap = Map<String, dynamic>.from(user);
        final userId = _parseInt(
          _firstValue(userMap, const ['id', 'user_id', 'userId']),
        );
        if (userId != null && userId > 0) return userId;
      }
      final userId = _parseInt(agent['user']);
      if (userId != null && userId > 0) return userId;
    }

    final userId = _parseInt(
      _firstValue(json, const ['user', 'user_id', 'userId']),
    );
    if (userId != null && userId > 0) return userId;

    if (hasExplicitReactionId) {
      return _parseInt(json['id']) ?? 0;
    }

    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    final normalized = value.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  InterestedAgentModel copyWith({
    int? id,
    int? reactionId,
    String? name,
    String? jobTitle,
    String? city,
    double? rating,
    int? completedJobs,
    String? imageUrl,
    String? offerImageUrl,
    int? offerId,
    String? offerTitle,
    String? message,
    String? proposedPrice,
    String? status,
    DateTime? createdAt,
    bool? hasRated,
  }) {
    return InterestedAgentModel(
      id: id ?? this.id,
      reactionId: reactionId ?? this.reactionId,
      name: name ?? this.name,
      jobTitle: jobTitle ?? this.jobTitle,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      imageUrl: imageUrl ?? this.imageUrl,
      offerImageUrl: offerImageUrl ?? this.offerImageUrl,
      offerId: offerId ?? this.offerId,
      offerTitle: offerTitle ?? this.offerTitle,
      message: message ?? this.message,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      hasRated: hasRated ?? this.hasRated,
    );
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}