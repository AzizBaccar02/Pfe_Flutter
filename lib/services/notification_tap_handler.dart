import 'package:flutter/material.dart';

import '../models/app_notification_model.dart';
import '../models/interested_agent_model.dart';
import '../screens/offers/client/client_agent_interest_screen.dart';
import 'app_navigation_bus.dart';
import 'app_navigator.dart';
import 'notification_enrichment_service.dart';
import 'notification_realtime_hub.dart';
import 'notification_router.dart';
import 'notification_service.dart';
import 'interaction_notification_flow.dart';

/// Shared tap flow for notification banners and inbox rows.
abstract final class NotificationTapHandler {
  static Future<void> handle(AppNotificationModel notification) async {
    final context = AppNavigator.context;
    if (context == null || !context.mounted) return;

    await _markAsRead(notification);

    final resolved =
        await NotificationEnrichmentService.enrichOne(notification);
    if (!context.mounted) return;

    if (resolved.isAgentInterestNotification) {
      await InteractionNotificationFlow.handleClientAgentInterestTap(
        context,
        resolved,
        openReviewScreen: () => _openClientAgentInterestReview(
          context,
          resolved,
        ),
      );
      return;
    }

    if (resolved.tapAction == NotificationTapAction.agentMatchAccepted ||
        resolved.tapAction == NotificationTapAction.openChat) {
      await InteractionNotificationFlow.openChatForNotification(
        context,
        resolved,
      );
      await AppNavigationBus.instance.chatOpened?.call();
      return;
    }

    if (resolved.tapAction == NotificationTapAction.agentMatchRejected) {
      await NotificationRouter.handle(context, resolved);
      return;
    }

    if (!resolved.isActionable) {
      AppNavigationBus.instance.openNotifications?.call();
      return;
    }

    final acceptedAgent = await NotificationRouter.handle(context, resolved);
    if (acceptedAgent != null) {
      AppNavigationBus.instance.agentAccepted?.call(acceptedAgent);
    }
  }

  static Future<void> _markAsRead(AppNotificationModel notification) async {
    if (notification.isRead || notification.id <= 0) return;

    try {
      await NotificationService.markAsRead(notification.id);
    } catch (_) {
      // Keep routing even if the read API fails.
    }

    await NotificationRealtimeHub.instance.syncUnreadCount();
  }

  static Future<void> _openClientAgentInterestReview(
    BuildContext context,
    AppNotificationModel notification,
  ) async {
    final offerId = notification.offerId;
    final agentId = notification.agentId;

    if (offerId == null || agentId == null) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Missing offer or agent info in this notification.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!context.mounted) return;

    final acceptedAgent = await Navigator.of(context).push<InterestedAgentModel>(
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

    if (acceptedAgent != null) {
      AppNavigationBus.instance.agentAccepted?.call(acceptedAgent);
    }
  }
}
