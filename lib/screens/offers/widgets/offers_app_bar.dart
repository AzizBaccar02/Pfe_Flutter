import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/user_profile_provider.dart';
import 'offers_app_bar_layout.dart';

/// Standard app bar: profile (left), notifications (right).
class OffersAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDarkMode;
  final int notificationUnreadCount;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;

  const OffersAppBar({
    super.key,
    required this.isDarkMode,
    required this.onProfileTap,
    required this.onNotificationTap,
    this.notificationUnreadCount = 0,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(OffersAppBarLayout.totalHeight);

  Color get _background => isDarkMode ? Colors.black : Colors.white;

  Color get _borderSubtle => isDarkMode
      ? const Color(0xFF3A3A3C)
      : const Color(0xFFE5E7EB);

  Color get _surface =>
      isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF9FAFB);

  Color get _iconMuted => isDarkMode
      ? Colors.white.withValues(alpha: 0.92)
      : const Color(0xFF6B7280);

  SystemUiOverlayStyle get _overlayStyle => isDarkMode
      ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
      : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent);

  ImageProvider? _imageProvider(UserProfileProvider provider) {
    final remoteUrl = provider.remoteProfileImageUrl;
    final localPath = provider.localProfileImagePath;

    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      return NetworkImage(remoteUrl);
    }

    if (localPath != null && localPath.isNotEmpty) {
      return FileImage(File(localPath));
    }

    return null;
  }

  Widget _profileButton(UserProfileProvider profileProvider) {
    final image = _imageProvider(profileProvider);
    final hasPhoto = image != null;
    final accent = AppColors.forTheme(isDarkMode);

    return Semantics(
      button: true,
      label: 'Open menu',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onProfileTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: OffersAppBarLayout.avatarTouchSize,
            height: OffersAppBarLayout.avatarTouchSize,
            child: Center(
              child: Container(
                width: OffersAppBarLayout.avatarSize,
                height: OffersAppBarLayout.avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: hasPhoto
                      ? null
                      : Border.all(color: _borderSubtle, width: 1.5),
                ),
                child: ClipOval(
                  child: image != null
                      ? Image(
                          image: image,
                          fit: BoxFit.cover,
                          width: OffersAppBarLayout.avatarSize,
                          height: OffersAppBarLayout.avatarSize,
                          filterQuality: FilterQuality.medium,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) =>
                              _avatarPlaceholder(accent),
                          frameBuilder:
                              (context, child, frame, wasSyncLoaded) {
                            if (wasSyncLoaded || frame != null) return child;
                            return ColoredBox(
                              color: _surface,
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accent,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : _avatarPlaceholder(accent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  AppColors.accent.withValues(alpha: 0.2),
                  const Color(0xFF1F2937),
                ]
              : [
                  AppColors.accentSurface,
                  const Color(0xFFECFDF5),
                ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: accent,
          size: OffersAppBarLayout.iconSize,
        ),
      ),
    );
  }

  Widget _notificationButton() {
    return Semantics(
      button: true,
      label: notificationUnreadCount > 0
          ? 'Notifications, $notificationUnreadCount unread'
          : 'Notifications',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onNotificationTap,
          borderRadius:
              BorderRadius.circular(OffersAppBarLayout.actionRadius),
          child: Ink(
            width: OffersAppBarLayout.actionSize,
            height: OffersAppBarLayout.actionSize,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius:
                  BorderRadius.circular(OffersAppBarLayout.actionRadius),
              border: Border.all(color: _borderSubtle),
              boxShadow: isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedNotification01,
                  color: _iconMuted,
                  size: OffersAppBarLayout.iconSize,
                ),
                if (notificationUnreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: _NotificationBadge(
                      count: notificationUnreadCount,
                      borderColor: _background,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<UserProfileProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: AppBar(
        toolbarHeight: OffersAppBarLayout.height,
        backgroundColor: _background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: OffersAppBarLayout.horizontalPadding +
            OffersAppBarLayout.avatarTouchSize,
        leading: Padding(
          padding: const EdgeInsets.only(
            left: OffersAppBarLayout.horizontalPadding,
          ),
          child: Center(
            child: _profileButton(profileProvider),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: OffersAppBarLayout.horizontalPadding,
            ),
            child: Center(child: _notificationButton()),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            OffersAppBarLayout.dividerHeight,
          ),
          child: Container(
            height: OffersAppBarLayout.dividerHeight,
            color: _borderSubtle,
          ),
        ),
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  final int count;
  final Color borderColor;

  const _NotificationBadge({
    required this.count,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          height: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
