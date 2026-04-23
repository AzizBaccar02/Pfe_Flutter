import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/user_profile_provider.dart';

class OffersAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDarkMode;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final String? fallbackAssetPath;
  final bool showNotificationDot;

  const OffersAppBar({
    super.key,
    required this.isDarkMode,
    required this.onProfileTap,
    required this.onNotificationTap,
    this.fallbackAssetPath,
    this.showNotificationDot = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _buildProfileImage(String? imagePath) {
    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
      );
    }

    if (fallbackAssetPath != null && fallbackAssetPath!.isNotEmpty) {
      return Image.asset(
        fallbackAssetPath!,
        fit: BoxFit.cover,
      );
    }

    return Center(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedUser,
        color: isDarkMode
            ? Colors.white.withOpacity(0.72)
            : Colors.black.withOpacity(0.72),
        size: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentYellow = Color(0xFFFFC107);

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final profileProvider = Provider.of<UserProfileProvider>(context);
    final profileImagePath = profileProvider.profileImagePath;

    final shellColor = isDarkMode
        ? accentYellow.withOpacity(0.10)
        : accentYellow.withOpacity(0.14);

    final innerShellColor = isDarkMode
        ? accentYellow.withOpacity(0.12)
        : accentYellow.withOpacity(0.18);

    final neutralIconColor = isDarkMode
        ? Colors.white.withOpacity(0.72)
        : Colors.black.withOpacity(0.72);

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leadingWidth: 74,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: GestureDetector(
          onTap: onProfileTap,
          child: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: shellColor,
              border: Border.all(
                color: accentYellow.withOpacity(isDarkMode ? 0.24 : 0.34),
              ),
            ),
            child: Center(
              child: Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: innerShellColor,
                ),
                child: ClipOval(
                  child: _buildProfileImage(profileImagePath),
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: onNotificationTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: shellColor,
                    border: Border.all(
                      color: accentYellow.withOpacity(isDarkMode ? 0.24 : 0.34),
                    ),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedNotification01,
                      color: neutralIconColor,
                      size: 18,
                    ),
                  ),
                ),
                if (showNotificationDot)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: accentYellow,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentYellow.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
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