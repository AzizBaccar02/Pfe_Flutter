import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification_model.dart';
import 'app_realtime_coordinator.dart';
import 'notification_realtime_hub.dart';

/// Broadcasts when the client should reload or prepend interested agents.
class ClientInteractionRealtime {
  ClientInteractionRealtime._();

  static final ClientInteractionRealtime instance =
      ClientInteractionRealtime._();

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  final StreamController<AppNotificationModel> _agentInterestController =
      StreamController<AppNotificationModel>.broadcast();

  /// Fired when list should reload from API.
  Stream<void> get onRefresh => _refreshController.stream;

  /// Fired with payload when an agent likes an offer (WebSocket / push).
  Stream<AppNotificationModel> get onAgentInterest =>
      _agentInterestController.stream;

  StreamSubscription<AppNotificationModel>? _notificationSubscription;
  bool _listening = false;

  void reset() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _listening = false;
  }
  
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
    if (!_isAgentInterestPush(notification)) return;

    debugPrint(
      '[CLIENT_INTERACTION_RT] Agent interest push — refresh Interested tab',
    );

    _agentInterestController.add(notification);
    _refreshController.add(null);
  }

  bool _isAgentInterestPush(AppNotificationModel notification) {
    if (notification.isAgentInterestNotification) return true;

    final type = notification.type;
    if (type == AppNotificationType.agentLikedOffer ||
        type == AppNotificationType.offer) {
      return notification.offerId != null && notification.agentId != null;
    }

    final title = notification.title.toLowerCase();
    final body = notification.body.toLowerCase();

    return title.contains('interested') ||
        title.contains('liked your offer') ||
        title.contains('liked your offer') ||
        body.contains('liked your offer') ||
        body.contains('is interested');
  }

  /// Manual refresh trigger (e.g. after returning from background).
  void notifyRefresh() {
    _refreshController.add(null);
    AppRealtimeCoordinator.instance.notifyRefresh(debugLabel: 'client_interaction');
  }

  void dispose() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _listening = false;
  }
}
