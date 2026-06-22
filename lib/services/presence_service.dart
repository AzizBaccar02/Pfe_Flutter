// lib/services/presence_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'chat_realtime_hub.dart';

/// Keeps the signed-in user marked online while the app session is active.
abstract final class PresenceService {
  /// Django uses inbox WebSocket (`/ws/chats/inbox/`) only — no REST presence routes.
  /// Set to `true` if you add POST `/api/users/me/online/` (etc.) on the backend.
  static const bool useRestPresence = false;

  static Timer? _heartbeatTimer;
  static bool _active = false;
  /// When every REST presence path returns 404, skip further heartbeat POSTs.
  static bool _restPresenceUnavailable = false;

  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _requestTimeout = Duration(seconds: 4);

  static final List<String> _onlinePaths = [
    '/api/users/me/online/',
    '/api/users/presence/online/',
    '/api/chats/presence/online/',
    '/api/presence/online/',
  ];

  static final List<String> _offlinePaths = [
    '/api/users/me/offline/',
    '/api/users/presence/offline/',
    '/api/chats/presence/offline/',
    '/api/presence/offline/',
  ];

  /// Call after login or when restoring an existing session.
  static Future<void> activate() async {
    if (!await AuthService.hasActiveSession()) return;

    if (_active) {
      await refreshOnline();
      return;
    }

    _active = true;

    // Never block login/navigation on optional REST presence or socket setup.
    unawaited(_setPresenceOnline());
    unawaited(ChatRealtimeHub.instance.ensureStarted());

    _startHeartbeat();
    debugPrint('[PRESENCE] activated');
  }

  /// Call before clearing auth tokens (logout).
  static Future<void> shutdown() async {
    _active = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    await ChatRealtimeHub.instance.shutdown();
    unawaited(_setPresenceOffline());

    debugPrint('[PRESENCE] shutdown');
  }

  static Future<void> deactivate() => shutdown();

  /// Refresh online status (app resumed, tab opened).
  static Future<void> refreshOnline() async {
    if (!_active || !await AuthService.hasActiveSession()) return;
    unawaited(_setPresenceOnline());
    unawaited(ChatRealtimeHub.instance.ensureStarted());
  }

  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (!_active) return;
      unawaited(_setPresenceOnline(silent: true));
    });
  }

  static Future<void> _setPresenceOnline({bool silent = false}) async {
    if (!useRestPresence || _restPresenceUnavailable) return;

    final ok = await _postFirstSuccess(_onlinePaths, silent: silent);
    if (!silent) {
      debugPrint(
        ok
            ? '[PRESENCE] marked online via REST'
            : '[PRESENCE] online REST skipped (inbox socket may still apply)',
      );
    }
  }

  static Future<void> _setPresenceOffline() async {
    if (!useRestPresence || _restPresenceUnavailable) return;

    final ok = await _postFirstSuccess(_offlinePaths);
    debugPrint(
      ok
          ? '[PRESENCE] marked offline via REST'
          : '[PRESENCE] offline REST skipped (socket disconnect may still apply)',
    );
  }

  static Future<bool> _postFirstSuccess(
    List<String> paths, {
    bool silent = false,
  }) async {
    var onlyMissingEndpoints = true;

    for (final path in paths) {
      try {
        final response = await _authorizedPost(path);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          _restPresenceUnavailable = false;
          return true;
        }
        if (response.statusCode == 404 || response.statusCode == 405) {
          continue;
        }
        onlyMissingEndpoints = false;
      } catch (e) {
        onlyMissingEndpoints = false;
        if (!silent) {
          debugPrint('[PRESENCE] POST $path failed: $e');
        }
      }
    }

    if (onlyMissingEndpoints) {
      _restPresenceUnavailable = true;
    }

    return false;
  }

  static Future<http.Response> _authorizedPost(String path) async {
    final token = await AuthService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw StateError('No access token');
    }

    final uri = AuthService.apiUri(path);
    return http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(const {}),
        )
        .timeout(_requestTimeout);
  }
}
