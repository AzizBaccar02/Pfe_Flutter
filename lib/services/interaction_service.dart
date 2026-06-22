// lib/services/interaction_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../conf/api_config.dart';
import '../models/agent_my_reaction_model.dart';
import '../models/interested_agent_model.dart';
import '../models/offer_interaction_model.dart';
import 'auth_service.dart';
import 'client_interaction_state_service.dart';
import 'client_match_persistence.dart';

class InteractionService {
  static Uri _uri(String path) => ApiConfig.httpUri(path);

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

  /// Pending agent interests for one of the client's offers.
  static Future<List<OfferInteractionModel>> getPendingForOffer(
    int offerId,
  ) async {
    final agents = await fetchInterestedAgents(offerId: offerId);
    return agents.map(_interactionFromInterestedAgent).toList();
  }

  /// Reaction detail for notifications / profile enrichment.
  ///
  /// Uses Django client lookup (`/api/interactions/client/reaction/`) or
  /// agent `my-reactions` list — not `GET /api/interactions/{id}/`.
  static Future<OfferInteractionModel?> getInteractionById(int interactionId) async {
    if (interactionId <= 0) return null;

    if (await AuthService.isClientRole()) {
      return lookupClientReaction(reactionId: interactionId);
    }

    if (await AuthService.isAgentRole()) {
      final reactions = await fetchMyOfferReactions();
      for (final reaction in reactions) {
        if (reaction.id == interactionId) {
          return OfferInteractionModel(
            id: reaction.id,
            offerId: reaction.offerId,
            offerTitle: reaction.offerTitle,
            agentId: 0,
            message: reaction.message,
            status: reaction.status,
            react: reaction.react,
          );
        }
      }
    }

    return null;
  }

  static Future<List<OfferInteractionModel>> getClientPendingInteractions() async {
    final agents = await fetchInterestedAgents();
    return agents.map(_interactionFromInterestedAgent).toList();
  }

  /// GET /api/interactions/client/reactions/ — all reactions (any status).
  static Future<List<OfferInteractionModel>> fetchClientReactions({
    int? offerId,
    String? status,
  }) async {
    if (!await AuthService.isClientRole()) return const [];

    final params = <String>[];
    if (offerId != null && offerId > 0) {
      params.add('offer_id=$offerId');
    }
    if (status != null && status.trim().isNotEmpty) {
      params.add('status=${Uri.encodeComponent(status.trim())}');
    }

    var path = '/api/interactions/client/reactions/';
    if (params.isNotEmpty) {
      path = '$path?${params.join('&')}';
    }

    try {
      final decoded = await _getJson(
        path: path,
        expectedStatusCodes: const [200],
      );

      final list = _extractList(decoded);
      return list
          .map(
            (item) => _interactionFromInterestedAgent(
              InterestedAgentModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            ),
          )
          .where((item) => item.agentId > 0)
          .toList();
    } on InteractionServiceException catch (e) {
      debugPrint('[INTERACTION_SERVICE] fetchClientReactions: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('[INTERACTION_SERVICE] fetchClientReactions: $e');
      return [];
    }
  }

  /// Lookup a reaction for the logged-in client (pending, accepted, or rejected).
  static Future<OfferInteractionModel?> lookupClientReaction({
    int? reactionId,
    int? offerId,
    int? agentId,
  }) async {
    if (!await AuthService.isClientRole()) return null;

    final params = <String, String>{};

    if (reactionId != null && reactionId > 0) {
      params['reaction_id'] = '$reactionId';
    } else if (offerId != null &&
        offerId > 0 &&
        agentId != null &&
        agentId > 0) {
      params['offer_id'] = '$offerId';
      params['agent_id'] = '$agentId';
    } else {
      return null;
    }

    final query = params.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    try {
      final decoded = await _getJson(
        path: '/api/interactions/client/reaction/?$query',
        expectedStatusCodes: const [200],
      );

      if (decoded is! Map<String, dynamic>) return null;

      final agent = InterestedAgentModel.fromJson(decoded);
      if (agent.reactionId <= 0 && agent.id <= 0) return null;

      return _interactionFromInterestedAgent(agent);
    } on InteractionServiceException catch (e) {
      debugPrint('[INTERACTION_SERVICE] lookupClientReaction: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[INTERACTION_SERVICE] lookupClientReaction: $e');
      return null;
    }
  }

  /// GET /api/interactions/client/interested-agents/?offer_id= (optional).
  static Future<List<InterestedAgentModel>> fetchInterestedAgents({
    int? offerId,
  }) async {
    if (!await AuthService.isClientRole()) {
      debugPrint(
        '[INTERACTION_SERVICE] fetchInterestedAgents skipped: role is not CLIENT',
      );
      return const [];
    }

    var path = '/api/interactions/client/interested-agents/';
    if (offerId != null && offerId > 0) {
      path = '$path?offer_id=$offerId';
    }

    List<InterestedAgentModel> results = const [];

    try {
      final decoded = await _getJson(
        path: path,
        expectedStatusCodes: const [200],
      );
      results = _parseInterestedAgentList(decoded);
      debugPrint(
        '[INTERACTION_SERVICE] ${results.length} pending interested agents from $path',
      );
    } on InteractionServiceException catch (e) {
      debugPrint(
        '[INTERACTION_SERVICE] interested-agents failed ($path): ${e.message}',
      );
    }

    final fromReactions = await _fetchPendingAgentsFromReactionsEndpoint(
      offerId: offerId,
    );
    if (fromReactions.isNotEmpty) {
      debugPrint(
        '[INTERACTION_SERVICE] ${fromReactions.length} pending from client/reactions',
      );
    }

    return _dedupeInterestedAgents([...results, ...fromReactions]);
  }

  static List<InterestedAgentModel> _parseInterestedAgentList(dynamic decoded) {
    final list = _extractList(decoded);

    final agents = list
        .map(
          (item) => InterestedAgentModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where(_isValidInterestedAgent)
        .where((agent) => _isPendingStatus(agent.status))
        .toList();

    return _dedupeInterestedAgents(agents);
  }

  static bool _isValidInterestedAgent(InterestedAgentModel agent) {
    if (agent.reactionId > 0) return true;
    return agent.id > 0 && agent.offerId > 0;
  }

  static Future<List<InterestedAgentModel>> _fetchPendingAgentsFromReactionsEndpoint({
    int? offerId,
  }) async {
    try {
      final interactions = await fetchClientReactions(
        offerId: offerId,
        status: 'PENDING',
      );

      final agents = interactions
          .where((item) => _isPendingStatus(item.status))
          .where((item) => item.id > 0 && item.agentId > 0)
          .map(InterestedAgentModel.fromInteraction)
          .toList();

      return _dedupeInterestedAgents(agents);
    } catch (e) {
      debugPrint('[INTERACTION_SERVICE] reactions fallback failed: $e');
      return const [];
    }
  }

  static List<InterestedAgentModel> _dedupeInterestedAgents(
    List<InterestedAgentModel> agents,
  ) {
    final uniqueByReaction = <String, InterestedAgentModel>{};
    for (final agent in agents) {
      final key = agent.reactionId > 0
          ? 'reaction:${agent.reactionId}'
          : 'fallback:${agent.id}:${agent.offerId}:${agent.createdAt?.toIso8601String() ?? ''}';
      uniqueByReaction[key] = agent;
    }

    return uniqueByReaction.values.toList()
      ..sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;
        if (ad != null && bd != null) {
          final byDate = bd.compareTo(ad);
          if (byDate != 0) return byDate;
        } else if (ad != null) {
          return -1;
        } else if (bd != null) {
          return 1;
        }
        return b.reactionId.compareTo(a.reactionId);
      });
  }

  static bool _isMatchedStatus(InterestedAgentModel agent) {
    final normalized = agent.status.trim().toUpperCase();
    return normalized == 'ACCEPTED' || normalized == 'MATCHED';
  }

  static bool _isPendingStatus(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized.isEmpty) return false;

    const resolved = {'ACCEPTED', 'REJECTED', 'MATCHED', 'DECLINED'};
    if (resolved.contains(normalized)) return false;

    return normalized == 'PENDING' ||
        normalized == 'WAITING' ||
        normalized == 'NEW' ||
        normalized == 'INTERESTED';
  }

  /// Drops agents already accepted/rejected locally or on the server.
  ///
  /// [trustedReactionIds] — reactions returned by the pending API; never
  /// filtered out using a stale offer+agent cache entry.
  static Future<List<InterestedAgentModel>> filterUnresolvedInterestedAgents(
    List<InterestedAgentModel> agents, {
    Set<int> trustedReactionIds = const {},
  }) async {
    if (agents.isEmpty) return const [];

    await ClientInteractionStateService.ensureLoaded();

    final kept = <InterestedAgentModel>[];
    for (final agent in agents) {
      if (!agent.isActionable || !agent.isPendingForDeck) continue;

      final trusted = agent.reactionId > 0 &&
          trustedReactionIds.contains(agent.reactionId);

      if (!trusted) {
        if (await ClientMatchPersistence.isAccepted(
          offerId: agent.offerId,
          agentId: agent.id,
          reactionId: agent.reactionId,
        )) {
          continue;
        }

        final localStatus = await ClientMatchPersistence.statusFor(
          offerId: agent.offerId,
          agentId: agent.id,
          reactionId: agent.reactionId,
        );
        if (localStatus?.trim().toUpperCase() == 'REJECTED') continue;
      }

      if (!trusted) {
        final reaction = await ClientInteractionStateService.resolveReaction(
          reactionId: agent.reactionId > 0 ? agent.reactionId : null,
          offerId: agent.reactionId > 0 ? null : agent.offerId,
          agentId: agent.reactionId > 0 ? null : agent.id,
        );
        if (reaction != null && !_isPendingStatus(reaction.status)) continue;
      }

      kept.add(agent);
    }

    return _dedupeInterestedAgents(kept);
  }

  /// Recent accepted/matched agents for home preview (not pending).
  static Future<List<InterestedAgentModel>> fetchMatchedInterestedAgents({
    int limit = 5,
  }) async {
    if (!await AuthService.isClientRole()) return const [];

    try {
      final interactions = await fetchClientReactions(status: 'ACCEPTED');
      var agents = interactions
          .where((item) => item.agentId > 0 && item.offerId > 0)
          .map(InterestedAgentModel.fromInteraction)
          .where(_isMatchedStatus)
          .toList();

      if (agents.isEmpty) {
        final all = await fetchClientReactions();
        agents = all
            .where((item) => item.agentId > 0 && item.offerId > 0)
            .map(InterestedAgentModel.fromInteraction)
            .where(_isMatchedStatus)
            .toList();
      }

      return _dedupeInterestedAgents(agents).take(limit).toList();
    } catch (e) {
      debugPrint('[INTERACTION_SERVICE] fetchMatchedInterestedAgents: $e');
      return const [];
    }
  }

  /// Resolves a single pending reaction (used after push notifications).
  static Future<InterestedAgentModel?> fetchInterestedAgentByReaction({
    required int reactionId,
    int? offerId,
    int? agentId,
  }) async {
    if (reactionId <= 0) return null;

    final lookup = await lookupClientReaction(
      reactionId: reactionId,
      offerId: offerId,
      agentId: agentId,
    );
    if (lookup != null &&
        lookup.agentId > 0 &&
        _isPendingStatus(lookup.status)) {
      return InterestedAgentModel.fromInteraction(lookup);
    }

    return null;
  }

  static OfferInteractionModel _interactionFromInterestedAgent(
    InterestedAgentModel agent,
  ) {
    return OfferInteractionModel(
      id: agent.reactionId,
      offerId: agent.offerId,
      offerTitle: agent.offerTitle,
      agentId: agent.id,
      agentName: agent.name,
      agentPhotoUrl: agent.imageUrl,
      agentCity: agent.city,
      agentSkills: agent.jobTitle,
      message: agent.message,
      proposedPrice: double.tryParse(
        agent.proposedPrice.replaceAll(RegExp(r'[^0-9.]'), ''),
      ),
      status: agent.status,
      react: true,
    );
  }

  /// All offer reactions submitted by the logged-in agent.
  static Future<List<AgentMyReactionModel>> fetchMyOfferReactions() async {
    const paths = [
      '/api/interactions/my-reactions/',
      '/api/interactions/me/reactions/',
      '/api/interactions/agent/reactions/',
      '/api/interactions/agent/my-reactions/',
      '/api/interactions/me/',
    ];

    final merged = <int, AgentMyReactionModel>{};

    for (final path in paths) {
      try {
        final decoded = await _getJson(
          path: path,
          expectedStatusCodes: const [200, 201],
        );

        final list = _extractList(decoded);
        for (final item in list) {
          final reaction = AgentMyReactionModel.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (reaction.id <= 0) continue;
          merged[reaction.id] = reaction;
        }

        if (merged.isNotEmpty) {
          debugPrint(
            '[INTERACTION_SERVICE] ${merged.length} my reactions from $path',
          );
          break;
        }
      } on InteractionServiceException catch (e) {
        debugPrint('[INTERACTION_SERVICE] GET $path failed: ${e.message}');
      } catch (e) {
        debugPrint('[INTERACTION_SERVICE] GET $path failed: $e');
      }
    }

    final results = merged.values.toList()
      ..sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;
        if (ad == null && bd == null) return b.id.compareTo(a.id);
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });

    return results;
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

  /// POST /api/interactions/reactions/{reactionId}/respond/ with `{ "accept": true|false }`.
  static Future<OfferInteractionModel> respondToReaction({
    required int reactionId,
    required bool accept,
    int? offerId,
  }) async {
    return respondToInteraction(
      interactionId: reactionId,
      accept: accept,
      offerId: offerId,
    );
  }

  static Future<OfferInteractionModel> respondToInteraction({
    required int interactionId,
    required bool accept,
    int? offerId,
  }) async {
    final statusValue = accept ? 'ACCEPTED' : 'REJECTED';
    final path = '/api/interactions/reactions/$interactionId/respond/';

    OfferInteractionModel parseResponse(dynamic decoded) {
      if (decoded is Map<String, dynamic>) {
        final reaction = decoded['reaction'];
        if (reaction is Map<String, dynamic>) {
          return OfferInteractionModel.fromJson(reaction);
        }
        if (decoded.containsKey('id')) {
          return OfferInteractionModel.fromJson(decoded);
        }
      }
      return _syntheticResponse(interactionId, statusValue);
    }

    try {
      final decoded = await _postJson(
        path: path,
        payload: {'accept': accept},
        expectedStatusCodes: const [200, 201],
      );
      return parseResponse(decoded);
    } on InteractionServiceException catch (e) {
      final msg = e.message.toLowerCase();

      if (msg.contains('already been handled') ||
          msg.contains('already handled')) {
        final existing = await lookupClientReaction(
          reactionId: interactionId,
          offerId: offerId,
        );
        if (existing != null) {
          return existing;
        }
        return _syntheticResponse(interactionId, statusValue);
      }

      rethrow;
    }
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

class InteractionServiceException implements Exception {
  final String message;

  const InteractionServiceException(this.message);

  @override
  String toString() => message;
}
