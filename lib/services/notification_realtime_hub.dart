// lib/services/notification_realtime_hub.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/app_notification_model.dart';
import 'notification_enrichment_service.dart';
import 'notification_service.dart';

/// Single shared WebSocket + unread state for the whole app.
class NotificationRealtimeHub {
  NotificationRealtimeHub._();

  static final NotificationRealtimeHub instance = NotificationRealtimeHub._();

  final StreamController<AppNotificationModel> _notificationController =
      StreamController<AppNotificationModel>.broadcast();

  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  Stream<AppNotificationModel> get onNotification =>
      _notificationController.stream;

  Stream<int> get onUnreadCountChanged => _unreadCountController.stream;

  int unreadCount = 0;
  bool isInboxOpen = false;

  bool _isStarting = false;
  bool _isStarted = false;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  void setInboxOpen(bool value) {
    isInboxOpen = value;
  }

  Future<void> ensureStarted() async {
    if (_isStarted || _isStarting) return;

    _isStarting = true;

    try {
      await syncUnreadCount();
      await _connectSocket();
      _isStarted = true;
    } finally {
      _isStarting = false;
    }
  }

  Future<void> syncUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      unreadCount = count;
      _unreadCountController.add(count);
      debugPrint('[NOTIFICATION_HUB] unread_count=$count');
    } catch (e) {
      debugPrint('[NOTIFICATION_HUB] syncUnreadCount failed: $e');
    }
  }

  Future<List<AppNotificationModel>> fetchNotifications() async {
    final items = await NotificationService.getMyNotifications();
    return NotificationEnrichmentService.enrich(items);
  }

  Future<void> markAllAsRead() async {
    await NotificationService.markAllAsRead();
    unreadCount = 0;
    _unreadCountController.add(0);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
    _isStarted = false;
    isInboxOpen = false;
    unreadCount = 0;
  }

  Future<void> _connectSocket() async {
    try {
      await _subscription?.cancel();
      await _channel?.sink.close();

      final channel = await NotificationService.connectToNotificationSocket();
      _channel = channel;

      _subscription = channel.stream.listen(
        _handleSocketEvent,
        onError: (_) {},
        onDone: () {},
        cancelOnError: false,
      );
    } catch (_) {
      // Keep app usable if notifications socket is unavailable.
    }
  }

  void _handleSocketEvent(dynamic event) {
    try {
      final decoded = event is String ? jsonDecode(event) : event;

      if (decoded is! Map) return;

      final data = Map<String, dynamic>.from(decoded);
      final type = data['type']?.toString();

      if (type != 'new_notification') return;

      final rawNotification = data['notification'];

      if (rawNotification is! Map) return;

      final notification = AppNotificationModel.fromJson(
        Map<String, dynamic>.from(rawNotification),
      );

      unawaited(
        NotificationEnrichmentService.enrichOne(notification).then(
          _notificationController.add,
        ),
      );

      if (isInboxOpen) {
        unawaited(markAllAsRead());
        return;
      }

      unreadCount += 1;
      _unreadCountController.add(unreadCount);
    } catch (e) {
      debugPrint('[NOTIFICATION_HUB] Invalid event: $e');
    }
  }
}
