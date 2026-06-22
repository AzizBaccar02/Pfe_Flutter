import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/user_profile_provider.dart';
import '../../../models/agent_profile_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../auth/agent/agent_complete_profile_flow_screen.dart';
import '../../auth/role_selection_screen.dart';
import '../../settings/appearance_screen.dart';
import '../../settings/help_support_screen.dart';
import '../../subscription/subscription_hub_screen.dart';
import 'offers_drawer_item.dart';

class AgentOffersDrawer extends StatefulWidget {
  final bool isDarkMode;

  const AgentOffersDrawer({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<AgentOffersDrawer> createState() => _AgentOffersDrawerState();
}

class _AgentOffersDrawerState extends State<AgentOffersDrawer> {
  String _agentName = 'Agent';
  String _agentEmail = '';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadAgentProfile();
  }

  Future<void> _loadAgentProfile() async {
    try {
      final AgentProfileModel profile = await ProfileService.getAgentProfile();
      if (!mounted) return;

      final profileProvider = context.read<UserProfileProvider>();
      final remoteUrl = ProfileService.resolveMediaUrl(profile.photoUrl);
      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        profileProvider.setRemoteProfileImageUrl(remoteUrl);
      } else {
        profileProvider.clearProfileImage();
      }

      setState(() {
        _agentName = profile.displayName;
        _agentEmail = profile.email.trim();
        _isLoadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      context.read<UserProfileProvider>().clearProfileImage();
      setState(() {
        _agentName = 'Agent';
        _agentEmail = '';
        _isLoadingProfile = false;
      });
    }
  }

  Widget _emptyAvatar() {
    return Center(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedUser,
        color: widget.isDarkMode
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.black.withValues(alpha: 0.7),
        size: 18,
      ),
    );
  }

  Widget _buildProfileImage(UserProfileProvider profileProvider) {
    final localPath = profileProvider.localProfileImagePath;
    final remoteUrl = profileProvider.remoteProfileImageUrl;

    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      return Image.network(
        remoteUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _emptyAvatar(),
      );
    }

    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _emptyAvatar(),
      );
    }

    return _emptyAvatar();
  }

  Future<void> _openAccount() async {
    Navigator.pop(context);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AgentCompleteProfileFlowScreen(),
      ),
    );
    if (!mounted) return;
    _loadAgentProfile();
  }

  void _openAppearance() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AppearanceScreen(),
      ),
    );
  }

  void _openHelpSupport() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpSupportScreen(),
      ),
    );
  }

  void _openSubscription() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionHubScreen(isAgent: true),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogBackground =
            widget.isDarkMode ? const Color(0xFF141414) : Colors.white;
        final primaryTextColor =
            widget.isDarkMode ? Colors.white : Colors.black;
        final secondaryTextColor = widget.isDarkMode
            ? Colors.white.withValues(alpha: 0.62)
            : Colors.black.withValues(alpha: 0.58);

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

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    try {
      await AuthService.logout().timeout(const Duration(seconds: 8));
    } catch (_) {
      await AuthService.clearLoginSession();
    }

    if (!context.mounted) return;
    context.read<UserProfileProvider>().clearProfileImage();

    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const RoleSelectionScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        widget.isDarkMode ? const Color(0xFF0D0D0D) : Colors.white;
    final cardColor =
        widget.isDarkMode ? const Color(0xFF171717) : const Color(0xFFF0F0F0);
    final primaryTextColor = widget.isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = widget.isDarkMode
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.6);
    final profileProvider = context.watch<UserProfileProvider>();

    return Drawer(
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _openAccount,
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
                          color: widget.isDarkMode
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                        child: Center(
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.06),
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
                              _isLoadingProfile ? 'Loading...' : _agentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _agentEmail.isEmpty
                                  ? 'Open and manage your profile'
                                  : _agentEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      OffersDrawerSection(
                        label: 'Subscription',
                        isDarkMode: widget.isDarkMode,
                        rows: [
                          OffersDrawerRow(
                            icon: HugeIcons.strokeRoundedWallet02,
                            title: 'Subscription',
                            onTap: _openSubscription,
                          ),
                        ],
                      ),
                      OffersDrawerSection(
                        label: 'Preferences',
                        isDarkMode: widget.isDarkMode,
                        rows: [
                          OffersDrawerRow(
                            icon: HugeIcons.strokeRoundedDarkMode,
                            title: 'Appearance',
                            onTap: _openAppearance,
                          ),
                        ],
                      ),
                      OffersDrawerSection(
                        label: 'Support',
                        isDarkMode: widget.isDarkMode,
                        rows: [
                          OffersDrawerRow(
                            icon: HugeIcons.strokeRoundedHelpCircle,
                            title: 'Help & Support',
                            onTap: _openHelpSupport,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              OffersDrawerSection(
                isDarkMode: widget.isDarkMode,
                rows: [
                  OffersDrawerRow(
                    icon: HugeIcons.strokeRoundedLogout01,
                    title: 'Logout',
                    isDestructive: true,
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
