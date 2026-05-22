// lib/services/notification_router.dart

import 'package:flutter/material.dart';

import '../models/app_notification_model.dart';
import '../models/chat_conversation_summary_model.dart';
import '../models/interested_agent_model.dart';
import '../screens/chats/chat_conversation_screen.dart';
import '../screens/offers/client/client_agent_interest_screen.dart';
import '../screens/offers/widgets/agent_match_response_sheet.dart';
import 'chat_service.dart';
import 'offer_reaction_service.dart';

class NotificationRouter {
  static Future<InterestedAgentModel?> handle(
    BuildContext context,
    AppNotificationModel notification,
  ) async {
    if (!context.mounted) return null;

    switch (notification.tapAction) {
      case NotificationTapAction.reviewAgentInterest:
        return _openClientAgentInterest(context, notification);
      case NotificationTapAction.agentMatchAccepted:
        await AgentMatchResponseSheet.show(
          context,
          notification: notification,
          onStartChat: () => _openAgentChat(context, notification),
        );
        return null;
      case NotificationTapAction.agentMatchRejected:
        await _showAgentRejectedDialog(context, notification);
        return null;
      case NotificationTapAction.openChat:
        await _openAgentChat(context, notification);
        return null;
      case NotificationTapAction.none:
        return null;
    }
  }

  static Future<InterestedAgentModel?> _openClientAgentInterest(
    BuildContext context,
    AppNotificationModel notification,
  ) async {
    final offerId = notification.offerId;
    final agentId = notification.agentId;

    if (offerId == null || agentId == null) {
      if (!context.mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This notification is missing offer or agent details.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }

    return Navigator.push<InterestedAgentModel>(
      context,
      MaterialPageRoute(
        builder: (_) => ClientAgentInterestScreen(
          offerId: offerId,
          agentId: agentId,
          agentName: notification.resolvedAgentName ?? notification.agentName,
          agentEmail: notification.agentEmail,
          offerTitle: notification.offerTitle,
          interactionId: notification.interactionId,
          interestMessage: notification.body,
          avatarUrl: notification.avatarUrl,
        ),
      ),
    );
  }

  static Future<void> _openAgentChat(
    BuildContext context,
    AppNotificationModel notification,
  ) async {
    ChatConversationSummaryModel? chat;

    try {
      final response = await ChatService.getCurrentUserChats();
      final offerId = notification.offerId;

      for (final item in response.chats) {
        final matchesOffer =
            offerId == null || (item.offer?.id ?? -1) == offerId;
        if (!matchesOffer) continue;

        chat = item;
        break;
      }
    } catch (_) {
      // Fall through to chats tab message.
    }

    if (!context.mounted) return;

    if (chat != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatConversationScreen(chat: chat!),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Open the Chats tab when your conversation is ready.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> _showAgentRejectedDialog(
    BuildContext context,
    AppNotificationModel notification,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Interest declined'),
          content: Text(notification.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static InterestedAgentModel? resolveAgent({
    required int offerId,
    required int agentId,
    String? agentName,
  }) {
    return OfferReactionService.findInterestedAgent(
      offerId: offerId,
      agentId: agentId,
    );
  }
}
