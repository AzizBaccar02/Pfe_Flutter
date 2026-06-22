import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../conf/theme_provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor =
        isDarkMode ? const Color(0xFF0D0D0D) : const Color(0xFFF3F4F6);
    final cardColor = isDarkMode ? const Color(0xFF141414) : Colors.white;
    final primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDarkMode
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final accent = isDarkMode
        ? AppColors.accentReadableOnDark
        : AppColors.accentReadable;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: AppBackButton(isDarkMode: isDarkMode),
        centerTitle: true,
        title: Text(
          'Appearance',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Choose how JobMatch looks on your device. Your preference is saved automatically.',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'THEME',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ThemeOptionCard(
                    title: 'Light',
                    subtitle: 'Bright & clean',
                    isSelected: !isDarkMode,
                    isDarkPreview: false,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    accent: accent,
                    previewBackground: const Color(0xFFF3F4F6),
                    previewSurface: Colors.white,
                    previewText: const Color(0xFF111827),
                    icon: Icons.light_mode_rounded,
                    onTap: () {
                      if (isDarkMode) themeProvider.toggleTheme();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ThemeOptionCard(
                    title: 'Dark',
                    subtitle: 'Easy on the eyes',
                    isSelected: isDarkMode,
                    isDarkPreview: true,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    accent: accent,
                    previewBackground: const Color(0xFF0D0D0D),
                    previewSurface: const Color(0xFF141414),
                    previewText: Colors.white,
                    icon: Icons.dark_mode_rounded,
                    onTap: () {
                      if (!isDarkMode) themeProvider.toggleTheme();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentSurface.withValues(
                        alpha: isDarkMode ? 0.12 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        color: accent,
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
                          'Active: ${isDarkMode ? 'Dark' : 'Light'} mode',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Menus, offers, chats, and notifications follow this theme.',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isDarkPreview;
  final Color cardColor;
  final Color borderColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accent;
  final Color previewBackground;
  final Color previewSurface;
  final Color previewText;
  final IconData icon;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isDarkPreview,
    required this.cardColor,
    required this.borderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accent,
    required this.previewBackground,
    required this.previewSurface,
    required this.previewText,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBorder = isSelected ? accent : borderColor;
    final selectedWidth = isSelected ? 2.0 : 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selectedBorder, width: selectedWidth),
            boxShadow: isSelected && !isDarkPreview
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniThemePreview(
                background: previewBackground,
                surface: previewSurface,
                text: previewText,
                accent: accent,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(icon, size: 18, color: isSelected ? accent : secondaryTextColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, size: 20, color: accent)
                  else
                    Icon(
                      Icons.circle_outlined,
                      size: 20,
                      color: secondaryTextColor.withValues(alpha: 0.45),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

class _MiniThemePreview extends StatelessWidget {
  final Color background;
  final Color surface;
  final Color text;
  final Color accent;

  const _MiniThemePreview({
    required this.background,
    required this.surface,
    required this.text,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 72,
        width: double.infinity,
        color: background,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 6,
                  decoration: BoxDecoration(
                    color: text.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: text.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 4,
                            width: 36,
                            decoration: BoxDecoration(
                              color: text.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 3,
                            width: 24,
                            decoration: BoxDecoration(
                              color: text.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
