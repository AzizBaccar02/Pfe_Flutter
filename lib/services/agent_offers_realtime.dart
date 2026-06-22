import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification_model.dart';
import 'auth_service.dart';
import 'app_realtime_coordinator.dart';
import 'notification_realtime_hub.dart';

/// Tells the agent Offers swipe deck to reload when new public offers appear.
class AgentOffersRealtime {
  AgentOffersRealtime._();

  static final AgentOffersRealtime instance = AgentOffersRealtime._();

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  final StreamController<AppNotificationModel> _newOfferController =
      StreamController<AppNotificationModel>.broadcast();

  Stream<void> get onRefresh => _refreshController.stream;

  Stream<AppNotificationModel> get onNewOffer => _newOfferController.stream;

  StreamSubscription<AppNotificationModel>? _notificationSubscription;
  bool _listening = false;

  void ensureStarted() {
    if (_listening) return;
    _listening = true;

    unawaited(NotificationRealtimeHub.instance.ensureStarted());

    _notificationSubscription =
        NotificationRealtimeHub.instance.onNotification.listen(
      _handleNotification,
    );
  }

  void _handleNotification(AppNotificationModel notification) {
    unawaited(_handleNotificationAsync(notification));
  }

  Future<void> _handleNotificationAsync(
    AppNotificationModel notification,
  ) async {
    if (!await AuthService.isAgentRole()) return;
    if (!_isNewPublicOfferPush(notification)) return;

    debugPrint(
      '[AGENT_OFFERS_RT] New offer push — refresh Offers deck '
      '(offerId=${notification.offerId})',
    );

    _newOfferController.add(notification);
    _refreshController.add(null);
  }

  bool _isNewPublicOfferPush(AppNotificationModel notification) {
    if (notification.isAgentInterestNotification ||
        notification.isClientMatchNotification) {
      return false;
    }

    final action = notification.tapAction;
    if (action == NotificationTapAction.reviewAgentInterest ||
        action == NotificationTapAction.agentMatchAccepted ||
        action == NotificationTapAction.agentMatchRejected) {
      return false;
    }

    if (notification.offerId != null && notification.offerId! > 0) {
      if (notification.type == AppNotificationType.offer ||
          notification.type == AppNotificationType.system) {
        return true;
      }
    }

    if (notification.type == AppNotificationType.offer) {
      return true;
    }

    final title = notification.title.toLowerCase();
    final body = notification.body.toLowerCase();
    const keywords = [
      'new offer',
      'offer published',
      'published successfully',
      'now visible to agents',
      'posted a new',
      'new job',
      'nouvelle offre',
      'offre publiée',
    ];

    for (final keyword in keywords) {
      if (title.contains(keyword) || body.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  void notifyRefresh() {
    _refreshController.add(null);
    AppRealtimeCoordinator.instance.notifyRefresh(debugLabel: 'agent_offers');
  }

  void dispose() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _listening = false;
  }
}
