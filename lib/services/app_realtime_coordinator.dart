import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification_model.dart';
import 'chat_realtime_hub.dart';
import 'notification_realtime_hub.dart';

/// Single app-wide refresh bus. Screens subscribe once; any backend change
/// (notification, chat, or domain hub) triggers a silent reload.
class AppRealtimeCoordinator {
  AppRealtimeCoordinator._();

  static final AppRealtimeCoordinator instance = AppRealtimeCoordinator._();

  final StreamController<void> _refreshController =
      StreamController<void>.broadcast();

  Stream<void> get onRefresh => _refreshController.stream;

  StreamSubscription<AppNotificationModel>? _notificationSubscription;
  StreamSubscription<Map<String, dynamic>>? _chatSubscription;
  bool _started = false;

  void ensureStarted() {
    if (_started) return;
    _started = true;

    unawaited(NotificationRealtimeHub.instance.ensureStarted());
    unawaited(ChatRealtimeHub.instance.ensureStarted());

    _notificationSubscription =
        NotificationRealtimeHub.instance.onNotification.listen((_) {
      notifyRefresh(debugLabel: 'notification');
    });

    _chatSubscription = ChatRealtimeHub.instance.onInboxEvent.listen((event) {
      if (!ChatRealtimeHub.isMessageRelatedEvent(event)) return;
      notifyRefresh(debugLabel: 'chat');
    });
  }

  void reset() {
    _notificationSubscription?.cancel();
    _chatSubscription?.cancel();
    _notificationSubscription = null;
    _chatSubscription = null;
    _started = false;
  }

  void notifyRefresh({String? debugLabel}) {
    if (debugLabel != null) {
      debugPrint('[APP_RT] refresh ($debugLabel)');
    }
    if (!_refreshController.isClosed) {
      _refreshController.add(null);
    }
  }
}
