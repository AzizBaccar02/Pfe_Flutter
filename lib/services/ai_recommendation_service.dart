import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/recommended_offer_model.dart';
import 'auth_service.dart';

class AiRecommendationService {
  static const String _recommendedOffersPath =
      '/api/ai-recommendations/offers/';

  /// Default backend sort: nearest location first, then skills (semantic score).
  static const String sortLocationSkills = 'location_skills';
  static const String sortMatchScore = 'score';

  static Future<AiRecommendationsResult> fetchRecommendedOffers({
    int limit = 20,
    String sort = sortLocationSkills,
  }) async {
    final query = <String, String>{
      'limit': '$limit',
      'sort': sort,
    };

    final uri = AuthService.apiUri(_recommendedOffersPath).replace(
      queryParameters: query,
    );

    final response = await _authorizedRequest(
      requestBuilder: (headers) => http.get(uri, headers: headers),
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode == 400 ||
        response.statusCode == 403 ||
        response.statusCode == 404) {
      throw AiRecommendationException(_extractErrorMessage(decoded));
    }

    if (response.statusCode != 200) {
      throw AiRecommendationException(_extractErrorMessage(decoded));
    }

    if (decoded is! Map<String, dynamic>) {
      throw const AiRecommendationException(
        'Invalid AI recommendations response from server.',
      );
    }

    final resultsRaw = decoded['results'];
    final offers = <RecommendedOfferModel>[];

    if (resultsRaw is List) {
      for (final item in resultsRaw) {
        if (item is Map<String, dynamic>) {
          offers.add(RecommendedOfferModel.fromJson(item));
        }
      }
    }

    return AiRecommendationsResult(
      agentCity: (decoded['agentCity'] ?? '').toString().trim(),
      sortBy: (decoded['sortBy'] ?? sortLocationSkills).toString().trim(),
      offers: offers,
    );
  }

  static Future<http.Response> _authorizedRequest({
    required Future<http.Response> Function(Map<String, String> headers)
        requestBuilder,
  }) async {
    final token = await AuthService.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const AiRecommendationException(
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
        const Duration(seconds: 90),
      );
    } on TimeoutException {
      throw const AiRecommendationException(
        'AI matching took too long. Please try again in a moment.',
      );
    } on http.ClientException {
      throw const AiRecommendationException(
        'Unable to reach the server. Please make sure the backend is running.',
      );
    } on SocketException {
      throw const AiRecommendationException(
        'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (e is AiRecommendationException) rethrow;
      throw const AiRecommendationException(
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
      final detail = body['detail'];
      final message = body['message'];

      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    return 'Something went wrong. Please try again.';
  }
}

class AiRecommendationException implements Exception {
  final String message;

  const AiRecommendationException(this.message);

  bool get isProfileIncomplete {
    final lower = message.toLowerCase();
    return lower.contains('profile') &&
        (lower.contains('skills') || lower.contains('bio'));
  }

  @override
  String toString() => message;
}
