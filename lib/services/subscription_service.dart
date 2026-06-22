import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/subscription_model.dart';
import '../models/subscription_plan_model.dart';
import 'auth_service.dart';

class SubscriptionService {
  static const String _plansPath = '/api/subscriptions/plans/';
  static const String _mePath = '/api/subscriptions/me/';
  static const String _checkoutPath =
      '/api/subscriptions/create-checkout-session/';
  static const String _portalPath = '/api/subscriptions/create-portal-session/';
  static const String _confirmCheckoutPath =
      '/api/subscriptions/confirm-checkout-session/';
  static const String _syncPath = '/api/subscriptions/sync/';

  static Future<List<SubscriptionPlanModel>> fetchPlans() async {
    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.get(
          AuthService.apiUri(_plansPath),
          headers: headers,
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw SubscriptionException(_extractErrorMessage(decoded));
    }

    if (decoded is! List) {
      throw const SubscriptionException('Invalid plans response from server.');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionPlanModel.fromJson)
        .where((plan) => plan.id > 0)
        .toList();
  }

  static Future<MySubscriptionModel> fetchMySubscription() async {
    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.get(
          AuthService.apiUri(_mePath),
          headers: headers,
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw SubscriptionException(_extractErrorMessage(decoded));
    }

    if (decoded is! Map<String, dynamic>) {
      throw const SubscriptionException(
        'Invalid subscription response from server.',
      );
    }

    return MySubscriptionModel.fromJson(decoded);
  }

  static Future<CheckoutSessionResult> createCheckoutSession({
    required int planId,
  }) async {
    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.post(
          AuthService.apiUri(_checkoutPath),
          headers: headers,
          body: jsonEncode({'planId': planId}),
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw SubscriptionException(_extractErrorMessage(decoded));
    }

    if (decoded is! Map<String, dynamic>) {
      throw const SubscriptionException('Invalid checkout response from server.');
    }

    final checkoutUrl = decoded['checkoutUrl']?.toString().trim() ?? '';
    final sessionId = decoded['sessionId']?.toString().trim() ?? '';

    if (checkoutUrl.isEmpty) {
      throw const SubscriptionException('Checkout URL was not returned.');
    }

    return CheckoutSessionResult(
      checkoutUrl: checkoutUrl,
      sessionId: sessionId,
    );
  }

  /// Pulls the latest paid subscription state from Stripe (fixes INCOMPLETE rows).
  static Future<MySubscriptionModel> syncSubscription() async {
    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.post(
          AuthService.apiUri(_syncPath),
          headers: headers,
          body: jsonEncode({}),
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw SubscriptionException(_extractErrorMessage(decoded));
    }

    if (decoded is! Map<String, dynamic>) {
      throw const SubscriptionException(
        'Invalid subscription sync response from server.',
      );
    }

    return MySubscriptionModel.fromJson(decoded);
  }

  /// Activates subscription from Stripe after checkout (needed when webhooks
  /// cannot reach localhost). Omit [sessionId] to use the stored checkout id.
  static Future<MySubscriptionModel> confirmCheckoutSession({
    String? sessionId,
  }) async {
    final body = <String, dynamic>{};
    final trimmedSessionId = sessionId?.trim() ?? '';

    if (trimmedSessionId.isNotEmpty) {
      body['sessionId'] = trimmedSessionId;
    }

    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.post(
          AuthService.apiUri(_confirmCheckoutPath),
          headers: headers,
          body: jsonEncode(body),
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw SubscriptionException(_extractErrorMessage(decoded));
    }

    if (decoded is! Map<String, dynamic>) {
      throw const SubscriptionException(
        'Invalid subscription confirmation response from server.',
      );
    }

    return MySubscriptionModel.fromJson(decoded);
  }

  static Future<String> createPortalSession() async {
    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.post(
          AuthService.apiUri(_portalPath),
          headers: headers,
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw SubscriptionException(_extractErrorMessage(decoded));
    }

    if (decoded is! Map<String, dynamic>) {
      throw const SubscriptionException('Invalid portal response from server.');
    }

    final portalUrl = decoded['portalUrl']?.toString().trim() ?? '';

    if (portalUrl.isEmpty) {
      throw const SubscriptionException('Portal URL was not returned.');
    }

    return portalUrl;
  }

  static Future<http.Response> _authorizedRequest({
    required Future<http.Response> Function(Map<String, String> headers)
        requestBuilder,
  }) async {
    final token = await AuthService.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const SubscriptionException(
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
      throw const SubscriptionException(
        'The request took too long. Please check your connection and try again.',
      );
    } on http.ClientException {
      throw const SubscriptionException(
        'Unable to reach the server. Please make sure the backend is running.',
      );
    } on SocketException {
      throw const SubscriptionException(
        'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (e is SubscriptionException) rethrow;

      throw const SubscriptionException(
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
    }

    return 'Something went wrong. Please try again.';
  }
}

class CheckoutSessionResult {
  final String checkoutUrl;
  final String sessionId;

  const CheckoutSessionResult({
    required this.checkoutUrl,
    required this.sessionId,
  });
}

class SubscriptionException implements Exception {
  final String message;

  const SubscriptionException(this.message);

  @override
  String toString() => message;
}
