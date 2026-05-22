// lib/services/interaction_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/offer_interaction_model.dart';
import 'auth_service.dart';

class InteractionService {
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
      throw const InteractionServiceException('No active session found.');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Matches Postman: POST /api/interactions/offers/{offerId}/react/
  static Future<OfferInteractionModel> reactToOffer({
    required int offerId,
    required bool react,
    String message = 'I am interested in this offer.',
    double? proposedPrice,
  }) async {
    final decoded = await _postJson(
      path: '/api/interactions/offers/$offerId/react/',
      payload: {
        'react': react,
        'message': message,
        if (proposedPrice != null) 'proposedPrice': proposedPrice,
      },
      expectedStatusCodes: const [201],
    );

    if (decoded is! Map<String, dynamic>) {
      throw const InteractionServiceException('Invalid react response.');
    }

    debugPrint('[INTERACTION_SERVICE] react ok: $decoded');

    return OfferInteractionModel.fromJson(decoded);
  }

  /// Pending agent interests for a client's offer.
  static Future<List<OfferInteractionModel>> getPendingForOffer(
    int offerId,
  ) async {
    final paths = _offerInteractionListPaths(offerId);
    final merged = await _fetchFromPaths(paths);

    final forOffer = merged
        .where((item) => item.offerId == offerId || item.offerId == 0)
        .where(_isPendingInterest)
        .toList();

    if (forOffer.isNotEmpty) {
      debugPrint(
        '[INTERACTION_SERVICE] ${forOffer.length} pending for offer $offerId',
      );
      return _dedupeInteractions(forOffer);
    }

    // Fallback: client-wide pending then filter by offer id.
    final clientWide = await getClientPendingInteractions();
    final filtered = clientWide
        .where((item) => item.offerId == offerId)
        .where(_isPendingInterest)
        .toList();

    if (filtered.isNotEmpty) {
      debugPrint(
        '[INTERACTION_SERVICE] ${filtered.length} pending for offer $offerId (client list)',
      );
    }

    return _dedupeInteractions(filtered);
  }

  /// All pending interests for the logged-in client.
  /// Single interaction detail (nested `agent` object when backend supports it).
  static Future<OfferInteractionModel?> getInteractionById(int interactionId) async {
    if (interactionId <= 0) return null;

    final paths = [
      '/api/interactions/$interactionId/',
      '/api/interactions/interactions/$interactionId/',
    ];

    for (final path in paths) {
      try {
        final decoded = await _getJson(
          path: path,
          expectedStatusCodes: const [200],
        );

        if (decoded is Map<String, dynamic>) {
          return OfferInteractionModel.fromJson(decoded);
        }
      } on InteractionServiceException catch (e) {
        debugPrint(
          '[INTERACTION_SERVICE] GET $path failed: ${e.message}',
        );
      } catch (e) {
        debugPrint('[INTERACTION_SERVICE] GET $path failed: $e');
      }
    }

    return null;
  }

  static Future<List<OfferInteractionModel>> getClientPendingInteractions() async {
    const paths = [
      '/api/interactions/client/pending/',
      '/api/interactions/client/interactions/pending/',
      '/api/interactions/client/interactions/',
      '/api/interactions/client/offres/pending/',
      '/api/interactions/pending/',
      '/api/interactions/me/pending/',
      '/api/interactions/me/',
      '/api/interactions/',
    ];

    final merged = await _fetchFromPaths(paths);
    final pending = merged.where(_isPendingInterest).toList();

    if (pending.isNotEmpty) {
      debugPrint(
        '[INTERACTION_SERVICE] ${pending.length} client-wide pending',
      );
    }

    return _dedupeInteractions(pending);
  }

  static List<String> _offerInteractionListPaths(int offerId) {
    return [
      '/api/interactions/offers/$offerId/interactions/',
      '/api/interactions/offers/$offerId/pending/',
      '/api/interactions/offres/$offerId/interactions/',
      '/api/interactions/offres/$offerId/pending/',
      '/api/interactions/client/offers/$offerId/pending/',
      '/api/interactions/client/offers/$offerId/interactions/',
      '/api/interactions/client/offres/$offerId/pending/',
      '/api/interactions/client/offres/$offerId/interactions/',
      '/api/interactions/?offre=$offerId',
      '/api/interactions/?offer=$offerId',
      '/api/interactions/?offer_id=$offerId',
      '/api/interactions/?offre_id=$offerId',
    ];
  }

  static Future<List<OfferInteractionModel>> _fetchFromPaths(
    List<String> paths,
  ) async {
    final merged = <int, OfferInteractionModel>{};

    for (final path in paths) {
      try {
        final items = await _tryFetchList(path);
        for (final item in items) {
          final key = item.id > 0 ? item.id : item.hashCode;
          merged[key] = item;
        }

        if (items.isNotEmpty) {
          debugPrint(
            '[INTERACTION_SERVICE] loaded ${items.length} from $path',
          );
        }
      } on InteractionServiceException catch (e) {
        debugPrint('[INTERACTION_SERVICE] GET $path failed: ${e.message}');
      } catch (e) {
        debugPrint('[INTERACTION_SERVICE] GET $path failed: $e');
      }
    }

    return merged.values.toList();
  }

  static Future<List<OfferInteractionModel>> _tryFetchList(String path) async {
    final decoded = await _getJson(
      path: path,
      expectedStatusCodes: const [200, 201],
    );

    final list = _extractList(decoded);

    return list
        .map(
          (item) => OfferInteractionModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  static bool _isPendingInterest(OfferInteractionModel item) {
    final status = item.status.trim().toUpperCase();
    if (status == 'PENDING') return true;
    if (status.isEmpty && item.react) return true;
    return false;
  }

  static OfferInteractionModel _syntheticResponse(
    int interactionId,
    String status,
  ) {
    return OfferInteractionModel(
      id: interactionId,
      offerId: 0,
      offerTitle: '',
      agentId: 0,
      message: '',
      status: status,
      react: true,
    );
  }

  static List<OfferInteractionModel> _dedupeInteractions(
    List<OfferInteractionModel> items,
  ) {
    final map = <int, OfferInteractionModel>{};

    for (final item in items) {
      if (item.id > 0) {
        map[item.id] = item;
      }
    }

    if (map.isNotEmpty) return map.values.toList();
    return items;
  }

  static Future<OfferInteractionModel> respondToInteraction({
    required int interactionId,
    required bool accept,
    int? offerId,
  }) async {
    final statusValue = accept ? 'ACCEPTED' : 'REJECTED';
    const okCodes = [200, 201, 204];
    Object? lastError;

    OfferInteractionModel? fromDecoded(dynamic decoded) {
      if (decoded is Map<String, dynamic>) {
        return OfferInteractionModel.fromJson(decoded);
      }
      return _syntheticResponse(interactionId, statusValue);
    }

    Future<OfferInteractionModel?> tryPost(
      String path,
      Map<String, dynamic> payload,
    ) async {
      try {
        final decoded = await _postJson(
          path: path,
          payload: payload,
          expectedStatusCodes: okCodes,
        );
        return fromDecoded(decoded);
      } catch (e) {
        lastError = e;
        return null;
      }
    }

    Future<OfferInteractionModel?> tryPatch(
      String path,
      Map<String, dynamic> payload,
    ) async {
      try {
        final decoded = await _patchJson(
          path: path,
          payload: payload,
          expectedStatusCodes: okCodes,
        );
        return fromDecoded(decoded);
      } catch (e) {
        lastError = e;
        return null;
      }
    }

    final postPaths = <String>[
      if (accept) ...[
        '/api/interactions/$interactionId/accept/',
        '/api/interactions/interactions/$interactionId/accept/',
        '/api/interactions/$interactionId/respond/',
      ] else ...[
        '/api/interactions/$interactionId/reject/',
        '/api/interactions/interactions/$interactionId/reject/',
        '/api/interactions/$interactionId/decline/',
      ],
      if (offerId != null && offerId > 0) ...[
        if (accept) ...[
          '/api/interactions/offers/$offerId/interactions/$interactionId/accept/',
          '/api/interactions/offres/$offerId/interactions/$interactionId/accept/',
        ] else ...[
          '/api/interactions/offers/$offerId/interactions/$interactionId/reject/',
          '/api/interactions/offres/$offerId/interactions/$interactionId/reject/',
        ],
      ],
    ];

    final postPayloads = <Map<String, dynamic>>[
      if (accept)
        {'accept': true, 'status': statusValue}
      else
        {'accept': false, 'status': statusValue},
      {'status': statusValue},
      const {},
    ];

    for (final path in postPaths) {
      for (final payload in postPayloads) {
        final result = await tryPost(path, payload);
        if (result != null) return result;
      }
    }

    final patchPaths = [
      '/api/interactions/$interactionId/',
      '/api/interactions/interactions/$interactionId/',
    ];

    final patchPayloads = <Map<String, dynamic>>[
      {'status': statusValue},
      {'status': statusValue.toLowerCase()},
      if (accept) {'accept': true} else {'accept': false},
    ];

    for (final path in patchPaths) {
      for (final payload in patchPayloads) {
        final result = await tryPatch(path, payload);
        if (result != null) return result;
      }
    }

    if (lastError is InteractionServiceException) {
      final msg = (lastError as InteractionServiceException).message;
      if (msg.contains('404')) {
        throw InteractionServiceException(
          accept
              ? 'Accept failed: server has no accept endpoint yet. '
                  'Add POST /api/interactions/$interactionId/accept/ in Django '
                  '(see django_interactions_patches/accept_reject_views.py).'
              : 'Decline failed: server has no reject endpoint yet. '
                  'Add POST /api/interactions/$interactionId/reject/ in Django '
                  '(see django_interactions_patches/accept_reject_views.py).',
        );
      }
      throw lastError as InteractionServiceException;
    }

    throw InteractionServiceException(
      accept
          ? 'Unable to accept this interest.'
          : 'Unable to decline this interest.',
    );
  }

  static List<Map<dynamic, dynamic>> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded.whereType<Map>().map(Map<dynamic, dynamic>.from).toList();
    }

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);

      for (final key in [
        'results',
        'interactions',
        'data',
        'items',
        'pending',
      ]) {
        final nested = map[key];
        if (nested is List) {
          return nested
              .whereType<Map>()
              .map(Map<dynamic, dynamic>.from)
              .toList();
        }
      }

      // Single interaction object wrapped in a map.
      if (map.containsKey('id')) {
        return [map];
      }
    }

    return [];
  }

  static Future<dynamic> _getJson({
    required String path,
    required List<int> expectedStatusCodes,
  }) async {
    try {
      final uri = _uri(path);
      final headers = await _authHeaders();
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));

      debugPrint(
        '[INTERACTION_SERVICE] GET $path → ${response.statusCode}',
      );

      if (response.statusCode == 404) {
        throw InteractionServiceException('Not found ($path)');
      }

      final decoded = _decodeBody(response.body);

      if (expectedStatusCodes.contains(response.statusCode)) {
        return decoded;
      }

      final snippet = response.body.length > 280
          ? '${response.body.substring(0, 280)}...'
          : response.body;

      debugPrint('[INTERACTION_SERVICE] GET error body: $snippet');

      throw InteractionServiceException(
        _extractErrorMessage(decoded, response.statusCode),
      );
    } on TimeoutException {
      throw const InteractionServiceException('Request timed out.');
    } on http.ClientException {
      throw const InteractionServiceException('Unable to reach the server.');
    } on InteractionServiceException {
      rethrow;
    } catch (e) {
      throw InteractionServiceException('GET failed: $e');
    }
  }

  static Future<dynamic> _patchJson({
    required String path,
    required Map<String, dynamic> payload,
    required List<int> expectedStatusCodes,
  }) async {
    try {
      final uri = _uri(path);
      final headers = await _authHeaders();
      final response = await http
          .patch(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));

      debugPrint(
        '[INTERACTION_SERVICE] PATCH $path → ${response.statusCode}',
      );

      final decoded = _decodeBody(response.body);

      if (expectedStatusCodes.contains(response.statusCode)) {
        return decoded;
      }

      throw InteractionServiceException(
        _extractErrorMessage(decoded, response.statusCode),
      );
    } on TimeoutException {
      throw const InteractionServiceException('Request timed out.');
    } on http.ClientException {
      throw const InteractionServiceException('Unable to reach the server.');
    } on InteractionServiceException {
      rethrow;
    } catch (e) {
      throw InteractionServiceException('PATCH failed: $e');
    }
  }

  static Future<dynamic> _postJson({
    required String path,
    required Map<String, dynamic> payload,
    required List<int> expectedStatusCodes,
  }) async {
    try {
      final uri = _uri(path);
      final headers = await _authHeaders();
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 20));

      debugPrint(
        '[INTERACTION_SERVICE] POST $path → ${response.statusCode}',
      );

      if (response.statusCode != expectedStatusCodes.first &&
          !expectedStatusCodes.contains(response.statusCode)) {
        final snippet = response.body.length > 280
            ? '${response.body.substring(0, 280)}...'
            : response.body;
        debugPrint('[INTERACTION_SERVICE] POST body: $snippet');
      }

      final decoded = _decodeBody(response.body);

      if (expectedStatusCodes.contains(response.statusCode)) {
        return decoded;
      }

      throw InteractionServiceException(
        _extractErrorMessage(decoded, response.statusCode),
      );
    } on TimeoutException {
      throw const InteractionServiceException('Request timed out.');
    } on http.ClientException {
      throw const InteractionServiceException('Unable to reach the server.');
    } on InteractionServiceException {
      rethrow;
    } catch (e) {
      throw InteractionServiceException('POST failed: $e');
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

  static String _extractErrorMessage(dynamic body, int statusCode) {
    if (body is Map<String, dynamic>) {
      if (body['error'] != null) return body['error'].toString();
      if (body['detail'] != null) return body['detail'].toString();
      if (body['message'] != null) return body['message'].toString();

      final errors = body['errors'];
      if (errors != null) return errors.toString();
    }

    if (body is String && body.trim().isNotEmpty) {
      return body;
    }

    return 'HTTP $statusCode';
  }
}

class InteractionServiceException implements Exception {
  final String message;

  const InteractionServiceException(this.message);

  @override
  String toString() => message;
}
