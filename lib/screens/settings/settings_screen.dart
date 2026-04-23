import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../conf/theme_provider.dart';
import '../auth/agent/agent_profile_screen.dart';
import '../auth/client/client_profile_screen.dart';
import '../notifications/notification_preferences_screen.dart';
import 'about_screen.dart';
import 'appearance_screen.dart';
import 'help_support_screen.dart';
import 'privacy_security_screen.dart';
import 'widgets/settings_search_bar.dart';
import 'widgets/settings_section_title.dart';
import 'widgets/settings_tile.dart';

enum UserRoleType { client, agent }

class SettingsScreen extends StatefulWidget {
  final UserRoleType role;

  const SettingsScreen({
    super.key,
    required this.role,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<_SettingsItemData> get _items => [
        _SettingsItemData(
          title: 'Account',
          subtitle: 'Profile, personal information',
          icon: HugeIcons.strokeRoundedUser,
          onTap: _openAccount,
        ),
        _SettingsItemData(
          title: 'Notifications',
          subtitle: 'Push alerts, matches and messages',
          icon: HugeIcons.strokeRoundedNotification03,
          onTap: _openNotifications,
        ),
        _SettingsItemData(
          title: 'Appearance',
          subtitle: 'Dark mode and visual preferences',
          icon: HugeIcons.strokeRoundedDarkMode,
          onTap: _openAppearance,
        ),
        _SettingsItemData(
          title: 'Privacy & Security',
          subtitle: 'Password, sessions and login protection',
          icon: HugeIcons.strokeRoundedShield01,
          onTap: _openPrivacySecurity,
        ),
        _SettingsItemData(
          title: 'Help & Support',
          subtitle: 'FAQ, support and report a problem',
          icon: HugeIcons.strokeRoundedHelpCircle,
          onTap: _openHelpSupport,
        ),
        _SettingsItemData(
          title: 'About',
          subtitle: 'App information and version',
          icon: HugeIcons.strokeRoundedInformationCircle,
          onTap: _openAbout,
        ),
      ];

  List<_SettingsItemData> get _filteredItems {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;

    return _items
        .where(
          (item) =>
              item.title.toLowerCase().contains(q) ||
              item.subtitle.toLowerCase().contains(q),
        )
        .toList();
  }

  void _openAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => widget.role == UserRoleType.client
            ? const ClientProfileScreen()
            : const AgentProfileScreen(),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationPreferencesScreen(),
      ),
    );
  }

  void _openAppearance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AppearanceScreen(),
      ),
    );
  }

  void _openPrivacySecurity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrivacySecurityScreen(),
      ),
    );
  }

  void _openHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpSupportScreen(),
      ),
    );
  }

  void _openAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AboutScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF141414) : const Color(0xFFF5F5F5);
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    final filteredItems = _filteredItems;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: isDarkMode ? Colors.white : Colors.black,
            size: 20,
          ),
        ),
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            children: [
              SettingsSearchBar(
                controller: _searchController,
                isDarkMode: isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              SettingsSectionTitle(
                title: widget.role == UserRoleType.client
                    ? 'Client Settings'
                    : 'Agent Settings',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'No settings found',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.62)
                                : Colors.black.withOpacity(0.58),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: borderColor),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, __) => Divider(
                            color: borderColor,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];

                            return SettingsTile(
                              isDarkMode: isDarkMode,
                              title: item.title,
                              subtitle: item.subtitle,
                              icon: item.icon,
                              onTap: item.onTap,
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsItemData {
  final String title;
  final String subtitle;
  final dynamic icon;
  final VoidCallback onTap;

  _SettingsItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}