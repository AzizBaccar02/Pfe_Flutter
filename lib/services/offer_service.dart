import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/agent_public_offer_model.dart';
import '../models/client_offer_model.dart';
import '../models/offer_category_model.dart';
import 'auth_service.dart';

class OfferService {
  static const String _clientOffersPath = '/api/offers/client/offers/';
  static const String _agentOffersPath = '/api/offers/agent/offers/';
  static const String _categoriesPath = '/api/offers/categories/';

  static List<ClientOfferModel>? _myOffersCache;
  static DateTime? _myOffersCachedAt;
  static Future<List<ClientOfferModel>>? _myOffersInFlight;

  static void invalidateMyOffersCache() {
    _myOffersCache = null;
    _myOffersCachedAt = null;
  }

  static Future<List<OfferCategoryModel>> fetchCategories() async {
    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.get(
          AuthService.apiUri(_categoriesPath),
          headers: headers,
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw OfferException(_extractErrorMessage(decoded));
    }

    if (decoded is! List) {
      throw const OfferException('Invalid categories response from server.');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(OfferCategoryModel.fromJson)
        .where((category) => category.name.trim().isNotEmpty)
        .toList();
  }

  static Future<OfferCategoryModel> createCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const OfferException('Category name is required.');
    }

    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.post(
          AuthService.apiUri(_categoriesPath),
          headers: headers,
          body: jsonEncode({
            'name': trimmed,
            'description': '',
          }),
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw OfferException(_extractErrorMessage(decoded));
    }

    if (decoded is! Map<String, dynamic>) {
      throw const OfferException('Invalid category response from server.');
    }

    return OfferCategoryModel.fromJson(decoded);
  }

  /// Resolves offer title for client UI (Interested deck, notifications).
  static Future<String?> resolveOfferTitle(int offerId) async {
    final media = await resolveOfferMedia(offerId);
    return media?.title;
  }

  /// Title + cover image from the client's own offers list.
  static Future<({String title, String imageUrl})?> resolveOfferMedia(
    int offerId,
  ) async {
    if (offerId <= 0) return null;

    try {
      final offers = await fetchMyOffers();
      for (final offer in offers) {
        if (offer.id != offerId) continue;

        final title = offer.title.trim();
        final imageUrl = offer.images.isNotEmpty ? offer.images.first : '';

        if (title.isEmpty && imageUrl.isEmpty) return null;

        return (
          title: title.isNotEmpty ? title : 'Your offer',
          imageUrl: imageUrl,
        );
      }
    } catch (_) {
      // Fall through.
    }

    return null;
  }

  static Future<List<ClientOfferModel>> fetchMyOffers({bool force = false}) async {
    if (!force &&
        _myOffersCache != null &&
        _myOffersCachedAt != null &&
        DateTime.now().difference(_myOffersCachedAt!) <
            const Duration(seconds: 4)) {
      return List<ClientOfferModel>.from(_myOffersCache!);
    }

    if (!force && _myOffersInFlight != null) {
      return _myOffersInFlight!;
    }

    final future = _fetchMyOffersFromNetwork();
    _myOffersInFlight = future;

    try {
      final offers = await future;
      _myOffersCache = offers;
      _myOffersCachedAt = DateTime.now();
      return List<ClientOfferModel>.from(offers);
    } finally {
      if (identical(_myOffersInFlight, future)) {
        _myOffersInFlight = null;
      }
    }
  }

  static Future<List<ClientOfferModel>> _fetchMyOffersFromNetwork() async {
    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.get(
          AuthService.apiUri(_clientOffersPath),
          headers: headers,
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw OfferException(_extractErrorMessage(decoded));
    }

    if (decoded is! List) {
      throw const OfferException('Invalid offers response from server.');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ClientOfferModel.fromJson)
        .toList();
  }

  static Future<List<AgentPublicOfferModel>> fetchAgentOffers() async {
    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.get(
          AuthService.apiUri(_agentOffersPath),
          headers: headers,
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw OfferException(_extractErrorMessage(decoded));
    }

    if (decoded is! List) {
      throw const OfferException('Invalid offers response from server.');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AgentPublicOfferModel.fromJson)
        .where((o) => o.id > 0)
        .toList();
  }

  /// Loads one public offer for the agent deck (notification deep-link / prepend).
  static Future<AgentPublicOfferModel?> fetchAgentOfferById(int offerId) async {
    if (offerId <= 0) return null;

    final paths = [
      '$_agentOffersPath$offerId/',
      '/api/offers/$offerId/',
      '/api/offers/offers/$offerId/',
    ];

    for (final path in paths) {
      try {
        final response = await _authorizedRequest(
          requestBuilder: (headers) {
            return http.get(
              AuthService.apiUri(path),
              headers: headers,
            );
          },
        );

        final decoded = _decodeResponse(response);
        if (response.statusCode != 200) continue;

        if (decoded is Map<String, dynamic>) {
          final offer = AgentPublicOfferModel.fromJson(decoded);
          if (offer.id > 0) return offer;
        }
      } on OfferException {
        continue;
      }
    }

    try {
      final all = await fetchAgentOffers();
      for (final offer in all) {
        if (offer.id == offerId) return offer;
      }
    } catch (_) {
      // Fall through.
    }

    return null;
  }

  static Future<ClientOfferModel> createOffer({
    required String title,
    required String description,
    required double budget,
    required String category,
    required String city,
    required String address,
    required String postalCode,
    List<String> imagePaths = const [],
  }) async {
    final payload = {
      'title': title.trim(),
      'description': description.trim(),
      'budget': budget,
      'categoryName': category.trim(),
      'city': city.trim(),
      'address': address.trim(),
      'postalCode': postalCode.trim(),
    };

    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.post(
          AuthService.apiUri(_clientOffersPath),
          headers: headers,
          body: jsonEncode(payload),
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw OfferException(_extractErrorMessage(decoded));
    }

    final offerJson = _extractOfferJson(decoded);
    if (offerJson == null) {
      throw const OfferException('Invalid offer response from server.');
    }

    var createdOffer = ClientOfferModel.fromJson(offerJson);
    invalidateMyOffersCache();

    if (imagePaths.isNotEmpty && createdOffer.id > 0) {
      try {
        final uploadedImages = await uploadOfferImages(
          offerId: createdOffer.id,
          imagePaths: imagePaths,
        );

        createdOffer = createdOffer.copyWith(images: uploadedImages);
      } on OfferException catch (e) {
        throw OfferPartialCreateException(
          offer: createdOffer,
          imageError: _friendlyImageUploadError(e.message),
        );
      }
    }

    return createdOffer;
  }

  static String _friendlyImageUploadError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('integrityerror') ||
        lower.contains('already exists') ||
        lower.contains('duplicate key')) {
      return 'Images could not be saved (server database sequence). '
          'Restart Django and run: python manage.py migrate offers';
    }
    if (raw.trim().isEmpty ||
        raw.contains('<!DOCTYPE html>') ||
        raw.contains('IntegrityError')) {
      return 'Images could not be uploaded. The offer was still created.';
    }
    return raw;
  }

  static Future<ClientOfferModel> updateOffer({
    required int offerId,
    required String title,
    required String description,
    required double budget,
    required String category,
    required String city,
    required String address,
    required String postalCode,
    required OfferStatus status,
  }) async {
    final payload = {
      'title': title.trim(),
      'description': description.trim(),
      'budget': budget,
      'categoryName': category.trim(),
      'city': city.trim(),
      'address': address.trim(),
      'postalCode': postalCode.trim(),
      'status': offerStatusToApi(status),
    };

    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.patch(
          AuthService.apiUri('$_clientOffersPath$offerId/'),
          headers: headers,
          body: jsonEncode(payload),
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw OfferException(_extractErrorMessage(decoded));
    }

    if (decoded is! Map<String, dynamic>) {
      throw const OfferException('Invalid update response from server.');
    }

    return ClientOfferModel.fromJson(decoded);
  }

  static Future<ClientOfferModel> updateOfferStatus({
    required int offerId,
    required OfferStatus status,
  }) async {
    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.patch(
          AuthService.apiUri('$_clientOffersPath$offerId/status/'),
          headers: headers,
          body: jsonEncode({
            'status': offerStatusToApi(status),
          }),
        );
      },
    );

    final decoded = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw OfferException(_extractErrorMessage(decoded));
    }

    if (decoded is! Map<String, dynamic>) {
      throw const OfferException('Invalid status response from server.');
    }

    return ClientOfferModel.fromJson(decoded);
  }

  static Future<void> deleteOffer({
    required int offerId,
  }) async {
    final response = await _authorizedRequest(
      requestBuilder: (headers) {
        return http.delete(
          AuthService.apiUri('$_clientOffersPath$offerId/'),
          headers: headers,
        );
      },
    );

    if (response.statusCode != 204) {
      final decoded = _decodeResponse(response);
      throw OfferException(_extractErrorMessage(decoded));
    }
  }

  static Future<List<String>> uploadOfferImages({
    required int offerId,
    required List<String> imagePaths,
  }) async {
    if (imagePaths.isEmpty) return [];

    final token = await AuthService.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const OfferException('Your session expired. Please login again.');
    }

    final request = http.MultipartRequest(
      'POST',
      AuthService.apiUri('$_clientOffersPath$offerId/images/'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    for (final imagePath in imagePaths) {
      final file = File(imagePath);

      if (!await file.exists()) {
        continue;
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          file.path,
        ),
      );
    }

    if (request.files.isEmpty) {
      return [];
    }

    try {
      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 35),
          );

      final response = await http.Response.fromStream(streamedResponse);
      final decoded = _decodeResponse(response);

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw OfferException(_extractErrorMessage(decoded));
      }

      if (decoded is! List) {
        throw const OfferException('Invalid image upload response.');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map((image) => image['url']?.toString() ?? '')
          .where((url) => url.trim().isNotEmpty)
          .toList();
    } on TimeoutException {
      throw const OfferException(
        'The image upload took too long. Please try again.',
      );
    } on http.ClientException {
      throw const OfferException(
        'Unable to reach the server. Please make sure the backend is running.',
      );
    } on SocketException {
      throw const OfferException(
        'No internet connection. Please check your network.',
      );
    }
  }

  static Future<http.Response> _authorizedRequest({
    required Future<http.Response> Function(Map<String, String> headers)
        requestBuilder,
  }) async {
    final token = await AuthService.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw const OfferException('Your session expired. Please login again.');
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
      throw const OfferException(
        'The request took too long. Please check your connection and try again.',
      );
    } on http.ClientException {
      throw const OfferException(
        'Unable to reach the server. Please make sure the backend is running.',
      );
    } on SocketException {
      throw const OfferException(
        'No internet connection. Please check your network.',
      );
    } catch (e) {
      if (e is OfferException) rethrow;

      throw const OfferException(
        'Something went wrong. Please try again.',
      );
    }
  }

  static Map<String, dynamic>? _extractOfferJson(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final nested = decoded['offer'] ?? decoded['data'] ?? decoded['result'];
      if (nested is Map<String, dynamic>) return nested;
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return decoded;
    }

    return null;
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
      final text = body.trim();
      if (text.contains('IntegrityError') || text.contains('already exists')) {
        return 'Database error while saving images. Please contact support or retry.';
      }
      if (text.length > 280 || text.contains('<!DOCTYPE html>')) {
        return 'Server error. Please try again.';
      }
      return text;
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

        if (value is Map && value.isNotEmpty) {
          return value.values.first.toString();
        }
      }
    }

    return 'Something went wrong. Please try again.';
  }
}

class OfferException implements Exception {
  final String message;

  const OfferException(this.message);

  @override
  String toString() => message;
}

/// Offer row was created but optional image upload failed.
class OfferPartialCreateException implements Exception {
  final ClientOfferModel offer;
  final String imageError;

  const OfferPartialCreateException({
    required this.offer,
    required this.imageError,
  });

  @override
  String toString() => imageError;
}
