// lib/screens/notifications/widgets/app_notification_listener.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../models/app_notification_model.dart';
import '../../../models/interested_agent_model.dart';
import '../../../services/notification_realtime_hub.dart';
import '../../../services/notification_router.dart';

class AppNotificationListener extends StatefulWidget {
  final Widget child;
  final ValueChanged<int>? onUnreadCountChanged;
  final VoidCallback? onOpenNotifications;
  final ValueChanged<InterestedAgentModel>? onAgentAccepted;

  const AppNotificationListener({
    super.key,
    required this.child,
    this.onUnreadCountChanged,
    this.onOpenNotifications,
    this.onAgentAccepted,
  });

  @override
  State<AppNotificationListener> createState() =>
      _AppNotificationListenerState();
}

class _AppNotificationListenerState extends State<AppNotificationListener> {
  final NotificationRealtimeHub _hub = NotificationRealtimeHub.instance;

  StreamSubscription<AppNotificationModel>? _notificationSubscription;
  StreamSubscription<int>? _unreadSubscription;
  Timer? _hideTimer;

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
    _notificationSubscription?.cancel();
    _unreadSubscription?.cancel();
    super.dispose();
  }

  Future<void> _bootstrapNotifications() async {
    await _hub.ensureStarted();

    if (!mounted) return;

    _unreadSubscription = _hub.onUnreadCountChanged.listen((count) {
      if (!mounted) return;

      widget.onUnreadCountChanged?.call(count);
    });

    _notificationSubscription = _hub.onNotification.listen((notification) {
      if (!mounted || _hub.isInboxOpen) return;

      setState(() {
        _latestNotification = notification;
        _isBannerVisible = true;
      });

      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 5), _hideBanner);
    });

    widget.onUnreadCountChanged?.call(_hub.unreadCount);
  }

  void _hideBanner() {
    if (!mounted) return;

    _hideTimer?.cancel();

    setState(() {
      _isBannerVisible = false;
    });
  }

  Future<void> _openNotification(AppNotificationModel notification) async {
    _hideBanner();

    if (notification.isActionable) {
      final acceptedAgent =
          await NotificationRouter.handle(context, notification);

      if (acceptedAgent != null) {
        widget.onAgentAccepted?.call(acceptedAgent);
      }

      return;
    }

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
                        onTap: () => _openNotification(notification),
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
    const backgroundColor = Color(0xFF141414);
    const primaryTextColor = Colors.white;
    const secondaryTextColor = Color(0xFF9CA3AF);

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
              color: accentGreen.withOpacity(0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
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
                  color: accentGreen.withOpacity(0.14),
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
                    color: Colors.white.withOpacity(0.08),
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
