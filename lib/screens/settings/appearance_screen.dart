import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../conf/theme_provider.dart';
import 'widgets/settings_section_title.dart';
import 'widgets/settings_tile.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF141414) : const Color(0xFFF5F5F5);
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

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
          'Appearance',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
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
              SettingsSectionTitle(
                title: 'Theme Mode',
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
                    SettingsTile(
                      isDarkMode: isDarkMode,
                      title: 'Dark Mode',
                      subtitle: 'Elegant dark premium interface',
                      icon: HugeIcons.strokeRoundedDarkMode,
                      trailing: isDarkMode
                          ? HugeIcon(
                              icon: HugeIcons.strokeRoundedFavourite,
                              color: const Color(0xFF22C55E),
                              size: 18,
                            )
                          : null,
                      onTap: () {
                        if (!themeProvider.isDarkMode) {
                          themeProvider.toggleTheme();
                        }
                      },
                    ),
                    Divider(
                      color: borderColor,
                      height: 1,
                    ),
                    SettingsTile(
                      isDarkMode: isDarkMode,
                      title: 'Light Mode',
                      subtitle: 'Clean bright interface',
                      icon: HugeIcons.strokeRoundedDarkMode,
                      trailing: !isDarkMode
                          ? HugeIcon(
                              icon: HugeIcons.strokeRoundedFavourite,
                              color: const Color(0xFF22C55E),
                              size: 18,
                            )
                          : null,
                      onTap: () {
                        if (themeProvider.isDarkMode) {
                          themeProvider.toggleTheme();
                        }
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