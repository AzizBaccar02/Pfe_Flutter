import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification_model.dart';
import 'auth_service.dart';
import 'app_realtime_coordinator.dart';
import 'notification_realtime_hub.dart';

/// Reloads agent "My Reactions" when client accepts/declines or status changes.
class AgentReactionsRealtime {
  AgentReactionsRealtime._();

  static final AgentReactionsRealtime instance = AgentReactionsRealtime._();

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  Stream<void> get onRefresh => _refreshController.stream;

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

  void reset() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _listening = false;
  }

  void _handleNotification(AppNotificationModel notification) {
    unawaited(_handleNotificationAsync(notification));
  }

  Future<void> _handleNotificationAsync(
    AppNotificationModel notification,
  ) async {
    if (!await AuthService.isAgentRole()) return;
    if (!_shouldRefreshReactions(notification)) return;

    debugPrint(
      '[AGENT_REACTIONS_RT] Match/status push — refresh My Reactions '
      '(offerId=${notification.offerId}, reactionId=${notification.interactionId})',
    );

    _refreshController.add(null);
  }

  bool _shouldRefreshReactions(AppNotificationModel notification) {
    if (notification.isClientMatchNotification) return true;

    final action = notification.tapAction;
    if (action == NotificationTapAction.agentMatchAccepted ||
        action == NotificationTapAction.agentMatchRejected) {
      return true;
    }

    if (notification.type == AppNotificationType.clientRejected) {
      return true;
    }

    final title = notification.title.toLowerCase();
    final body = notification.body.toLowerCase();

    const keywords = [
      'accepted your',
      'accepted you',
      'matched with',
      'new match',
      'declined your',
      'rejected your',
      'client accepted',
      'client declined',
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
    AppRealtimeCoordinator.instance.notifyRefresh(debugLabel: 'agent_reactions');
  }

  void dispose() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _listening = false;
  }
}
