// lib/services/notification_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/app_notification_model.dart';
import 'auth_service.dart';

class NotificationService {
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

  static String get _socketBaseUrl {
    if (kIsWeb) {
      return 'ws://127.0.0.1:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ws://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'ws://127.0.0.1:8000';
      default:
        return 'ws://127.0.0.1:8000';
    }
  }

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getAccessToken();

    if (token == null || token.isEmpty) {
      throw const NotificationServiceException('No active session found.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<WebSocketChannel> connectToNotificationSocket() async {
    final userId = await AuthService.getStoredUserId();

    debugPrint('[NOTIFICATION_SERVICE] Stored user id: $userId');

    if (userId == null || userId <= 0) {
      throw const NotificationServiceException('No active user found.');
    }

    final socketUri = Uri.parse('$_socketBaseUrl/ws/notifications/$userId/');

    debugPrint('[NOTIFICATION_SERVICE] Connecting socket: $socketUri');

    return WebSocketChannel.connect(socketUri);
  }

  static Future<List<AppNotificationModel>> getMyNotifications() async {
    final decoded = await _getJson(
      path: '/api/notifications/me/',
      expectedStatusCode: 200,
    );

    if (decoded is! List) {
      throw const NotificationServiceException(
        'Invalid notifications response from server.',
      );
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => AppNotificationModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  static Future<int> getUnreadCount() async {
    final decoded = await _getJson(
      path: '/api/notifications/me/unread-count/',
      expectedStatusCode: 200,
    );

    if (decoded is! Map<String, dynamic>) {
      return 0;
    }

    return _parseInt(decoded['unread_count']) ?? 0;
  }

  static Future<void> markAllAsRead() async {
    await _patchJson(
      path: '/api/notifications/me/read-all/',
      payload: {},
      expectedStatusCode: 200,
    );
  }

  static Future<dynamic> _getJson({
    required String path,
    required int expectedStatusCode,
  }) async {
    try {
      final uri = _uri(path);
      final headers = await _authHeaders();

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));

      final decoded = _decodeBody(response.body);

      if (response.statusCode == expectedStatusCode) {
        return decoded;
      }

      throw NotificationServiceException(_extractErrorMessage(decoded));
    } on TimeoutException {
      throw const NotificationServiceException(
        'The request took too long. Please try again.',
      );
    } on http.ClientException {
      throw const NotificationServiceException(
        'Unable to reach the server. Please make sure the backend is running.',
      );
    } catch (e) {
      if (e is NotificationServiceException) rethrow;

      throw const NotificationServiceException(
        'Something went wrong. Please try again.',
      );
    }
  }

  static Future<dynamic> _patchJson({
    required String path,
    required Map<String, dynamic> payload,
    required int expectedStatusCode,
  }) async {
    try {
      final uri = _uri(path);
      final headers = await _authHeaders();

      final response = await http
          .patch(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      final decoded = _decodeBody(response.body);

      if (response.statusCode == expectedStatusCode) {
        return decoded;
      }

      throw NotificationServiceException(_extractErrorMessage(decoded));
    } on TimeoutException {
      throw const NotificationServiceException(
        'The request took too long. Please try again.',
      );
    } on http.ClientException {
      throw const NotificationServiceException(
        'Unable to reach the server. Please make sure the backend is running.',
      );
    } catch (e) {
      if (e is NotificationServiceException) rethrow;

      throw const NotificationServiceException(
        'Something went wrong. Please try again.',
      );
    }
  }

  static dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;

    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static String _extractErrorMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['error'] != null) return body['error'].toString();
      if (body['detail'] != null) return body['detail'].toString();
      if (body['message'] != null) return body['message'].toString();
    }

    if (body is String && body.trim().isNotEmpty) {
      return body;
    }

    return 'Something went wrong. Please try again.';
  }
}

class NotificationServiceException implements Exception {
  final String message;

  const NotificationServiceException(this.message);

  @override
  String toString() => message;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}