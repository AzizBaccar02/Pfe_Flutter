class ClientProfileModel {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String photoUrl;
  final String city;
  final String address;
  final String postalCode;
  final bool isProfileCompleted;

  const ClientProfileModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.photoUrl,
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

    if (value.isEmpty) return 'Client';

    return value;
  }

  factory ClientProfileModel.fromApi({
    required Map<String, dynamic> meJson,
    required Map<String, dynamic> clientJson,
  }) {
    final profile = (meJson['profile'] as Map<String, dynamic>?) ?? {};

    return ClientProfileModel(
      firstName: (meJson['first_name'] ?? '').toString(),
      lastName: (meJson['last_name'] ?? '').toString(),
      email: (meJson['email'] ?? '').toString(),
      phone: (clientJson['phone'] ?? profile['phone'] ?? '').toString(),
      photoUrl: (clientJson['photo'] ?? profile['photo'] ?? '').toString(),
      city: (clientJson['city_value'] ?? '').toString(),
      address: (clientJson['address_value'] ?? '').toString(),
      postalCode: (clientJson['postal_code_value'] ?? '').toString(),
      isProfileCompleted: meJson['isProfileCompleted'] == true,
    );
  }
}