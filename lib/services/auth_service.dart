import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const String authBase = '$baseUrl/api/auth';
  static const String usersBase = '$baseUrl/api/users';

  static Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) return {};

    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return {};
  }

  static String _extractErrorMessage(Map<String, dynamic> body) {
    if (body['detail'] is String) return body['detail'];
    if (body['message'] is String) return body['message'];

    for (final key in body.keys) {
      final value = body[key];
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
      if (value is String) {
        return value;
      }
    }

    return 'Something went wrong.';
  }

  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String role,
    String? username,
    String? phone,
    String? bio,
    String? skills,
    double? hourlyRate,
    int? localisationId,
  }) async {
    final response = await http.post(
      Uri.parse('$usersBase/signup/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role,
        'username': username?.trim(),
        'phone': phone?.trim(),
        'bio': bio?.trim(),
        'skills': skills?.trim(),
        'hourlyRate': hourlyRate,
        'localisation_id': localisationId,
      }),
    );

    final body = _decodeBody(response.body);

    if (response.statusCode == 201) {
      return body;
    }

    throw Exception(_extractErrorMessage(body));
  }

  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$usersBase/verify-email/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      }),
    );

    final body = _decodeBody(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(_extractErrorMessage(body));
  }

  static Future<Map<String, dynamic>> resendVerificationCode({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$usersBase/resend-code/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
      }),
    );

    final body = _decodeBody(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(_extractErrorMessage(body));
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$authBase/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    final body = _decodeBody(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(_extractErrorMessage(body));
  }

  static Future<Map<String, dynamic>> getMe({
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse('$usersBase/me/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    final body = _decodeBody(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(_extractErrorMessage(body));
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$usersBase/forgot-password/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
      }),
    );

    final body = _decodeBody(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(_extractErrorMessage(body));
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$usersBase/reset-password/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
        'new_password': newPassword,
      }),
    );

    final body = _decodeBody(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(_extractErrorMessage(body));
  }

  static Future<Map<String, dynamic>> logout({
    required String refreshToken,
    required String accessToken,
  }) async {
    final response = await http.post(
      Uri.parse('$authBase/logout/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'refresh': refreshToken,
      }),
    );

    final body = _decodeBody(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(_extractErrorMessage(body));
  }
}