// lib/services/offer_reaction_service.dart

import '../data/mock_client_data.dart';
import '../models/interested_agent_model.dart';
import '../models/offer_interaction_model.dart';
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
  }

  static Future<void> clientRejectAgent({
    required OfferInteractionModel interaction,
  }) async {
    await InteractionService.respondToInteraction(
      interactionId: interaction.id,
      accept: false,
      offerId: interaction.offerId > 0 ? interaction.offerId : null,
    );
  }

  static Future<List<InterestedAgentModel>> loadPendingAgentsForOffer(
    int offerId,
  ) async {
    final pending = await InteractionService.getPendingForOffer(offerId);

    return pending
        .where((item) => item.agentId > 0)
        .map(
          (item) => InterestedAgentModel(
            id: item.agentId,
            name: item.agentName ?? item.agentEmail ?? 'Agent',
            jobTitle: 'Interested agent',
            city: '—',
            rating: 4.5,
            completedJobs: 0,
            imageUrl: 'assets/images/agent1.jpg',
            offerId: item.offerId,
            offerTitle: item.offerTitle,
          ),
        )
        .toList();
  }

  static InterestedAgentModel? findInterestedAgent({
    required int offerId,
    required int agentId,
  }) {
    try {
      return MockClientData.interestedAgents.firstWhere(
        (agent) => agent.offerId == offerId && agent.id == agentId,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> refreshNotificationBadge() async {
    await NotificationRealtimeHub.instance.syncUnreadCount();
  }
}
