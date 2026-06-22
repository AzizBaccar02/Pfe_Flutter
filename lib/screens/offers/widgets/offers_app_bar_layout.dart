import 'package:flutter/material.dart';

import 'offers_app_bar.dart';

/// Shared app bar metrics.
abstract final class OffersAppBarLayout {
  static const double height = kToolbarHeight;
  static const double dividerHeight = 0;
  static const double totalHeight = height + dividerHeight;
  static const double horizontalPadding = 16;
  static const double actionSize = 40;
  static const double iconSize = 20;
  static const double actionRadius = 12;
  static const double avatarSize = 34;
  static const double avatarTouchSize = 40;
  static const double hideDistance = 80;

  /// Top inset for overlays (status bar + app bar).
  static double headerHeight(BuildContext context) {
    return MediaQuery.paddingOf(context).top + totalHeight;
  }

  @Deprecated('Use totalHeight')
  static const double toolbarHeight = totalHeight;

  @Deprecated('Use avatarSize')
  static const double avatarOuter = avatarTouchSize;

  @Deprecated('Use avatarSize')
  static const double avatarInner = avatarSize;
}

/// Hides the app bar when scrolling down, reveals when scrolling up.
class OffersAppBarScrollBehavior {
  double hideProgress = 0;
  double _lastOffset = 0;

  void reset() {
    hideProgress = 0;
    _lastOffset = 0;
  }

  bool handle(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      final offset = notification.metrics.pixels;

      if (offset <= 0) {
        if (hideProgress != 0) {
          hideProgress = 0;
          _lastOffset = 0;
          return true;
        }
        return false;
      }

      if (notification is! ScrollUpdateNotification) {
        return false;
      }

      final delta = offset - _lastOffset;
      _lastOffset = offset;

      if (delta.abs() < 0.5) return false;

      final change = delta / OffersAppBarLayout.hideDistance;
      final next = (hideProgress + change).clamp(0.0, 1.0);

      if ((next - hideProgress).abs() < 0.01) return false;

      hideProgress = next;
      return true;
    }

    return false;
  }
}

/// Home-tab header overlay (collapses on scroll).
class OffersAppBarOverlay extends StatelessWidget {
  final bool isDarkMode;
  final int notificationUnreadCount;
  final double hideProgress;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;

  const OffersAppBarOverlay({
    super.key,
    required this.isDarkMode,
    required this.onProfileTap,
    required this.onNotificationTap,
    this.notificationUnreadCount = 0,
    this.hideProgress = 0,
  });

  @override
  Widget build(BuildContext context) {
    final progress = hideProgress.clamp(0.0, 1.0);
    final visibleHeight = OffersAppBarLayout.totalHeight * (1 - progress);

    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: visibleHeight <= 0 ? 0 : 1,
        child: SizedBox(
          height: visibleHeight > 0 ? visibleHeight : 0,
          child: Opacity(
            opacity: 1 - progress,
            child: OffersAppBar(
              isDarkMode: isDarkMode,
              notificationUnreadCount: notificationUnreadCount,
              onProfileTap: onProfileTap,
              onNotificationTap: onNotificationTap,
            ),
          ),
        ),
      ),
    );
  }
}

class CollapsibleOffersAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final bool isDarkMode;
  final int notificationUnreadCount;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final double hideProgress;
  final bool collapsible;

  const CollapsibleOffersAppBar({
    super.key,
    required this.isDarkMode,
    required this.onProfileTap,
    required this.onNotificationTap,
    this.notificationUnreadCount = 0,
    this.hideProgress = 0,
    this.collapsible = true,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(OffersAppBarLayout.totalHeight);

  @override
  Widget build(BuildContext context) {
    if (!collapsible) {
      return OffersAppBar(
        isDarkMode: isDarkMode,
        notificationUnreadCount: notificationUnreadCount,
        onProfileTap: onProfileTap,
        onNotificationTap: onNotificationTap,
      );
    }

    final opacity = (1 - hideProgress).clamp(0.0, 1.0);

    if (opacity <= 0) {
      return const SizedBox.shrink();
    }

    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: opacity,
        child: Opacity(
          opacity: opacity,
          child: OffersAppBar(
            isDarkMode: isDarkMode,
            notificationUnreadCount: notificationUnreadCount,
            onProfileTap: onProfileTap,
            onNotificationTap: onNotificationTap,
          ),
        ),
      ),
    );
  }
}
