// lib/services/notification_router.dart

import 'package:flutter/material.dart';

import '../models/app_notification_model.dart';
import '../models/interested_agent_model.dart';
import '../screens/offers/client/client_agent_interest_screen.dart';
import 'auth_service.dart';
import 'client_interaction_state_service.dart';
import 'interaction_notification_flow.dart';
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
        await _handleAgentMatchAccepted(context, notification);
        return null;
      case NotificationTapAction.agentMatchRejected:
        await _showAgentRejectedDialog(context, notification);
        return null;
      case NotificationTapAction.openChat:
        await InteractionNotificationFlow.openChatForNotification(
          context,
          notification,
        );
        return null;
      case NotificationTapAction.none:
        return null;
    }
  }

  static Future<InterestedAgentModel?> _openClientAgentInterest(
    BuildContext context,
    AppNotificationModel notification,
  ) async {
    if (!await AuthService.isClientRole()) {
      if (!context.mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This action is only available for client accounts.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }

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

    await ClientInteractionStateService.ensureLoaded();

    final resolution =
        await InteractionNotificationFlow.resolveInterest(notification);

    if (!context.mounted) return null;

    if (resolution.isAccepted) {
      final chat = resolution.chat ??
          ClientInteractionStateService.chatFor(
            offerId: offerId,
            agentId: agentId,
          );

      if (chat != null) {
        await InteractionNotificationFlow.openChat(context, chat);
      } else {
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
              interactionId:
                  notification.interactionId ?? resolution.reaction?.id,
              interestMessage: notification.body,
              avatarUrl: notification.avatarUrl,
            ),
          ),
        );
      }
      return null;
    }

    if (resolution.isRejected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already declined this agent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }

    final reaction = resolution.reaction;

    return Navigator.push<InterestedAgentModel>(
      context,
      MaterialPageRoute(
        builder: (_) => ClientAgentInterestScreen(
          offerId: offerId,
          agentId: agentId,
          agentName: notification.resolvedAgentName ?? notification.agentName,
          agentEmail: notification.agentEmail,
          offerTitle: notification.offerTitle,
          interactionId: notification.interactionId ?? reaction?.id,
          interestMessage: notification.body,
          avatarUrl: notification.avatarUrl,
        ),
      ),
    );
  }

  static Future<void> _handleAgentMatchAccepted(
    BuildContext context,
    AppNotificationModel notification,
  ) async {
    await InteractionNotificationFlow.openChatForNotification(
      context,
      notification,
    );
  }

  static Future<void> _showAgentRejectedDialog(
    BuildContext context,
    AppNotificationModel notification,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
          title: Text(
            'Interest declined',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            notification.body,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.65),
            ),
          ),
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

  static Future<InterestedAgentModel?> resolveAgent({
    required int offerId,
    required int agentId,
    int? reactionId,
    String? agentName,
  }) {
    return OfferReactionService.findInterestedAgent(
      offerId: offerId,
      agentId: agentId,
      reactionId: reactionId,
    );
  }
}
