import 'package:flutter/foundation.dart';

import '../models/chat_conversation_summary_model.dart';
import '../models/offer_interaction_model.dart';
import 'auth_service.dart';
import 'chat_service.dart';
import 'client_match_persistence.dart';
import 'interaction_service.dart';

/// Cached client-side view of offer reactions + chats for routing notifications.
abstract final class ClientInteractionStateService {
  static final Map<int, OfferInteractionModel> _byReactionId = {};
  static final Map<String, OfferInteractionModel> _byOfferAgent = {};
  static List<ChatConversationSummaryModel> _chats = const [];
  static DateTime? _loadedAt;

  /// Clears in-memory reaction/chat cache on logout.
  static void reset() {
    _byReactionId.clear();
    _byOfferAgent.clear();
    _chats = const [];
    _loadedAt = null;
  }

  static String _pairKey(int offerId, int agentId) => '${offerId}_$agentId';

  static void _store(OfferInteractionModel reaction) {
    if (reaction.id > 0) {
      _byReactionId[reaction.id] = reaction;
    }
    if (reaction.offerId > 0 && reaction.agentId > 0) {
      _byOfferAgent[_pairKey(reaction.offerId, reaction.agentId)] = reaction;
    }
  }

  static Future<void> ensureLoaded({bool force = false}) async {
    if (!force &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) <
            const Duration(seconds: 20)) {
      return;
    }

    _byReactionId.clear();
    _byOfferAgent.clear();
    _chats = const [];

    await _loadFromApi();
    await _loadFromChats();

    _loadedAt = DateTime.now();
  }

  static Future<void> invalidate() async {
    _loadedAt = null;
    await ensureLoaded(force: true);
  }

  static Future<void> recordAccepted({
    required int offerId,
    required int agentId,
    required int reactionId,
  }) async {
    await ClientMatchPersistence.markAccepted(
      offerId: offerId,
      agentId: agentId,
      reactionId: reactionId,
    );

    _store(
      OfferInteractionModel(
        id: reactionId,
        offerId: offerId,
        offerTitle: '',
        agentId: agentId,
        message: '',
        status: 'ACCEPTED',
        react: true,
      ),
    );
  }

  static Future<void> _loadFromApi() async {
    if (!await AuthService.isClientRole()) return;

    try {
      final reactions = await InteractionService.fetchClientReactions();
      for (final reaction in reactions) {
        _store(reaction);
        if (reaction.status.trim().toUpperCase() == 'ACCEPTED' &&
            reaction.offerId > 0 &&
            reaction.agentId > 0) {
          await ClientMatchPersistence.markAccepted(
            offerId: reaction.offerId,
            agentId: reaction.agentId,
            reactionId: reaction.id,
          );
        }
      }
    } catch (e) {
      debugPrint('[CLIENT_STATE] fetchClientReactions: $e');
    }
  }

  static Future<void> _loadFromChats() async {
    try {
      final response = await ChatService.getCurrentUserChats();
      _chats = response.chats;

      for (final chat in _chats) {
        final reaction = chat.offreReaction;
        if (reaction == null || reaction.id <= 0) continue;

        final status = reaction.status.trim();
        if (status.isEmpty) continue;

        final model = OfferInteractionModel(
          id: reaction.id,
          offerId: chat.linkedOfferId,
          offerTitle: chat.offerTitle,
          agentId: reaction.agentId,
          message: reaction.message,
          proposedPrice: reaction.proposedPrice,
          status: status,
          react: reaction.react,
        );
        _store(model);

        if (status.toUpperCase() == 'ACCEPTED' &&
            model.offerId > 0 &&
            model.agentId > 0) {
          await ClientMatchPersistence.markAccepted(
            offerId: model.offerId,
            agentId: model.agentId,
            reactionId: model.id,
          );
        }
      }
    } catch (e) {
      debugPrint('[CLIENT_STATE] getCurrentUserChats: $e');
    }
  }

  static OfferInteractionModel? reactionFor({
    int? reactionId,
    int? offerId,
    int? agentId,
  }) {
    if (reactionId != null && reactionId > 0) {
      return _byReactionId[reactionId];
    }

    if (offerId != null &&
        offerId > 0 &&
        agentId != null &&
        agentId > 0) {
      return _byOfferAgent[_pairKey(offerId, agentId)];
    }

    return null;
  }

  static Future<OfferInteractionModel?> resolveReaction({
    int? reactionId,
    int? offerId,
    int? agentId,
  }) async {
    await ensureLoaded();

    final hasReactionId = reactionId != null && reactionId > 0;

    var reaction = hasReactionId
        ? reactionFor(reactionId: reactionId)
        : reactionFor(offerId: offerId, agentId: agentId);

    if (reaction != null) return reaction;

    final persisted = await ClientMatchPersistence.statusFor(
      reactionId: reactionId,
      offerId: offerId,
      agentId: agentId,
    );

    if (persisted != null) {
      if (hasReactionId ||
          (offerId != null &&
              offerId > 0 &&
              agentId != null &&
              agentId > 0)) {
        reaction = OfferInteractionModel(
          id: reactionId ?? 0,
          offerId: offerId ?? 0,
          offerTitle: '',
          agentId: agentId ?? 0,
          message: '',
          status: persisted,
          react: true,
        );
        _store(reaction);
        return reaction;
      }
    }

    if (!await AuthService.isClientRole()) return null;

    if (hasReactionId) {
      reaction = await InteractionService.lookupClientReaction(
        reactionId: reactionId,
      );
    } else if (offerId != null &&
        offerId > 0 &&
        agentId != null &&
        agentId > 0) {
      reaction = await InteractionService.lookupClientReaction(
        offerId: offerId,
        agentId: agentId,
      );
    }

    if (reaction != null) {
      _store(reaction);
    }

    return reaction;
  }

  static ChatConversationSummaryModel? chatById(int chatId) {
    if (chatId <= 0) return null;
    for (final chat in _chats) {
      if (chat.id == chatId) return chat;
    }
    return null;
  }

  static ChatConversationSummaryModel? chatFor({
    required int offerId,
    int? agentId,
    int? clientId,
  }) {
    if (offerId <= 0) return null;

    final matchesOffer = _chats
        .where((chat) => chat.linkedOfferId == offerId)
        .toList();

    if (matchesOffer.isEmpty) return null;

    final peerRef = agentId ?? clientId;
    if (peerRef == null || peerRef <= 0) {
      return matchesOffer.first;
    }

    for (final chat in matchesOffer) {
      if (_chatMatchesPeer(chat, peerRef)) {
        return chat;
      }
    }

    if (matchesOffer.length == 1) {
      return matchesOffer.first;
    }

    return null;
  }

  static bool _chatMatchesPeer(ChatConversationSummaryModel chat, int peerRef) {
    final reactionAgentId = chat.offreReaction?.agentId ?? 0;
    final linkedAgentId = chat.linkedAgentId;
    final clientRowId = chat.client?.id ?? 0;
    final clientUserId = chat.client?.userId ?? 0;
    final agentRowId = chat.agent?.id ?? 0;
    final agentUserId = chat.agent?.userId ?? 0;
    final otherId = chat.otherUser?.id ?? 0;
    final otherUserId = chat.otherUser?.userId ?? 0;

    return reactionAgentId == peerRef ||
        linkedAgentId == peerRef ||
        clientRowId == peerRef ||
        clientUserId == peerRef ||
        agentRowId == peerRef ||
        agentUserId == peerRef ||
        otherId == peerRef ||
        otherUserId == peerRef;
  }
}
