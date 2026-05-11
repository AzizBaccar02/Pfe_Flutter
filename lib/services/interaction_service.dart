import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/interested_agent_model.dart';
import 'auth_service.dart';

class InteractionService {
  static const String _interestedAgentsPath =
      '/api/interactions/client/interested-agents/';

  static Future<List<InterestedAgentModel>> fetchInterestedAgents({
    int? offerId,
  }) async {
    final uri = offerId == null
        ? AuthService.apiUri(_interestedAgentsPath)
        : AuthService.apiUri(_interestedAgentsPath).replace(
            queryParameters: {
              'offer_id': offerId.toString(),
            },
          );

    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.get(
          uri,
          headers: headers,
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw InteractionException(_extractErrorMessage(decoded));
    }

    if (decoded is! List) {
      throw const InteractionException(
        'Invalid interested agents response from server.',
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(InterestedAgentModel.fromJson)
        .toList();
  }

  static Future<void> respondToReaction({
    required int reactionId,
    required bool accept,
  }) async {
    if (reactionId <= 0) {
      throw const InteractionException('Invalid reaction selected.');
    }

    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.post(
          AuthService.apiUri(
            '/api/interactions/reactions/$reactionId/respond/',
          ),
          headers: headers,
          body: jsonEncode({
            'accept': accept,
          }),
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw InteractionException(_extractErrorMessage(decoded));
    }
  }

  static Future<http.Response> _authorizedRequest({
    required Future<http.Response> Function(Map<String, String> headers)
        requestBuilder,
  }) async {
    final token = await AuthService.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const InteractionException(
        'Your session expired. Please login again.',
      );
    }

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      return await requestBuilder(headers).timeout(
        const Duration(seconds: 25),
      );
    } on TimeoutException {
      throw const InteractionException(
        'The request took too long. Please check your connection and try again.',
      );
    } on http.ClientException {
      throw const InteractionException(
        'Unable to reach the server. Please make sure the backend is running.',
      );
    } on SocketException {
      throw const InteractionException(
        'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (e is InteractionException) rethrow;

      throw const InteractionException(
        'Something went wrong. Please try again.',
      );
    }
  }

  static dynamic _decodeResponse(http.Response response) {
    if (response.body.trim().isEmpty) return null;

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
      final message = body['message'];
      final detail = body['detail'];

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }

      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
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

class InteractionException implements Exception {
  final String message;

  const InteractionException(this.message);

  @override
  String toString() => message;
}