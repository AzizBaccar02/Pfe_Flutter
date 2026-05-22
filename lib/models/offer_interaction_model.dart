// lib/models/offer_interaction_model.dart

class OfferInteractionModel {
  final int id;
  final int offerId;
  final String offerTitle;
  final int agentId;
  final int? agentUserId;
  final String? agentEmail;
  final String? agentName;
  final String? agentPhotoUrl;
  final String? agentPhone;
  final String? agentCity;
  final String? agentBio;
  final String? agentSkills;
  final double? agentHourlyRate;
  final String message;
  final double? proposedPrice;
  final String status;
  final bool react;

  const OfferInteractionModel({
    required this.id,
    required this.offerId,
    required this.offerTitle,
    required this.agentId,
    this.agentUserId,
    this.agentEmail,
    this.agentName,
    this.agentPhotoUrl,
    this.agentPhone,
    this.agentCity,
    this.agentBio,
    this.agentSkills,
    this.agentHourlyRate,
    required this.message,
    this.proposedPrice,
    required this.status,
    required this.react,
  });

  factory OfferInteractionModel.fromJson(Map<String, dynamic> json) {
    final agentFields = _parseAgentFields(json);

    return OfferInteractionModel(
      id: _parseInt(json['id']) ?? 0,
      offerId: _parseInt(json['offre']) ??
          _parseInt(json['offer_id']) ??
          _parseInt(json['offerId']) ??
          0,
      offerTitle: json['offer_title']?.toString() ??
          json['offerTitle']?.toString() ??
          '',
      agentId: agentFields.agentId,
      agentUserId: agentFields.agentUserId,
      agentEmail: agentFields.email ??
          json['agent_email']?.toString() ??
          json['agentEmail']?.toString(),
      agentName: agentFields.name ??
          json['agent_name']?.toString() ??
          json['agentName']?.toString(),
      agentPhotoUrl: agentFields.photoUrl,
      agentPhone: agentFields.phone,
      agentCity: agentFields.city,
      agentBio: agentFields.bio,
      agentSkills: agentFields.skills,
      agentHourlyRate: agentFields.hourlyRate,
      message: json['message']?.toString() ?? '',
      proposedPrice: _parseDouble(json['proposedPrice']) ??
          _parseDouble(json['proposed_price']),
      status: json['status']?.toString() ?? 'PENDING',
      react: _parseBool(json['react']) ?? true,
    );
  }
}

class _AgentFields {
  final int agentId;
  final int? agentUserId;
  final String? name;
  final String? email;
  final String? photoUrl;
  final String? phone;
  final String? city;
  final String? bio;
  final String? skills;
  final double? hourlyRate;

  const _AgentFields({
    required this.agentId,
    this.agentUserId,
    this.name,
    this.email,
    this.photoUrl,
    this.phone,
    this.city,
    this.bio,
    this.skills,
    this.hourlyRate,
  });
}

_AgentFields _parseAgentFields(Map<String, dynamic> json) {
  final raw = json['agent'];

  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    final user = map['user'] is Map
        ? Map<String, dynamic>.from(map['user'] as Map)
        : null;

    final first = map['firstName']?.toString() ??
        map['first_name']?.toString() ??
        user?['firstName']?.toString() ??
        user?['first_name']?.toString() ??
        '';
    final last = map['lastName']?.toString() ??
        map['last_name']?.toString() ??
        user?['lastName']?.toString() ??
        user?['last_name']?.toString() ??
        '';
    final fullName = '$first $last'.trim();

    return _AgentFields(
      agentId: _parseInt(map['id']) ?? 0,
      agentUserId: _parseInt(map['user']) ??
          _parseInt(map['user_id']) ??
          _parseInt(user?['id']),
      name: fullName.isNotEmpty
          ? fullName
          : map['username']?.toString() ?? user?['username']?.toString(),
      email: map['email']?.toString() ?? user?['email']?.toString(),
      photoUrl: _pickPhoto(map) ?? (user != null ? _pickPhoto(user) : null),
      phone: _pickPhone(map) ?? (user != null ? _pickPhone(user) : null),
      city: map['city_value']?.toString() ??
          map['city']?.toString() ??
          user?['city']?.toString(),
      bio: map['bio']?.toString(),
      skills: map['skills']?.toString(),
      hourlyRate: _parseDouble(map['hourlyRate']) ??
          _parseDouble(map['hourly_rate']),
    );
  }

  return _AgentFields(
    agentId: _parseInt(raw) ??
        _parseInt(json['agent_id']) ??
        _parseInt(json['agentId']) ??
        0,
  );
}

String? _pickPhoto(Map<String, dynamic> map) {
  for (final key in [
    'photo',
    'photoUrl',
    'photo_url',
    'avatar',
    'profile_photo',
    'image',
  ]) {
    final value = map[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

String? _pickPhone(Map<String, dynamic> map) {
  for (final key in ['phone', 'phoneNumber', 'phone_number', 'mobile']) {
    final value = map[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

class BrowseOfferModel {
  final int id;
  final int clientUserId;
  final String title;
  final String description;
  final String category;
  final String city;
  final String budgetLabel;
  final String clientName;
  final List<String> imageUrls;

  const BrowseOfferModel({
    required this.id,
    required this.clientUserId,
    required this.title,
    required this.description,
    required this.category,
    required this.city,
    required this.budgetLabel,
    required this.clientName,
    required this.imageUrls,
  });

  factory BrowseOfferModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'];
    int clientUserId = _parseInt(json['client_id']) ??
        _parseInt(json['clientId']) ??
        _parseInt(json['user']) ??
        0;

    if (client is Map) {
      clientUserId = _parseInt(client['id']) ??
          _parseInt(client['user_id']) ??
          clientUserId;
    }

    final images = <String>[];
    final rawImages = json['images'] ?? json['photos'] ?? json['image_urls'];

    if (rawImages is List) {
      for (final item in rawImages) {
        if (item is String && item.trim().isNotEmpty) {
          images.add(item);
        } else if (item is Map) {
          final url = item['url']?.toString() ?? item['image']?.toString();
          if (url != null && url.trim().isNotEmpty) {
            images.add(url);
          }
        }
      }
    }

    final budget = json['budget'] ?? json['proposedPrice'] ?? json['price'];

    return BrowseOfferModel(
      id: _parseInt(json['id']) ?? 0,
      clientUserId: clientUserId,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      city: json['city']?.toString() ??
          json['city_value']?.toString() ??
          'Tunis',
      budgetLabel: budget != null ? '$budget DT' : '—',
      clientName: _resolveClientName(json, client),
      imageUrls: images,
    );
  }

  static String _resolveClientName(
    Map<String, dynamic> json,
    dynamic client,
  ) {
    if (client is Map) {
      final first = client['firstName']?.toString() ?? '';
      final last = client['lastName']?.toString() ?? '';
      final full = '$first $last'.trim();
      if (full.isNotEmpty) return full;
      final username = client['username']?.toString();
      if (username != null && username.isNotEmpty) return username;
    }

    return json['client_name']?.toString() ?? 'Client';
  }
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
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}
