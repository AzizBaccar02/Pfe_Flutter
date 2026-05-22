// lib/screens/notifications/widgets/notification_inbox_tile.dart

import 'package:flutter/material.dart';

import '../../../models/app_notification_model.dart';
import '../../../services/profile_service.dart';

enum NotificationInboxResponse { none, accepted, rejected }

class NotificationInboxTile extends StatelessWidget {
  final AppNotificationModel notification;
  final NotificationInboxResponse localResponse;
  final bool isResponding;
  final Color accentGreen;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const NotificationInboxTile({
    super.key,
    required this.notification,
    required this.localResponse,
    required this.isResponding,
    required this.accentGreen,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    this.onTap,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final showActions = notification.canRespondInline &&
        localResponse == NotificationInboxResponse.none &&
        !isResponding;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActorAvatar(
                notification: notification,
                primaryTextColor: primaryTextColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ActionRichText(
                      notification: notification,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRelativeTime(notification.createdAt),
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (showActions) ...[
                      const SizedBox(height: 10),
                      _InlineActionButtons(
                        accentGreen: accentGreen,
                        onAccept: onAccept,
                        onReject: onReject,
                      ),
                    ],
                    if (isResponding) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentGreen,
                        ),
                      ),
                    ],
                    if (localResponse == NotificationInboxResponse.accepted) ...[
                      const SizedBox(height: 8),
                      Text(
                        'You accepted this interest.',
                        style: TextStyle(
                          color: accentGreen,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (localResponse == NotificationInboxResponse.rejected) ...[
                      const SizedBox(height: 8),
                      Text(
                        'You declined this interest.',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'a moment ago';
    if (diff.inHours < 1) {
      return diff.inMinutes == 1
          ? '1 minute ago'
          : '${diff.inMinutes} minutes ago';
    }
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    }
    if (diff.inDays < 7) {
      return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ActorAvatar extends StatelessWidget {
  final AppNotificationModel notification;
  final Color primaryTextColor;

  const _ActorAvatar({
    required this.notification,
    required this.primaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    final resolved = ProfileService.resolveMediaUrl(
      notification.avatarUrl?.trim() ?? '',
    );

    if (resolved != null && resolved.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          resolved,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialsAvatar(
            initials: notification.avatarInitials,
            primaryTextColor: primaryTextColor,
          ),
        ),
      );
    }

    return _InitialsAvatar(
      initials: notification.avatarInitials,
      primaryTextColor: primaryTextColor,
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final Color primaryTextColor;

  const _InitialsAvatar({
    required this.initials,
    required this.primaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF1F2937),
      child: Text(
        initials,
        style: TextStyle(
          color: primaryTextColor.withOpacity(0.88),
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionRichText extends StatelessWidget {
  final AppNotificationModel notification;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const _ActionRichText({
    required this.notification,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: secondaryTextColor,
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(
            text: notification.actorDisplayName,
            style: TextStyle(
              color: primaryTextColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: ' ${notification.actionLabel}'),
        ],
      ),
    );
  }
}

class _InlineActionButtons extends StatelessWidget {
  final Color accentGreen;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _InlineActionButtons({
    required this.accentGreen,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionIconButton(
          icon: Icons.check_rounded,
          color: accentGreen,
          onPressed: onAccept,
        ),
        const SizedBox(width: 20),
        _ActionIconButton(
          icon: Icons.close_rounded,
          color: const Color(0xFFEF4444),
          onPressed: onReject,
        ),
      ],
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
      ),
    );
  }
}
