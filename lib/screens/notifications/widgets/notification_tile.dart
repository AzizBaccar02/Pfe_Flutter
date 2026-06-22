import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../models/app_notification_model.dart';

class NotificationTile extends StatelessWidget {
  final AppNotificationModel notification;
  final bool isDarkMode;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = AppColors.accent;

    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);

    final neutralIconColor = isDarkMode
        ? Colors.white.withOpacity(0.78)
        : Colors.black.withOpacity(0.78);

    final cardColor = notification.isRead
        ? (isDarkMode ? const Color(0xFF141414) : const Color(0xFFF6F6F6))
        : (isDarkMode ? const Color(0xFF181818) : AppColors.accentSurface);

    final borderColor = notification.isRead
        ? (isDarkMode
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.06))
        : accentGreen.withOpacity(isDarkMode ? 0.18 : 0.24);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accentGreen.withOpacity(isDarkMode ? 0.10 : 0.14),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: HugeIcon(
                  icon: _iconForType(notification.type),
                  color: neutralIconColor,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (!notification.isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: accentGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentGreen.withOpacity(0.34),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static dynamic _iconForType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.message:
        return HugeIcons.strokeRoundedMessage02;
      case AppNotificationType.match:
        return HugeIcons.strokeRoundedFavourite;
      case AppNotificationType.agentLikedOffer:
        return HugeIcons.strokeRoundedUserLove01;
      case AppNotificationType.clientRejected:
        return HugeIcons.strokeRoundedCancel01;
      case AppNotificationType.offer:
        return HugeIcons.strokeRoundedWork;
      case AppNotificationType.agentRated:
        return HugeIcons.strokeRoundedStar;
      case AppNotificationType.system:
        return HugeIcons.strokeRoundedNotification03;
    }
  }

  static String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}