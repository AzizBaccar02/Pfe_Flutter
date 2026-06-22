import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../conf/theme_provider.dart';
import '../settings/widgets/settings_section_title.dart';
import '../settings/widgets/settings_switch_tile.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _messages = true;
  bool _matches = true;
  bool _offers = true;
  bool _tips = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    const accentGreen = AppColors.accent;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF141414) : const Color(0xFFF5F5F5);
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);

    final neutralIconColor = isDarkMode
        ? Colors.white.withOpacity(0.78)
        : Colors.black.withOpacity(0.78);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: AppBackButton(isDarkMode: isDarkMode),
        centerTitle: true,
        title: Text(
          'Notification Preferences',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.w800,
            fontSize: 21,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: accentGreen.withOpacity(isDarkMode ? 0.10 : 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedNotification03,
                          color: neutralIconColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage your alerts',
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose which notifications you want JobMatch to send you.',
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SettingsSectionTitle(
                title: 'Notification Preferences',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    SettingsSwitchTile(
                      isDarkMode: isDarkMode,
                      title: 'New Messages',
                      subtitle: 'Get notified when a new message arrives',
                      value: _messages,
                      onChanged: (value) {
                        setState(() {
                          _messages = value;
                        });
                      },
                    ),
                    Divider(color: borderColor, height: 1),
                    SettingsSwitchTile(
                      isDarkMode: isDarkMode,
                      title: 'New Matches',
                      subtitle: 'Get notified when a match is created',
                      value: _matches,
                      onChanged: (value) {
                        setState(() {
                          _matches = value;
                        });
                      },
                    ),
                    Divider(color: borderColor, height: 1),
                    SettingsSwitchTile(
                      isDarkMode: isDarkMode,
                      title: 'Offer Activity',
                      subtitle: 'Updates about offers and interactions',
                      value: _offers,
                      onChanged: (value) {
                        setState(() {
                          _offers = value;
                        });
                      },
                    ),
                    Divider(color: borderColor, height: 1),
                    SettingsSwitchTile(
                      isDarkMode: isDarkMode,
                      title: 'Tips & Recommendations',
                      subtitle: 'Receive useful product tips and suggestions',
                      value: _tips,
                      onChanged: (value) {
                        setState(() {
                          _tips = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}