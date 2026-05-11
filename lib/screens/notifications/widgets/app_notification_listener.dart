// lib/screens/notifications/widgets/app_notification_listener.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/app_notification_model.dart';
import '../../../services/notification_service.dart';

class AppNotificationListener extends StatefulWidget {
  final Widget child;
  final ValueChanged<int>? onUnreadCountChanged;
  final VoidCallback? onOpenNotifications;

  const AppNotificationListener({
    super.key,
    required this.child,
    this.onUnreadCountChanged,
    this.onOpenNotifications,
  });

  @override
  State<AppNotificationListener> createState() =>
      _AppNotificationListenerState();
}

class _AppNotificationListenerState extends State<AppNotificationListener> {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _hideTimer;

  int _unreadCount = 0;
  bool _isBannerVisible = false;

  AppNotificationModel? _latestNotification;

  @override
  void initState() {
    super.initState();
    _bootstrapNotifications();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _bootstrapNotifications() async {
    await _syncUnreadCount();
    await _connectSocket();
  }

  Future<void> _syncUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount();

      if (!mounted) return;

      setState(() {
        _unreadCount = count;
      });

      widget.onUnreadCountChanged?.call(count);
    } catch (_) {
      // Silent sync should never disturb the current screen.
    }
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

      if (!mounted) return;

      final nextCount = _unreadCount + 1;

      setState(() {
        _unreadCount = nextCount;
        _latestNotification = notification;
        _isBannerVisible = true;
      });

      widget.onUnreadCountChanged?.call(nextCount);

      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 5), _hideBanner);
    } catch (e) {
      debugPrint('[NOTIFICATION_SOCKET] Invalid event: $e');
    }
  }

  void _hideBanner() {
    if (!mounted) return;

    _hideTimer?.cancel();

    setState(() {
      _isBannerVisible = false;
    });
  }

  void _openNotifications() {
    _hideBanner();
    widget.onOpenNotifications?.call();
  }

  @override
  Widget build(BuildContext context) {
    final notification = _latestNotification;

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: IgnorePointer(
            ignoring: !_isBannerVisible || notification == null,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              offset: _isBannerVisible && notification != null
                  ? Offset.zero
                  : const Offset(0, -1.25),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _isBannerVisible && notification != null ? 1 : 0,
                child: notification == null
                    ? const SizedBox.shrink()
                    : _NotificationBanner(
                        notification: notification,
                        onTap: _openNotifications,
                        onClose: _hideBanner,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  final AppNotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _NotificationBanner({
    required this.notification,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF22C55E);

    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    final backgroundColor =
        isDarkMode ? const Color(0xFF111827) : Colors.white;

    final primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF111827);

    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.56);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentGreen.withOpacity(isDarkMode ? 0.24 : 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.32 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(isDarkMode ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedNotification01,
                    color: accentGreen,
                    size: 23,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 14.8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12.8,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}