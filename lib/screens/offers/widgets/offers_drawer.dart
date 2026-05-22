import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/user_profile_provider.dart';
import '../../../data/mock_client_data.dart';
import '../../auth/client/client_profile_screen.dart';
import '../../settings/settings_screen.dart';
import 'offers_drawer_item.dart';

class OffersDrawer extends StatelessWidget {
  final bool isDarkMode;

  const OffersDrawer({
    super.key,
    required this.isDarkMode,
  });

  Widget _emptyAvatar() {
    return Center(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedUser,
        color: isDarkMode
            ? Colors.white.withOpacity(0.7)
            : Colors.black.withOpacity(0.7),
        size: 18,
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
    final backgroundColor =
        isDarkMode ? const Color(0xFF0D0D0D) : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF171717) : const Color(0xFFF0F0F0);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.6)
        : Colors.black.withOpacity(0.6);

    final profileProvider = Provider.of<UserProfileProvider>(context);

    return Drawer(
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClientProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.08),
                        ),
                        child: Center(
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.06),
                            ),
                            child: ClipOval(
                              child: _buildProfileImage(profileProvider),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              MockClientData.clientName,
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              MockClientData.clientEmail,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: secondaryTextColor,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              OffersDrawerItem(
                icon: HugeIcons.strokeRoundedSettings01,
                title: 'Settings',
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(
                        role: UserRoleType.client,
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              OffersDrawerItem(
                icon: HugeIcons.strokeRoundedLogout01,
                title: 'Logout',
                isDarkMode: isDarkMode,
                color: Colors.redAccent,
                onTap: () {},
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}