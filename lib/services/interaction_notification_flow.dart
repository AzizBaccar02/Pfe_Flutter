import 'package:flutter/material.dart';

import '../models/app_notification_model.dart';
import '../models/chat_conversation_summary_model.dart';
import '../models/interest_resolution.dart';
import '../models/offer_interaction_model.dart';
import '../screens/chats/chat_conversation_screen.dart';
import '../screens/offers/client/client_agent_interest_screen.dart';
import 'chat_service.dart';
import 'client_interaction_state_service.dart';
export '../models/interest_resolution.dart';

/// Routes notification taps based on the real offer-reaction status.
abstract final class InteractionNotificationFlow {
  static String normalizeStatus(String? status) =>
      status?.trim().toUpperCase() ?? '';

  static bool isPending(String? status) => normalizeStatus(status) == 'PENDING';

  static bool isAccepted(String? status) =>
      normalizeStatus(status) == 'ACCEPTED';

  static bool isRejected(String? status) =>
      normalizeStatus(status) == 'REJECTED';

  static Future<OfferInteractionModel?> lookupReaction(
    AppNotificationModel notification,
  ) {
    return ClientInteractionStateService.resolveReaction(
      reactionId: notification.interactionId,
      offerId: notification.offerId,
      agentId: notification.agentId,
    );
  }

  /// Checks reaction status, chats, and local match records.
  static Future<InterestResolution> resolveInterest(
    AppNotificationModel notification,
  ) async {
    await ClientInteractionStateService.ensureLoaded();

    final offerId = notification.offerId;
    final agentId = notification.agentId;

    OfferInteractionModel? reaction =
        await ClientInteractionStateService.resolveReaction(
      reactionId: notification.interactionId,
      offerId: offerId,
      agentId: agentId,
    );

    final chat = offerId != null && offerId > 0
        ? ClientInteractionStateService.chatFor(
            offerId: offerId,
            agentId: agentId,
            clientId: notification.clientId,
          ) ??
            (notification.chatId != null
                ? ClientInteractionStateService.chatById(
                    notification.chatId!,
                  )
                : null)
        : null;

    var inferredAcceptedFromChat = false;

    if (chat != null &&
        (reaction == null || !isRejected(reaction.status))) {
      if (reaction == null || !isAccepted(reaction.status)) {
        inferredAcceptedFromChat = true;
        reaction = syntheticAcceptedReaction(
          notification: notification,
          existing: reaction,
        );
        if (reaction.offerId > 0 && reaction.agentId > 0) {
          await ClientInteractionStateService.recordAccepted(
            offerId: reaction.offerId,
            agentId: reaction.agentId,
            reactionId: reaction.id,
          );
        }
      }
    }

    return InterestResolution(
      reaction: reaction,
      chat: chat,
      inferredAcceptedFromChat: inferredAcceptedFromChat,
    );
  }

  static OfferInteractionModel syntheticAcceptedReaction({
    required AppNotificationModel notification,
    OfferInteractionModel? existing,
  }) {
    return OfferInteractionModel(
      id: existing?.id ?? notification.interactionId ?? 0,
      offerId: notification.offerId ?? existing?.offerId ?? 0,
      offerTitle: notification.offerTitle ?? existing?.offerTitle ?? '',
      agentId: notification.agentId ?? existing?.agentId ?? 0,
      agentUserId: existing?.agentUserId,
      agentEmail: notification.agentEmail ?? existing?.agentEmail,
      agentName: notification.resolvedAgentName ??
          notification.agentName ??
          existing?.agentName,
      agentPhotoUrl: notification.avatarUrl ?? existing?.agentPhotoUrl,
      message: existing?.message ?? notification.body,
      proposedPrice: existing?.proposedPrice,
      status: 'ACCEPTED',
      react: true,
    );
  }

  static Future<ChatConversationSummaryModel?> resolveChatForNotification(
    AppNotificationModel notification,
  ) async {
    final chatId = notification.chatId;
    if (chatId != null && chatId > 0) {
      final cached = ClientInteractionStateService.chatById(chatId);
      if (cached != null) return cached;

      try {
        return await ChatService.getChatById(chatId: chatId);
      } catch (_) {
        // Fall through to list lookup.
      }
    }

    await ClientInteractionStateService.ensureLoaded();

    final offerId = notification.offerId;
    if (offerId == null || offerId <= 0) return null;

    final clientId = notification.clientId;
    if (clientId != null && clientId > 0) {
      final byClient = ClientInteractionStateService.chatFor(
        offerId: offerId,
        clientId: clientId,
      );
      if (byClient != null) return byClient;
    }

    final agentId = notification.agentId;
    if (agentId != null && agentId > 0) {
      final byAgent = ClientInteractionStateService.chatFor(
        offerId: offerId,
        agentId: agentId,
      );
      if (byAgent != null) return byAgent;
    }

    return ClientInteractionStateService.chatFor(offerId: offerId);
  }

  static Future<ChatConversationSummaryModel?> findChatForNotification(
    AppNotificationModel notification,
  ) =>
      resolveChatForNotification(notification);

  static Future<ChatConversationSummaryModel?> findChatForOfferAgent({
    required int offerId,
    int? agentId,
  }) async {
    await ClientInteractionStateService.ensureLoaded();
    return ClientInteractionStateService.chatFor(
      offerId: offerId,
      agentId: agentId,
    );
  }

  static Future<void> openChat(
    BuildContext context,
    ChatConversationSummaryModel chat,
  ) async {
    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(chat: chat),
      ),
    );
  }

  static Future<void> openChatForNotification(
    BuildContext context,
    AppNotificationModel notification,
  ) async {
    if (!context.mounted) return;

    var chat = await resolveChatForNotification(notification);

    if (chat == null) {
      await ClientInteractionStateService.invalidate();
      chat = await resolveChatForNotification(notification);
    }

    if (!context.mounted) return;

    if (chat != null) {
      await openChat(context, chat);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Conversation not found yet. Pull to refresh on the Chats tab.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Client notification tap: open chat, show match summary, or review screen.
  static Future<bool> handleClientAgentInterestTap(
    BuildContext context,
    AppNotificationModel notification, {
    required Future<void> Function() openReviewScreen,
    Future<void> Function(InterestResolution resolution)? openAcceptedScreen,
  }) async {
    final resolution = await resolveInterest(notification);

    if (!context.mounted) return false;

    if (resolution.isAccepted) {
      final chat =
          resolution.chat ?? await resolveChatForNotification(notification);
      if (chat != null) {
        await openChat(context, chat);
        return true;
      }

      if (openAcceptedScreen != null) {
        await openAcceptedScreen(resolution);
        return true;
      }

      final offerId = notification.offerId;
      final agentId = notification.agentId;
      if (offerId != null && agentId != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClientAgentInterestScreen(
              offerId: offerId,
              agentId: agentId,
              agentName:
                  notification.resolvedAgentName ?? notification.agentName,
              agentEmail: notification.agentEmail,
              offerTitle: notification.offerTitle,
              interactionId: notification.interactionId,
              interestMessage: notification.body,
              avatarUrl: notification.avatarUrl,
            ),
          ),
        );
        return true;
      }

      await openChatForNotification(context, notification);
      return true;
    }

    if (resolution.isRejected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already declined this agent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    }

    await openReviewScreen();
    return true;
  }
}
