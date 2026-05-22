class AgentProfileModel {
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
  });

  String get fullName {
    final value = [
      firstName.trim(),
      lastName.trim(),
    ].where((part) => part.isNotEmpty).join(' ');

    if (value.isEmpty) return 'Agent';

    return value;
  }

  factory AgentProfileModel.fromApi({
    required Map<String, dynamic> meJson,
    required Map<String, dynamic> agentJson,
  }) {
    final profile = (meJson['profile'] as Map<String, dynamic>?) ?? {};

    final rawHourlyRate =
        agentJson['hourlyRate'] ?? profile['hourlyRate'] ?? 0;

    return AgentProfileModel(
      firstName: (meJson['first_name'] ?? '').toString(),
      lastName: (meJson['last_name'] ?? '').toString(),
      email: (meJson['email'] ?? '').toString(),
      phone: (agentJson['phone'] ?? profile['phone'] ?? '').toString(),
      photoUrl: (agentJson['photo'] ?? profile['photo'] ?? '').toString(),
      bio: (agentJson['bio'] ?? profile['bio'] ?? '').toString(),
      skills: (agentJson['skills'] ?? profile['skills'] ?? '').toString(),
      hourlyRate: double.tryParse(rawHourlyRate.toString()) ?? 0,
      city: (agentJson['city_value'] ?? '').toString(),
      address: (agentJson['address_value'] ?? '').toString(),
      postalCode: (agentJson['postal_code_value'] ?? '').toString(),
      isProfileCompleted: meJson['isProfileCompleted'] == true,
    );
  }
}