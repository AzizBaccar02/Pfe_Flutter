import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/app_colors.dart';
import '../../../conf/user_profile_provider.dart';
import 'offers_app_bar_layout.dart';

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
  Size get preferredSize => const Size.fromHeight(OffersAppBarLayout.height);

  Widget _emptyAvatar() {
    return Center(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedUser,
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.black.withValues(alpha: 0.7),
        size: OffersAppBarLayout.iconSize,
      ),
    );
  }

  Widget _buildProfileImage(UserProfileProvider profileProvider) {
    final localPath = profileProvider.localProfileImagePath;
    final remoteUrl = profileProvider.remoteProfileImageUrl;

    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
      );
    }

    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      return Image.network(
        remoteUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _emptyAvatar(),
      );
    }

    return _emptyAvatar();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final profileProvider = Provider.of<UserProfileProvider>(context);

    return AppBar(
      toolbarHeight: OffersAppBarLayout.height,
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leadingWidth: OffersAppBarLayout.actionSize +
          OffersAppBarLayout.horizontalPadding,
      leading: Padding(
        padding: const EdgeInsets.only(
          left: OffersAppBarLayout.horizontalPadding,
        ),
        child: GestureDetector(
          onTap: onProfileTap,
          child: Container(
            height: OffersAppBarLayout.avatarOuter,
            width: OffersAppBarLayout.avatarOuter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Container(
                height: OffersAppBarLayout.avatarInner,
                width: OffersAppBarLayout.avatarInner,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                child: ClipOval(
                  child: _buildProfileImage(profileProvider),
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(
            right: OffersAppBarLayout.horizontalPadding,
          ),
          child: GestureDetector(
            onTap: onNotificationTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: OffersAppBarLayout.actionSize,
                  width: OffersAppBarLayout.actionSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedNotification01,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.7),
                      size: OffersAppBarLayout.iconSize,
                    ),
                  ),
                ),
                if (notificationUnreadCount > 0)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: _NotificationBadge(
                      count: notificationUnreadCount,
                      borderColor: backgroundColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
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
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
