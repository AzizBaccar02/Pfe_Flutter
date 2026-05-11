import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/client_offer_model.dart';
import 'auth_service.dart';

class OfferService {
  static const String _clientOffersPath = '/api/offers/client/offers/';

  static Future<List<ClientOfferModel>> fetchMyOffers() async {
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

    if (response.statusCode != 201) {
      throw OfferException(_extractErrorMessage(decoded));
    }

    if (decoded is! Map<String, dynamic>) {
      throw const OfferException('Invalid offer response from server.');
    }

    var createdOffer = ClientOfferModel.fromJson(decoded);

    if (imagePaths.isNotEmpty && createdOffer.id > 0) {
      final uploadedImages = await uploadOfferImages(
        offerId: createdOffer.id,
        imagePaths: imagePaths,
      );

      createdOffer = createdOffer.copyWith(images: uploadedImages);
    }

    return createdOffer;
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

      if (response.statusCode != 201) {
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