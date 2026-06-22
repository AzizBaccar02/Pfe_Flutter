// lib/services/chat_realtime_hub.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'auth_service.dart';
import 'chat_service.dart';

/// Single shared inbox WebSocket for chat list updates and global banners.
class ChatRealtimeHub {
  ChatRealtimeHub._();

  static final ChatRealtimeHub instance = ChatRealtimeHub._();

  final StreamController<Map<String, dynamic>> _inboxEventController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onInboxEvent => _inboxEventController.stream;

  bool _isStarting = false;
  bool _isStarted = false;
  bool _shutdown = false;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;

  static bool isMessageRelatedEvent(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';

    return type == 'new_message' ||
        type == 'message_created' ||
        type == 'chat_message' ||
        type == 'chat_list_updated' ||
        type == 'chat_updated' ||
        type == 'chat_summary_updated';
  }

  Future<void> ensureStarted() async {
    if (_shutdown || _isStarted || _isStarting) return;
    if (!await AuthService.hasActiveSession()) return;

    _isStarting = true;

    try {
      await _connectSocket();
      if (!_shutdown) {
        _isStarted = true;
      }
    } finally {
      _isStarting = false;
    }
  }

  Future<void> stop() => shutdown();

  /// Stops inbox socket and blocks auto-reconnect (logout).
  Future<void> shutdown() async {
    _shutdown = true;
    _isStarted = false;
    _isStarting = false;
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

  void _allowReconnectAfterLogin() {
    _shutdown = false;
  }

  Future<void> _connectSocket() async {
    if (_shutdown || !await AuthService.hasActiveSession()) return;

    try {
      await _subscription?.cancel();
      try {
        _channel?.sink.close();
      } catch (_) {}

      final channel = await ChatService.connectToUserChatsInboxSocket();
      if (_shutdown) {
        channel.sink.close();
        return;
      }
      _channel = channel;

      _subscription = channel.stream.listen(
        _handleSocketEvent,
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[CHAT_HUB] connect failed: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_shutdown || !_isStarted) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_shutdown || !_isStarted) return;
      unawaited(_connectSocket());
    });
  }

  /// Call after a successful login so [ensureStarted] can run again.
  static void resetForNewSession() {
    instance._allowReconnectAfterLogin();
  }

  void _handleSocketEvent(dynamic event) {
    try {
      final decoded = event is String ? jsonDecode(event) : event;

      if (decoded is! Map) return;

      _inboxEventController.add(Map<String, dynamic>.from(decoded));
    } catch (e) {
      debugPrint('[CHAT_HUB] Invalid event: $e');
    }
  }
}
