// lib/services/notification_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../conf/api_config.dart';
import '../models/app_notification_model.dart';
import 'auth_service.dart';

class NotificationService {
  static String get _baseUrl => ApiConfig.httpBaseUrl;

  static String get _socketBaseUrl => ApiConfig.wsBaseUrl;

  static Uri _uri(String path) => ApiConfig.httpUri(path);

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
    final token = await AuthService.getAccessToken();
    final userId = await AuthService.getStoredUserId();

    debugPrint('[NOTIFICATION_SERVICE] Stored user id: $userId');

    if (token == null || token.isEmpty) {
      throw const NotificationServiceException('No active session found.');
    }

    if (userId == null || userId <= 0) {
      throw const NotificationServiceException('No active user found.');
    }

    final encodedToken = Uri.encodeComponent(token);
    final socketUri = Uri.parse(
      '$_socketBaseUrl/ws/notifications/$userId/?token=$encodedToken',
    );

    debugPrint('[NOTIFICATION_SERVICE] Connecting socket: $socketUri');

    return WebSocketChannel.connect(socketUri);
  }

  static Future<void> markAsRead(int notificationId) async {
    if (notificationId <= 0) return;

    await _patchJson(
      path: '/api/notifications/me/$notificationId/read/',
      payload: const {},
      expectedStatusCode: 200,
    );
  }

  static Future<List<AppNotificationModel>> getMyNotifications() async {
    final decoded = await _getJson(
      path: '/api/notifications/me/',
      expectedStatusCode: 200,
    );

    debugPrint('[NOTIFICATION_SERVICE] GET /me/ decoded: $decoded');

    final items = _extractNotificationList(decoded);
    debugPrint(
      '[NOTIFICATION_SERVICE] Parsed ${items.length} notification(s). '
      'If 0 after a react in Postman, Django must call create_and_send_notification() '
      'in the react view (see django_interactions_patches/POSTMAN_VERIFY_NOTIFICATIONS.md).',
    );

    return items
        .map(
          (item) => AppNotificationModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  /// DRF may return a bare list or a paginated `{ results: [...] }` payload.
  static List<Map<dynamic, dynamic>> _extractNotificationList(dynamic decoded) {
    if (decoded is List) {
      return decoded.whereType<Map>().map(Map<dynamic, dynamic>.from).toList();
    }

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);

      for (final key in ['results', 'data', 'notifications', 'items']) {
        final nested = map[key];
        if (nested is List) {
          return nested.whereType<Map>().map(Map<dynamic, dynamic>.from).toList();
        }
      }
    }

    throw const NotificationServiceException(
      'Invalid notifications response from server.',
    );
  }

  static Future<int> getUnreadCount() async {
    final decoded = await _getJson(
      path: '/api/notifications/me/unread-count/',
      expectedStatusCode: 200,
    );

    if (decoded is! Map<String, dynamic>) {
      return 0;
    }

    return _parseInt(decoded['unread_count']) ??
        _parseInt(decoded['unreadCount']) ??
        0;
  }

  /// Marks every notification as read (bulk endpoint, then one-by-one fallback).
  static Future<void> markAllAsRead() async {
    try {
      await _patchJson(
        path: '/api/notifications/me/read-all/',
        payload: const {},
        expectedStatusCode: 200,
      );
      debugPrint('[NOTIFICATION_SERVICE] markAllAsRead: bulk OK');
      return;
    } on NotificationServiceException catch (e) {
      debugPrint('[NOTIFICATION_SERVICE] markAllAsRead bulk failed: $e');
    }

    final items = await getMyNotifications();
    final unread = items.where((item) => !item.isRead).toList();

    for (final item in unread) {
      try {
        await markAsRead(item.id);
      } on NotificationServiceException catch (e) {
        debugPrint(
          '[NOTIFICATION_SERVICE] markAsRead(${item.id}) failed: $e',
        );
      }
    }
  }

  static Future<void> createNotification({
    required int targetUserId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await _postJson(
      path: '/api/notifications/',
      payload: {
        'user': targetUserId,
        'title': title,
        'body': body,
        'type': type,
        if (data != null) 'data': data,
      },
      expectedStatusCode: 201,
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

      debugPrint(
        '[NOTIFICATION_SERVICE] GET $path → ${response.statusCode}',
      );

      final decoded = _decodeBody(response.body);

      if (response.statusCode == expectedStatusCode) {
        return decoded;
      }

      debugPrint('[NOTIFICATION_SERVICE] GET error body: ${response.body}');

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

  static Future<dynamic> _postJson({
    required String path,
    required Map<String, dynamic> payload,
    required int expectedStatusCode,
  }) async {
    try {
      final uri = _uri(path);
      final headers = await _authHeaders();

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      final decoded = _decodeBody(response.body);

      debugPrint(
        '[NOTIFICATION_SERVICE] POST $path → ${response.statusCode}',
      );

      if (response.statusCode == expectedStatusCode) {
        return decoded;
      }

      debugPrint('[NOTIFICATION_SERVICE] POST error body: ${response.body}');

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

      debugPrint(
        '[NOTIFICATION_SERVICE] PATCH $path → ${response.statusCode}',
      );

      final decoded = _decodeBody(response.body);

      if (response.statusCode == expectedStatusCode) {
        return decoded;
      }

      debugPrint('[NOTIFICATION_SERVICE] PATCH error body: ${response.body}');

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