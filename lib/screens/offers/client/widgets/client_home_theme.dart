// lib/screens/offers/client/widgets/client_home_theme.dart

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

/// Cinematic dashboard palette (reference-inspired, brand-safe).
abstract final class ClientHomeTheme {
  static Color screenBackground(bool isDarkMode) =>
      isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F7);

  static Color cardBackground(bool isDarkMode) =>
      isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

  static Color elevatedSurface(bool isDarkMode) =>
      isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFEBEBEF);

  static Color searchFieldBackground(bool isDarkMode) =>
      isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8ED);

  static Color cardBorder(bool isDarkMode) => isDarkMode
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.06);

  static Color primaryText(bool isDarkMode) =>
      isDarkMode ? Colors.white : const Color(0xFF111111);

  static Color secondaryText(bool isDarkMode) => isDarkMode
      ? Colors.white.withValues(alpha: 0.65)
      : const Color(0xFF6B6B6B);

  static Color tertiaryText(bool isDarkMode) => isDarkMode
      ? Colors.white.withValues(alpha: 0.42)
      : const Color(0xFF9A9A9A);

  /// “See all” and highlights — brand green, readable on dark.
  static Color highlight(bool isDarkMode) =>
      isDarkMode ? AppColors.accentSoft : AppColors.accent;

  static Color accent(bool isDarkMode) =>
      isDarkMode ? AppColors.accentReadableOnDark : AppColors.accentReadable;

  static Color navBarBackground(bool isDarkMode) =>
      isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

  static Color navActivePill(bool isDarkMode) => AppColors.accent;

  static List<BoxShadow> floatingShadow(bool isDarkMode) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDarkMode ? 0.45 : 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> cardShadow(bool isDarkMode) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}
