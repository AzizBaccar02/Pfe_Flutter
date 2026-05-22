class AgentProfileModel {
  final int? userId;
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

  const AgentProfileModel({
    this.userId,
    required this.firstName,
    required this.lastName,
    this.email = '',
    required this.phone,
    required this.photoUrl,
    required this.bio,
    required this.skills,
    required this.hourlyRate,
    required this.city,
    required this.address,
    required this.postalCode,
    required this.isProfileCompleted,
  });

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
    final photoUrl = photoRaw.startsWith('http')
        ? photoRaw
        : photoRaw.isNotEmpty
            ? 'http://127.0.0.1:8000$photoRaw'
            : '';

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
    );
  }

  factory AgentProfileModel.fromApi({
    required Map<String, dynamic> meJson,
    required Map<String, dynamic> agentJson,
  }) {
    final rawHourlyRate = agentJson['hourlyRate'] ?? 0;

    final photoRaw = (agentJson['photo'] ?? '').toString();
    final photoUrl = photoRaw.startsWith('http')
        ? photoRaw
        : photoRaw.isNotEmpty
            ? 'http://127.0.0.1:8000$photoRaw'
            : '';

    return AgentProfileModel(
      firstName:          (meJson['first_name'] ?? '').toString(),
      lastName:           (meJson['last_name'] ?? '').toString(),
      email:              (meJson['email'] ?? '').toString(),
      phone:              (agentJson['phone'] ?? '').toString(),
      photoUrl:           photoUrl,
      bio:                (agentJson['bio'] ?? '').toString(),
      skills:             (agentJson['skills'] ?? '').toString(),
      hourlyRate:         double.tryParse(rawHourlyRate.toString()) ?? 0,
      city:               (agentJson['city_value'] ?? '').toString(),
      address:            (agentJson['address_value'] ?? '').toString(),
      postalCode:         (agentJson['postal_code_value'] ?? '').toString(),
      isProfileCompleted: meJson['isProfileCompleted'] == true,
    );
  }
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