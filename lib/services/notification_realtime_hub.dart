// lib/services/notification_realtime_hub.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/app_notification_model.dart';
import 'auth_service.dart';
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
  bool _socketConnected = false;
  bool _shutdown = false;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pollTimer;
  Timer? _reconnectTimer;

  void setInboxOpen(bool value) {
    isInboxOpen = value;
  }

  bool get isSocketConnected => _socketConnected;

  Future<void> ensureStarted() async {
    if (_shutdown || _isStarted || _isStarting) return;
    if (!await AuthService.hasActiveSession()) return;

    _isStarting = true;

    try {
      await syncUnreadCount();
      if (_shutdown) return;
      await _connectSocket();
      if (_shutdown) return;
      _isStarted = true;
      _startPolling();
    } catch (e) {
      debugPrint('[NOTIFICATION_HUB] start failed: $e');
      _isStarted = false;
      if (!_shutdown) {
        _scheduleReconnect();
        _startPolling();
      }
    } finally {
      _isStarting = false;
    }
  }

  void _startPolling() {
    if (_shutdown) return;

    _pollTimer?.cancel();
    // Keeps the bell badge in sync when WebSocket is down or Channels is misconfigured.
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (_shutdown || isInboxOpen) return;
      unawaited(syncUnreadCount());
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> syncUnreadCount() async {
    if (_shutdown || !await AuthService.hasActiveSession()) return;

    try {
      var count = await NotificationService.getUnreadCount();
      if (count < 0) count = 0;

      unreadCount = count;
      _unreadCountController.add(count);
      debugPrint('[NOTIFICATION_HUB] unread_count=$count');
    } catch (e) {
      debugPrint('[NOTIFICATION_HUB] syncUnreadCount failed: $e');
      try {
        final items = await NotificationService.getMyNotifications();
        final count = items.where((item) => !item.isRead).length;
        unreadCount = count;
        _unreadCountController.add(count);
      } catch (_) {
        // Keep previous count if both calls fail.
      }
    }
  }

  Future<List<AppNotificationModel>> fetchNotifications() async {
    final items = await NotificationService.getMyNotifications();
    return NotificationEnrichmentService.enrich(items);
  }

  Future<void> markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
    } catch (e) {
      debugPrint('[NOTIFICATION_HUB] markAllAsRead failed: $e');
    }

    unreadCount = 0;
    _unreadCountController.add(0);

    try {
      final count = await NotificationService.getUnreadCount();
      if (count > 0) {
        debugPrint(
          '[NOTIFICATION_HUB] unread still $count after markAll, retrying',
        );
        await NotificationService.markAllAsRead();
        unreadCount = 0;
        _unreadCountController.add(0);
      }
    } catch (_) {
      // Badge already cleared locally.
    }
  }

  Future<void> stop() => shutdown();

  /// Stops polling, socket, and scheduled reconnects (logout).
  Future<void> shutdown() async {
    _shutdown = true;
    _isStarted = false;
    _isStarting = false;
    _socketConnected = false;
    isInboxOpen = false;
    unreadCount = 0;

    _stopPolling();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      await _subscription?.cancel();
    } catch (_) {}

    try {
      _channel?.sink.close();
    } catch (_) {}

    _subscription = null;
    _channel = null;
  }

  void resetForNewSession() {
    _shutdown = false;
  }

  /// Call when app returns to foreground.
  Future<void> refreshNow() async {
    if (_shutdown || !await AuthService.hasActiveSession()) return;

    await syncUnreadCount();
    if (!_shutdown && !_socketConnected && !_isStarting) {
      await _connectSocket();
    }
  }

  Future<void> _connectSocket() async {
    if (_shutdown || !await AuthService.hasActiveSession()) return;

    try {
      await _subscription?.cancel();
      try {
        _channel?.sink.close();
      } catch (_) {}

      final channel = await NotificationService.connectToNotificationSocket();
      if (_shutdown) {
        channel.sink.close();
        return;
      }
      _channel = channel;

      _subscription = channel.stream.listen(
        _handleSocketEvent,
        onError: (error) {
          debugPrint('[NOTIFICATION_HUB] socket error: $error');
          _socketConnected = false;
          if (!_shutdown) _scheduleReconnect();
        },
        onDone: () {
          debugPrint('[NOTIFICATION_HUB] socket closed');
          _socketConnected = false;
          if (!_shutdown) _scheduleReconnect();
        },
        cancelOnError: false,
      );

      _socketConnected = true;
      debugPrint('[NOTIFICATION_HUB] socket connected');
    } catch (e) {
      debugPrint('[NOTIFICATION_HUB] connect failed: $e');
      _socketConnected = false;
      if (!_shutdown) _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_shutdown) return;

    _isStarted = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () async {
      if (_shutdown || _isStarting || _isStarted) return;
      if (!await AuthService.hasActiveSession()) return;

      debugPrint('[NOTIFICATION_HUB] Reconnecting socket…');
      await ensureStarted();
    });
  }

  void _handleSocketEvent(dynamic event) {
    try {
      final decoded = event is String ? jsonDecode(event) : event;

      if (decoded is! Map) return;

      final data = Map<String, dynamic>.from(decoded);
      final type = data['type']?.toString();

      if (type == 'connection_established') {
        debugPrint('[NOTIFICATION_HUB] ${data['message']}');
        return;
      }

      final rawNotification = _extractNotificationPayload(data);
      if (rawNotification == null) return;

      final notification = AppNotificationModel.fromJson(rawNotification);

      _emitIncomingNotification(notification);
    } catch (e) {
      debugPrint('[NOTIFICATION_HUB] Invalid event: $e');
    }
  }

  Map<String, dynamic>? _extractNotificationPayload(Map<String, dynamic> data) {
    final type = data['type']?.toString();

    if (type == 'new_notification' || type == 'notification') {
      final raw = data['notification'];
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
    }

    if (data.containsKey('title') && data.containsKey('body')) {
      return data;
    }

    return null;
  }

  void _emitIncomingNotification(AppNotificationModel notification) {
    unawaited(
      NotificationEnrichmentService.enrichOne(notification).then((enriched) {
        _notificationController.add(enriched);
        _applyUnreadDelta(enriched);
      }),
    );
  }

  /// Updates the bell badge immediately, then reconciles with the API.
  void _applyUnreadDelta(AppNotificationModel notification) {
    if (isInboxOpen) {
      unawaited(markAllAsRead());
      return;
    }

    if (!notification.isRead) {
      unreadCount = unreadCount + 1;
      _unreadCountController.add(unreadCount);
      debugPrint('[NOTIFICATION_HUB] badge bumped → $unreadCount');
    }

    unawaited(syncUnreadCount());
  }
}
