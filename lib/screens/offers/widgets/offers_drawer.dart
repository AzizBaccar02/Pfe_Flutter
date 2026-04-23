import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/user_profile_provider.dart';
import '../../../data/mock_client_data.dart';
import '../../auth/client/client_profile_screen.dart';
import '../../auth/role_selection_screen.dart';
import '../../settings/settings_screen.dart';
import 'offers_drawer_item.dart';

class OffersDrawer extends StatelessWidget {
  final bool isDarkMode;
  final String? fallbackAssetPath;

  const OffersDrawer({
    super.key,
    required this.isDarkMode,
    this.fallbackAssetPath,
  });

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
            ? Colors.white.withOpacity(0.7)
            : Colors.black.withOpacity(0.7),
        size: 18,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogBackground =
            isDarkMode ? const Color(0xFF141414) : Colors.white;
        final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
        final secondaryTextColor = isDarkMode
            ? Colors.white.withOpacity(0.62)
            : Colors.black.withOpacity(0.58);

        return AlertDialog(
          backgroundColor: dialogBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              color: primaryTextColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Are you sure you want to logout from JobMatch?',
            style: TextStyle(
              color: secondaryTextColor,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) return;

    context.read<UserProfileProvider>().setProfileImagePath(null);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const RoleSelectionScreen(),
      ),
      (route) => false,
    );
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
    final profileImagePath = profileProvider.profileImagePath;

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
                              child: _buildProfileImage(profileImagePath),
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
                onTap: () => _handleLogout(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}