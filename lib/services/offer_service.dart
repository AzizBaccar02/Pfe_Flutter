// lib/services/offer_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/offer_interaction_model.dart';
import 'auth_service.dart';
import 'profile_service.dart';

class OfferService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getAccessToken();

    if (token == null || token.isEmpty) {
      throw const OfferServiceException('No active session found.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Loads offers the agent can browse / react to.
  static Future<List<BrowseOfferModel>> getBrowseOffers() async {
    final candidates = [
      '/api/offres/',
      '/api/offres/browse/',
      '/api/offers/',
      '/api/offers/browse/',
      '/api/interactions/offers/browse/',
    ];

    for (final path in candidates) {
      try {
        final decoded = await _getJson(path: path, expectedStatusCode: 200);
        final list = _extractList(decoded);

        if (list.isEmpty) continue;

        final offers = list
            .map(
              (item) => BrowseOfferModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((offer) => offer.id > 0)
            .toList();

        if (offers.isNotEmpty) {
          debugPrint(
            '[OFFER_SERVICE] Loaded ${offers.length} offers from $path',
          );
          return offers;
        }
      } catch (e) {
        debugPrint('[OFFER_SERVICE] GET $path failed: $e');
      }
    }

    return [];
  }

  /// Offers owned by the logged-in client.
  static Future<List<BrowseOfferModel>> getClientOffers() async {
    final candidates = [
      '/api/offres/my/',
      '/api/offres/me/',
      '/api/offres/client/',
      '/api/offers/my/',
      '/api/offers/me/',
    ];

    for (final path in candidates) {
      try {
        final decoded = await _getJson(path: path, expectedStatusCode: 200);
        final list = _extractList(decoded);

        final offers = list
            .map(
              (item) => BrowseOfferModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((offer) => offer.id > 0)
            .toList();

        if (offers.isNotEmpty) {
          debugPrint(
            '[OFFER_SERVICE] ${offers.length} client offers from $path',
          );
          return offers;
        }
      } catch (e) {
        debugPrint('[OFFER_SERVICE] GET $path failed: $e');
      }
    }

    return [];
  }

  static List<Map<dynamic, dynamic>> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded.whereType<Map>().map(Map<dynamic, dynamic>.from).toList();
    }

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      for (final key in ['results', 'offers', 'offres', 'data', 'items']) {
        final nested = map[key];
        if (nested is List) {
          return nested
              .whereType<Map>()
              .map(Map<dynamic, dynamic>.from)
              .toList();
        }
      }
    }

    return [];
  }

  static Future<dynamic> _getJson({
    required String path,
    required int expectedStatusCode,
  }) async {
    try {
      final uri = _uri(path);
      final headers = await _authHeaders();
      final response =
          await http.get(uri, headers: headers).timeout(const Duration(seconds: 20));

      debugPrint('[OFFER_SERVICE] GET $path → ${response.statusCode}');

      final decoded = _decodeBody(response.body);

      if (response.statusCode == expectedStatusCode) return decoded;

      throw OfferServiceException(_extractErrorMessage(decoded));
    } on TimeoutException {
      throw const OfferServiceException('Request timed out.');
    } on http.ClientException {
      throw const OfferServiceException('Unable to reach the server.');
    } catch (e) {
      if (e is OfferServiceException) rethrow;
      throw const OfferServiceException('Something went wrong.');
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
    }
    return 'Something went wrong.';
  }

  static String resolveImageUrl(String raw) {
    return ProfileService.resolveMediaUrl(raw) ?? raw;
  }
}

class OfferServiceException implements Exception {
  final String message;

  const OfferServiceException(this.message);

  @override
  String toString() => message;
}
