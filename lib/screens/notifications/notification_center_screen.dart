import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../conf/theme_provider.dart';
import '../../data/mock_notification_data.dart';
import 'widgets/notification_empty_state.dart';
import 'widgets/notification_tile.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  void _markAllRead() {
    setState(() {
      MockNotificationData.markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final items = MockNotificationData.all;

    const accentGreen = Color(0xFF22C55E);

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);
    final cardColor =
        isDarkMode ? const Color(0xFF141414) : const Color(0xFFF5F5F5);
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    final unreadCount = MockNotificationData.unreadCount;
    final neutralIconColor = isDarkMode
        ? Colors.white.withOpacity(0.78)
        : Colors.black.withOpacity(0.78);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: primaryTextColor,
            size: 20,
          ),
        ),
        centerTitle: true,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.w800,
            fontSize: 21,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: primaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: items.isEmpty
            ? NotificationEmptyState(isDarkMode: isDarkMode)
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: accentGreen.withOpacity(
                              isDarkMode ? 0.10 : 0.14,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedNotification03,
                              color: neutralIconColor,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unreadCount > 0
                                    ? '$unreadCount unread updates'
                                    : 'All caught up',
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                unreadCount > 0
                                    ? 'New activity from chats, matches, and offers is waiting for you.'
                                    : 'You have no unread activity right now.',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 13.5,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NotificationTile(
                        notification: item,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          setState(() {
                            MockNotificationData.markAsRead(item.id);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}