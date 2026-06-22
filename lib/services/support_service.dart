import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../conf/api_config.dart';
import 'auth_service.dart';

class SupportService {
  static Uri _uri(String path) => ApiConfig.httpUri(path);

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getAccessToken();

    if (token == null || token.isEmpty) {
      throw const SupportServiceException('No active session found.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<String> sendSupportRequest({
    required String message,
  }) {
    return _sendFeedback(
      path: '/api/users/contact-support/',
      message: message,
      emptyMessageError: 'Please describe your issue first.',
      defaultSuccessMessage: 'Your support request has been sent successfully.',
      defaultFailureMessage: 'Unable to send your support request.',
    );
  }

  static Future<String> sendProblemReport({
    required String message,
  }) {
    return _sendFeedback(
      path: '/api/users/report-problem/',
      message: message,
      emptyMessageError: 'Please describe the problem before submitting.',
      defaultSuccessMessage: 'Your problem report has been sent successfully.',
      defaultFailureMessage: 'Unable to send your problem report.',
    );
  }

  static Future<String> _sendFeedback({
    required String path,
    required String message,
    required String emptyMessageError,
    required String defaultSuccessMessage,
    required String defaultFailureMessage,
  }) async {
    final trimmedMessage = message.trim();

    if (trimmedMessage.isEmpty) {
      throw SupportServiceException(emptyMessageError);
    }

    try {
      final response = await http
          .post(
            _uri(path),
            headers: await _authHeaders(),
            body: jsonEncode({'message': trimmedMessage}),
          )
          .timeout(const Duration(seconds: 20));

      final decoded = _decodeBody(response.body);

      if (response.statusCode == 200) {
        if (decoded is Map<String, dynamic>) {
          return (decoded['message'] ?? defaultSuccessMessage).toString();
        }

        return defaultSuccessMessage;
      }

      throw SupportServiceException(
        _extractErrorMessage(decoded, defaultFailureMessage),
      );
    } on TimeoutException {
      throw const SupportServiceException(
        'The request took too long. Please try again.',
      );
    } on http.ClientException {
      throw const SupportServiceException(
        'Unable to reach the server. Please make sure the backend is running.',
      );
    } on SupportServiceException {
      rethrow;
    } catch (_) {
      throw const SupportServiceException(
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

  static String _extractErrorMessage(
    dynamic body,
    String fallbackMessage,
  ) {
    if (body is Map<String, dynamic>) {
      final message = body['message'] ?? body['detail'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
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

    return fallbackMessage;
  }
}

class SupportServiceException implements Exception {
  final String message;

  const SupportServiceException(this.message);

  @override
  String toString() => message;
}
