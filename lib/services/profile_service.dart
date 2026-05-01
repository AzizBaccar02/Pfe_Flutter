import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/client_profile_model.dart';
import 'auth_service.dart';

class ProfileService {
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

  static String? resolveMediaUrl(String? rawUrl) {
    if (rawUrl == null) return null;

    final value = rawUrl.trim();
    if (value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    return '$_baseUrl$value';
  }

  static Future<ClientProfileModel> getClientProfile() async {
    final token = await _getAccessToken();

    final meResponse = await http.get(
      _uri('/api/users/me/'),
      headers: _jsonHeaders(token),
    ).timeout(const Duration(seconds: 20));

    final clientResponse = await http.get(
      _uri('/api/users/client/profile/me/'),
      headers: _jsonHeaders(token),
    ).timeout(const Duration(seconds: 20));

    final meJson = _decodeBody(meResponse);
    final clientJson = _decodeBody(clientResponse);

    if (meResponse.statusCode != 200) {
      throw ProfileException(_extractErrorMessage(meJson));
    }

    if (clientResponse.statusCode != 200) {
      throw ProfileException(_extractErrorMessage(clientJson));
    }

    return ClientProfileModel.fromApi(
      meJson: meJson as Map<String, dynamic>,
      clientJson: clientJson as Map<String, dynamic>,
    );
  }

  static Future<void> updateClientBasicInfo({
    required String firstName,
    required String lastName,
  }) async {
    final token = await _getAccessToken();

    final response = await http.patch(
      _uri('/api/users/me/'),
      headers: _jsonHeaders(token),
      body: jsonEncode({
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
      }),
    ).timeout(const Duration(seconds: 20));

    final decoded = _decodeBody(response);

    if (response.statusCode != 200) {
      throw ProfileException(_extractErrorMessage(decoded));
    }
  }

  static Future<void> updateClientContact({
    required String phone,
    String? photoPath,
  }) async {
    final token = await _getAccessToken();

    final request = http.MultipartRequest(
      'PATCH',
      _uri('/api/users/profile/'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields['phone'] = phone.trim();

    if (photoPath != null && photoPath.trim().isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('photo', photoPath));
    }

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);
    final decoded = _decodeBody(response);

    if (response.statusCode != 200) {
      throw ProfileException(_extractErrorMessage(decoded));
    }
  }

  static Future<void> updateClientLocation({
    required String city,
    String? address,
    String? postalCode,
  }) async {
    final token = await _getAccessToken();

    final payload = <String, dynamic>{
      'city': city,
    };

    if (address != null && address.trim().isNotEmpty) {
      payload['address'] = address.trim();
    }

    if (postalCode != null && postalCode.trim().isNotEmpty) {
      payload['postalCode'] = postalCode.trim();
    }

    final response = await http.patch(
      _uri('/api/users/client/profile/me/'),
      headers: _jsonHeaders(token),
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 20));

    final decoded = _decodeBody(response);

    if (response.statusCode != 200) {
      throw ProfileException(_extractErrorMessage(decoded));
    }
  }

  static Future<String> _getAccessToken() async {
    final token = await AuthService.getAccessToken();

    if (token == null || token.isEmpty) {
      throw const ProfileException('No active session found.');
    }

    return token;
  }

  static Map<String, String> _jsonHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
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

class ProfileException implements Exception {
  final String message;

  const ProfileException(this.message);

  @override
  String toString() => message;
}