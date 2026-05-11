// lib/screens/notifications/notifications_screen.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../conf/theme_provider.dart';
import '../../models/app_notification_model.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onNotificationsRead;

  const NotificationsScreen({
    super.key,
    this.onNotificationsRead,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  WebSocketChannel? _notificationChannel;
  StreamSubscription<dynamic>? _notificationSubscription;

  bool _isLoading = true;
  String? _errorMessage;
  List<AppNotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _bootstrapNotificationsScreen();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _notificationChannel?.sink.close();
    super.dispose();
  }

  Future<void> _bootstrapNotificationsScreen() async {
    await _loadNotifications(markRead: true);
    await _connectNotificationSocket();
  }

  Future<void> _connectNotificationSocket() async {
    try {
      await _notificationSubscription?.cancel();
      await _notificationChannel?.sink.close();

      final channel = await NotificationService.connectToNotificationSocket();

      _notificationChannel = channel;

      _notificationSubscription = channel.stream.listen(
        _handleNotificationSocketEvent,
        onError: (_) {},
        onDone: () {},
        cancelOnError: false,
      );
    } catch (_) {
      // The screen can still show loaded notifications if the socket fails.
    }
  }

  void _handleNotificationSocketEvent(dynamic event) {
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
      ).copyWith(isRead: true);

      if (!mounted) return;

      setState(() {
        final alreadyExists = _notifications.any(
          (item) => item.id == notification.id,
        );

        if (!alreadyExists) {
          _notifications = [
            notification,
            ..._notifications,
          ];
        }
      });

      _markNotificationsReadSilently();
    } catch (e) {
      debugPrint('[NOTIFICATIONS_SCREEN_SOCKET] Invalid event: $e');
    }
  }

  Future<void> _markNotificationsReadSilently() async {
    try {
      await NotificationService.markAllAsRead();
      widget.onNotificationsRead?.call();
    } catch (_) {
      // Do not disturb the notification screen.
    }
  }

  Future<void> _loadNotifications({bool markRead = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifications = await NotificationService.getMyNotifications();

      if (markRead && notifications.any((item) => !item.isRead)) {
        await NotificationService.markAllAsRead();
        widget.onNotificationsRead?.call();
      }

      if (!mounted) return;

      setState(() {
        _notifications = notifications
            .map((item) => item.copyWith(isRead: true))
            .toList();
      });
    } on NotificationServiceException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load notifications.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openNotificationDetails(AppNotificationModel notification) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _NotificationDetailsSheet(
          notification: notification,
          isDarkMode: isDarkMode,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    const accentGreen = Color(0xFF22C55E);

    final backgroundColor =
        isDarkMode ? const Color(0xFF0B0F14) : const Color(0xFFF3F4F6);

    final appBarColor = isDarkMode ? const Color(0xFF0B0F14) : Colors.white;

    final primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF111827);

    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.58)
        : Colors.black.withOpacity(0.54);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: accentGreen,
            size: 18,
          ),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: _buildBody(
        isDarkMode: isDarkMode,
        accentGreen: accentGreen,
        primaryTextColor: primaryTextColor,
        secondaryTextColor: secondaryTextColor,
      ),
    );
  }

  Widget _buildBody({
    required bool isDarkMode,
    required Color accentGreen,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: accentGreen,
          strokeWidth: 2.4,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedNotification01,
                  color: accentGreen,
                  size: 34,
                ),
                const SizedBox(height: 18),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Important updates about messages, proposals, and matches will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: accentGreen,
      onRefresh: () => _loadNotifications(markRead: true),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notification = _notifications[index];

          return _NotificationTile(
            notification: notification,
            isDarkMode: isDarkMode,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            onTap: () => _openNotificationDetails(notification),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationModel notification;
  final bool isDarkMode;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isDarkMode,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF22C55E);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.14 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13.2,
                        height: 1.42,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatDate(notification.createdAt),
                      style: TextStyle(
                        color: secondaryTextColor.withOpacity(0.72),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: secondaryTextColor.withOpacity(0.72),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}

class _NotificationDetailsSheet extends StatelessWidget {
  final AppNotificationModel notification;
  final bool isDarkMode;

  const _NotificationDetailsSheet({
    required this.notification,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF22C55E);

    final backgroundColor =
        isDarkMode ? const Color(0xFF111827) : Colors.white;

    final cardColor =
        isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);

    final primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF111827);

    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.56);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.26),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryTextColor.withOpacity(0.34),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: accentGreen.withOpacity(isDarkMode ? 0.16 : 0.10),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedNotification01,
                  color: accentGreen,
                  size: 29,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              notification.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                notification.body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _formatFullDate(notification.createdAt),
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatFullDate(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.day}/${date.month}/${date.year} at $hour:$minute';
  }
}