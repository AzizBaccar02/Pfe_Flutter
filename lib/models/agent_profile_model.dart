import '../utils/media_url_resolver.dart';

class AgentProfileModel {
  final int? userId;
  /// Agent profile row id from `/api/users/agent/profile/me/`.
  final int? profileId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String photoUrl;
  final String bio;
  final String skills;
  final double hourlyRate;
  final String city;
  final String address;
  final String postalCode;
  final bool isProfileCompleted;
  final double averageRating;
  final int ratingCount;

  const AgentProfileModel({
    this.userId,
    this.profileId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.bio,
    required this.skills,
    required this.hourlyRate,
    required this.city,
    required this.address,
    required this.postalCode,
    required this.isProfileCompleted,
    this.averageRating = 0,
    this.ratingCount = 0,
  });

  bool get hasRatings => ratingCount > 0 && averageRating > 0;

  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? 'Agent' : full;
  }

  bool get hasDisplayableContent =>
      city.isNotEmpty ||
      phone.isNotEmpty ||
      bio.isNotEmpty ||
      skills.isNotEmpty ||
      hourlyRate > 0;

  factory AgentProfileModel.fromPublicMap(Map<String, dynamic> json) {
    final firstName = (json['first_name'] ?? json['firstName'] ?? '').toString();
    final lastName  = (json['last_name']  ?? json['lastName']  ?? '').toString();
    final email     = (json['email'] ?? '').toString();
    final rawHourlyRate = json['hourlyRate'] ?? json['hourly_rate'] ?? 0;

    final photoRaw = _pickPhoto(json) ?? '';
    final photoUrl = MediaUrlResolver.resolve(photoRaw) ?? '';

    return AgentProfileModel(
      firstName:          firstName,
      lastName:           lastName,
      email:              email,
      phone:              (json['phone'] ?? '').toString(),
      photoUrl:           photoUrl,
      bio:                (json['bio'] ?? '').toString(),
      skills:             (json['skills'] ?? '').toString(),
      hourlyRate:         double.tryParse(rawHourlyRate.toString()) ?? 0,
      city:               (json['city_value'] ?? json['city'] ?? '').toString(),
      address:            (json['address_value'] ?? json['address'] ?? '').toString(),
      postalCode:         (json['postal_code_value'] ?? json['postalCode'] ?? '').toString(),
      isProfileCompleted: json['isProfileCompleted'] == true,
      averageRating: _parseDouble(
        json['rating'] ?? json['averageRating'] ?? json['average_rating'],
      ),
      ratingCount: _parseInt(
            json['ratingCount'] ??
                json['rating_count'] ??
                json['completedJobs'] ??
                json['completed_jobs'],
          ) ??
          0,
    );
  }

  factory AgentProfileModel.fromApi({
    required Map<String, dynamic> meJson,
    required Map<String, dynamic> agentJson,
  }) {
    final profile = meJson['profile'] is Map
        ? Map<String, dynamic>.from(meJson['profile'] as Map)
        : <String, dynamic>{};

    final rawHourlyRate =
        agentJson['hourlyRate'] ?? agentJson['hourly_rate'] ?? 0;

    final photoRaw =
        _pickPhoto(agentJson) ?? _pickPhoto(profile) ?? '';
    final photoUrl = MediaUrlResolver.resolve(photoRaw) ?? '';

    final userIdRaw = meJson['id'] ?? meJson['userId'] ?? meJson['user_id'];
    final userId = userIdRaw is int
        ? userIdRaw
        : int.tryParse(userIdRaw?.toString() ?? '');

    final profileIdRaw = agentJson['id'] ?? agentJson['agentId'];
    final profileId = profileIdRaw is int
        ? profileIdRaw
        : int.tryParse(profileIdRaw?.toString() ?? '');

    return AgentProfileModel(
      userId: userId,
      profileId: profileId,
      firstName: (meJson['first_name'] ?? meJson['firstName'] ?? '')
          .toString(),
      lastName:
          (meJson['last_name'] ?? meJson['lastName'] ?? '').toString(),
      email: (meJson['email'] ?? '').toString(),
      phone: (agentJson['phone'] ?? profile['phone'] ?? '').toString(),
      photoUrl: photoUrl,
      bio: (agentJson['bio'] ?? profile['bio'] ?? '').toString(),
      skills: (agentJson['skills'] ?? profile['skills'] ?? '').toString(),
      hourlyRate: double.tryParse(rawHourlyRate.toString()) ?? 0,
      city: (agentJson['city_value'] ?? agentJson['city'] ?? '').toString(),
      address:
          (agentJson['address_value'] ?? agentJson['address'] ?? '')
              .toString(),
      postalCode: (agentJson['postal_code_value'] ??
              agentJson['postalCode'] ??
              '')
          .toString(),
      isProfileCompleted: meJson['isProfileCompleted'] == true,
      averageRating: _parseDouble(
        agentJson['rating'] ??
            agentJson['averageRating'] ??
            agentJson['average_rating'],
      ),
      ratingCount: _parseInt(
            agentJson['ratingCount'] ??
                agentJson['rating_count'] ??
                agentJson['completedJobs'] ??
                agentJson['completed_jobs'],
          ) ??
          0,
    );
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value.toString());
}

String? _pickPhoto(Map<String, dynamic> map) {
  for (final key in [
    'photo', 'photoUrl', 'photo_url', 'avatar',
    'avatar_url', 'profile_photo', 'profile_picture', 'image',
  ]) {
    final value = map[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}