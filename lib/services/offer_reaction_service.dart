// lib/services/offer_reaction_service.dart

import '../models/interested_agent_model.dart';
import '../models/offer_interaction_model.dart';
import 'client_interaction_state_service.dart';
import 'client_match_persistence.dart';
import 'interaction_service.dart';
import 'notification_realtime_hub.dart';

class OfferReactionService {
  /// Calls the real backend: POST /api/interactions/offers/{id}/react/
  /// The server should create the notification for the offer owner.
  static Future<OfferInteractionModel> recordAgentLikeOffer({
    required int offerId,
    String message = 'I am interested in this offer.',
    double? proposedPrice,
  }) async {
    final interaction = await InteractionService.reactToOffer(
      offerId: offerId,
      react: true,
      message: message,
      proposedPrice: proposedPrice,
    );

    return interaction;
  }

  static Future<void> clientAcceptAgent({
    required OfferInteractionModel interaction,
  }) async {
    await InteractionService.respondToInteraction(
      interactionId: interaction.id,
      accept: true,
      offerId: interaction.offerId > 0 ? interaction.offerId : null,
    );

    await ClientMatchPersistence.markAccepted(
      offerId: interaction.offerId,
      agentId: interaction.agentId,
      reactionId: interaction.id,
    );
    await ClientInteractionStateService.recordAccepted(
      offerId: interaction.offerId,
      agentId: interaction.agentId,
      reactionId: interaction.id,
    );
    await ClientInteractionStateService.invalidate();
  }

  static Future<void> clientRejectAgent({
    required OfferInteractionModel interaction,
  }) async {
    await InteractionService.respondToInteraction(
      interactionId: interaction.id,
      accept: false,
      offerId: interaction.offerId > 0 ? interaction.offerId : null,
    );

    await ClientMatchPersistence.markRejected(
      offerId: interaction.offerId,
      agentId: interaction.agentId,
    );
    await ClientInteractionStateService.invalidate();
  }

  static Future<List<InterestedAgentModel>> loadPendingAgentsForOffer(
    int offerId,
  ) async {
    final pending = await InteractionService.getPendingForOffer(offerId);

    return pending
        .where((item) => item.agentId > 0 && item.id > 0)
        .map(InterestedAgentModel.fromInteraction)
        .toList();
  }

  static Future<InterestedAgentModel?> findInterestedAgent({
    required int offerId,
    required int agentId,
    int? reactionId,
  }) async {
    final interaction = await InteractionService.lookupClientReaction(
      reactionId: reactionId,
      offerId: offerId,
      agentId: agentId,
    );

    if (interaction != null && interaction.agentId > 0) {
      return InterestedAgentModel.fromInteraction(interaction);
    }

    try {
      final agents = await InteractionService.fetchInterestedAgents(
        offerId: offerId,
      );
      return agents.firstWhere((agent) => agent.id == agentId);
    } catch (_) {
      return null;
    }
  }

  static Future<void> refreshNotificationBadge() async {
    await NotificationRealtimeHub.instance.syncUnreadCount();
  }
}
