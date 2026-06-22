// lib/screens/notifications/widgets/notification_inbox_tile.dart

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

import '../../../models/app_notification_model.dart';
import '../../../services/interaction_notification_flow.dart';
import '../../../services/profile_service.dart';

enum NotificationInboxResponse { none, accepted, rejected }

class NotificationInboxTile extends StatelessWidget {
  final AppNotificationModel notification;
  final NotificationInboxResponse localResponse;
  final String? reactionStatus;
  final String? statusNote;
  final Color accentGreen;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color avatarBackgroundColor;
  final bool isDarkMode;
  final VoidCallback? onTap;

  const NotificationInboxTile({
    super.key,
    required this.notification,
    required this.localResponse,
    this.reactionStatus,
    this.statusNote,
    required this.accentGreen,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    this.avatarBackgroundColor = const Color(0xFF1F2937),
    this.isDarkMode = true,
    this.onTap,
  });

  bool get _isUnread => !notification.isRead;

  @override
  Widget build(BuildContext context) {
    final unreadBackground = isDarkMode
        ? AppColors.accent.withValues(alpha: 0.08)
        : AppColors.accentSurface;
    final unreadBorder = AppColors.accent.withValues(
      alpha: isDarkMode ? 0.35 : 0.45,
    );

    return Material(
      color: _isUnread ? unreadBackground : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: _isUnread
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: unreadBorder, width: 3),
                  ),
                )
              : null,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActorAvatar(
                notification: notification,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                avatarBackgroundColor: avatarBackgroundColor,
                accentGreen: accentGreen,
                showUnreadRing: _isUnread,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ActionRichText(
                      notification: notification,
                      reactionStatus: reactionStatus,
                      localResponse: localResponse,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      accentGreen: accentGreen,
                      isUnread: _isUnread,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRelativeTime(notification.createdAt),
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight:
                            _isUnread ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (statusNote != null && statusNote!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        statusNote!,
                        style: TextStyle(
                          color: accentGreen.withValues(alpha: 0.9),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (localResponse == NotificationInboxResponse.accepted &&
                        (statusNote == null || statusNote!.trim().isEmpty)) ...[
                      const SizedBox(height: 8),
                      Text(
                        'You accepted this interest.',
                        style: TextStyle(
                          color: accentGreen.withValues(alpha: 0.85),
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
              if (_isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
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
  final Color secondaryTextColor;
  final Color avatarBackgroundColor;
  final Color accentGreen;
  final bool showUnreadRing;

  const _ActorAvatar({
    required this.notification,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.avatarBackgroundColor,
    required this.accentGreen,
    this.showUnreadRing = false,
  });

  @override
  Widget build(BuildContext context) {
    const size = 44.0;

    if (notification.isAgentRatingNotification) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: avatarBackgroundColor,
            child: Icon(
              Icons.star_rounded,
              color: const Color(0xFFF59E0B),
              size: 26,
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: accentGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: avatarBackgroundColor,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    final hidePhoto = notification.isAgentInterestNotification;

    final resolved = hidePhoto
        ? null
        : ProfileService.resolveMediaUrl(
            notification.avatarUrl?.trim() ?? '',
          );

    Widget avatarFace;

    if (!hidePhoto && resolved != null && resolved.isNotEmpty) {
      avatarFace = ClipOval(
        child: Image.network(
          resolved,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialsAvatar(
            initials: notification.avatarInitials,
            initialsColor: _initialsColor,
            avatarBackgroundColor: avatarBackgroundColor,
          ),
        ),
      );
    } else {
      avatarFace = _InitialsAvatar(
        initials: notification.avatarInitials,
        initialsColor: _initialsColor,
        avatarBackgroundColor: avatarBackgroundColor,
      );
    }

    if (!showUnreadRing) return avatarFace;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accentGreen, width: 2),
      ),
      child: avatarFace,
    );
  }

  Color get _initialsColor {
    if (notification.isClientMatchNotification) {
      return accentGreen.withValues(alpha: 0.9);
    }
    return primaryTextColor.withValues(alpha: 0.88);
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final Color initialsColor;
  final Color avatarBackgroundColor;

  const _InitialsAvatar({
    required this.initials,
    required this.initialsColor,
    required this.avatarBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: avatarBackgroundColor,
      child: Text(
        initials,
        style: TextStyle(
          color: initialsColor,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionRichText extends StatelessWidget {
  final AppNotificationModel notification;
  final String? reactionStatus;
  final NotificationInboxResponse localResponse;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentGreen;
  final bool isUnread;

  const _ActionRichText({
    required this.notification,
    required this.reactionStatus,
    required this.localResponse,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentGreen,
    this.isUnread = false,
  });

  String? get _effectiveStatus {
    if (localResponse == NotificationInboxResponse.accepted) {
      return 'ACCEPTED';
    }
    if (localResponse == NotificationInboxResponse.rejected) {
      return 'REJECTED';
    }
    return reactionStatus;
  }

  bool get _isAccepted =>
      InteractionNotificationFlow.isAccepted(_effectiveStatus);

  bool get _highlightActorName =>
      _isAccepted ||
      notification.isClientMatchNotification ||
      notification.isAgentRatingNotification;

  @override
  Widget build(BuildContext context) {
    final bodyWeight = isUnread ? FontWeight.w600 : FontWeight.w500;
    final nameWeight = isUnread ? FontWeight.w900 : FontWeight.w800;

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isUnread ? primaryTextColor : secondaryTextColor,
          fontSize: 14,
          height: 1.35,
          fontWeight: bodyWeight,
        ),
        children: [
          TextSpan(
            text: notification.actorDisplayName,
            style: TextStyle(
              color: _highlightActorName ? accentGreen : primaryTextColor,
              fontWeight: nameWeight,
            ),
          ),
          TextSpan(
            text:
                ' ${notification.inboxActionLabel(reactionStatus: _effectiveStatus)}',
            style: TextStyle(
              color: isUnread ? primaryTextColor : secondaryTextColor,
              fontWeight: bodyWeight,
            ),
          ),
        ],
      ),
    );
  }
}
