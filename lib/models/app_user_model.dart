class AppUser {
  final int id;
  final String email;
  final String username;
  final String role;
  final bool isEmailVerified;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    required this.isEmailVerified,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      email: (json['email'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      isEmailVerified: json['isEmailVerified'] == true,
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}

class SignUpResponse {
  final String message;
  final AppUser user;

  const SignUpResponse({
    required this.message,
    required this.user,
  });

  factory SignUpResponse.fromJson(Map<String, dynamic> json) {
    return SignUpResponse(
      message: (json['message'] ?? '').toString(),
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final int userId;
  final String role;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.role,
  });
}