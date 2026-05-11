
//lib/services/auth_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user_model.dart';

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _roleKey = 'role';
  static const String _completeProfilePromptPrefix =
      'seen_complete_profile_prompt_';

  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static String get apiBaseUrl => _baseUrl;

  static Uri apiUri(String path) => _uri(path);

  static Future<SignUpResponse> signUp({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final payload = <String, dynamic>{
      'username': username.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'role': role.trim().toUpperCase(),
    };

    final decoded = await _postJson(
      path: '/api/users/signup/',
      payload: payload,
      expectedStatusCode: 201,
    );

    return SignUpResponse.fromJson(decoded as Map<String, dynamic>);
  }

  static Future<String> verifyEmail({
    required String email,
    required String code,
  }) async {
    final decoded = await _postJson(
      path: '/api/users/verify-email/',
      payload: {
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      },
      expectedStatusCode: 200,
    );

    final map = decoded as Map<String, dynamic>;
    final accessToken = (map['access'] ?? '').toString();
    final refreshToken = (map['refresh'] ?? '').toString();

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw const AuthException(
        'Invalid verification response from server.',
      );
    }

    final session = _buildLoginResponseFromTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    await saveLoginSession(session);

    return (map['message'] ?? 'Email verified successfully.').toString();
  }

  static Future<String> resendVerificationCode({
    required String email,
  }) async {
    final decoded = await _postJson(
      path: '/api/users/resend-code/',
      payload: {
        'email': email.trim().toLowerCase(),
      },
      expectedStatusCode: 200,
    );

    if (decoded is Map<String, dynamic>) {
      return (decoded['message'] ?? 'Verification code resent.').toString();
    }

    return 'Verification code resent.';
  }

  static Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final decoded = await _postJson(
      path: '/api/auth/login/',
      payload: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      expectedStatusCode: 200,
    );

    final map = decoded as Map<String, dynamic>;
    final accessToken = (map['access'] ?? '').toString();
    final refreshToken = (map['refresh'] ?? '').toString();

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw const AuthException('Invalid login response from server.');
    }

    return _buildLoginResponseFromTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  static Future<String> forgotPassword({
    required String email,
  }) async {
    final decoded = await _postJson(
      path: '/api/users/forgot-password/',
      payload: {
        'email': email.trim().toLowerCase(),
      },
      expectedStatusCode: 200,
    );

    if (decoded is Map<String, dynamic>) {
      return (decoded['message'] ??
              'If the email exists, a reset code has been sent.')
          .toString();
    }

    return 'If the email exists, a reset code has been sent.';
  }

  static Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final decoded = await _postJson(
      path: '/api/users/reset-password/',
      payload: {
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
        'new_password': newPassword,
      },
      expectedStatusCode: 200,
    );

    if (decoded is Map<String, dynamic>) {
      return (decoded['message'] ??
              'Password reset successful. You can login now.')
          .toString();
    }

    return 'Password reset successful. You can login now.';
  }

  static LoginResponse _buildLoginResponseFromTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    final payload = _decodeJwtPayload(accessToken);

    final dynamic userIdRaw = payload['user_id'] ?? payload['userId'];
    final dynamic roleRaw = payload['role'];

    final int? userId = _parseInt(userIdRaw);
    final String role = (roleRaw ?? '').toString();

    if (userId == null || role.isEmpty) {
      throw const AuthException('Unable to read user session from token.');
    }

    return LoginResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      role: role,
    );
  }

  static Future<void> saveLoginSession(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, response.accessToken);
    await prefs.setString(_refreshTokenKey, response.refreshToken);
    await prefs.setInt(_userIdKey, response.userId);
    await prefs.setString(_roleKey, response.role);
  }

  static Future<void> clearLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_roleKey);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<int?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<String?> getStoredRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<bool> hasActiveSession() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    final userId = await getStoredUserId();
    final role = await getStoredRole();

    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty &&
        userId != null &&
        role != null &&
        role.isNotEmpty;
  }

  static Future<bool> hasSeenCompleteProfilePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);

    if (userId == null) return false;

    return prefs.getBool(_promptKeyForUser(userId)) ?? false;
  }

  static Future<void> markCompleteProfilePromptSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);

    if (userId == null) return;

    await prefs.setBool(_promptKeyForUser(userId), true);
  }

  static String _promptKeyForUser(int userId) {
    return '$_completeProfilePromptPrefix$userId';
  }

  static Future<dynamic> _postJson({
    required String path,
    required Map<String, dynamic> payload,
    required int expectedStatusCode,
  }) async {
    try {
      final response = await http
          .post(
            _uri(path),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      final dynamic decoded =
          response.body.isNotEmpty ? jsonDecode(response.body) : null;

      if (response.statusCode == expectedStatusCode) {
        return decoded;
      }

      throw AuthException(_extractErrorMessage(decoded));
    } on TimeoutException {
      throw const AuthException(
        'The request took too long. Please check your connection and try again.',
      );
    } on http.ClientException {
      throw const AuthException(
        'Unable to reach the server. Please make sure the backend is running.',
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException(
        'Something went wrong. Please try again.',
      );
    }
  }

  static Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const AuthException('Invalid access token received.');
    }

    final normalized = base64Url.normalize(parts[1]);
    final payloadString = utf8.decode(base64Url.decode(normalized));
    final dynamic payload = jsonDecode(payloadString);

    if (payload is! Map<String, dynamic>) {
      throw const AuthException('Invalid token payload received.');
    }

    return payload;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static String _extractErrorMessage(dynamic body) {
    if (body == null) {
      return 'Something went wrong. Please try again.';
    }

    if (body is String && body.trim().isNotEmpty) {
      return body;
    }

    if (body is Map<String, dynamic>) {
      if (body['message'] != null &&
          body['message'].toString().trim().isNotEmpty) {
        return body['message'].toString();
      }

      if (body['detail'] != null &&
          body['detail'].toString().trim().isNotEmpty) {
        return body['detail'].toString();
      }

      for (final entry in body.entries) {
        final value = entry.value;

        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }

        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }

    return 'Something went wrong. Please try again.';
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}