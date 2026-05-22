import 'package:flutter/material.dart';

import 'offers_app_bar.dart';

/// Fixed app bar metrics — same on all phone sizes.
abstract final class OffersAppBarLayout {
  static const double height = 64;
  static const double horizontalPadding = 16;
  static const double actionSize = 48;
  static const double iconSize = 22;
  static const double avatarOuter = 48;
  static const double avatarInner = 38;
  static const double hideDistance = 80;
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
  Size get preferredSize {
    if (!collapsible) {
      return const Size.fromHeight(OffersAppBarLayout.height);
    }

    final visibleHeight =
        OffersAppBarLayout.height * (1 - hideProgress.clamp(0.0, 1.0));

    return Size.fromHeight(visibleHeight);
  }

  @override
  Widget build(BuildContext context) {
    final opacity = collapsible ? (1 - hideProgress).clamp(0.0, 1.0) : 1.0;

    if (collapsible && opacity <= 0) {
      return const SizedBox.shrink();
    }

    return ClipRect(
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: collapsible ? opacity : 1,
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
