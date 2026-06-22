import 'package:flutter/material.dart';

/// Brand greens — muted palette (easy on the eyes, consistent app-wide).
abstract final class AppColors {
  /// Filled buttons, badges, primary CTAs.
  static const accent = Color(0xFF16A34A);

  /// Light fills, hover, subtle highlights.
  static const accentSoft = Color(0xFF86EFAC);

  /// Dark green for pressed / emphasis on light UI.
  static const accentDeep = Color(0xFF14532D);

  /// Tinted surfaces (chips, icon backgrounds).
  static const accentSurface = Color(0xFFECFDF5);

  /// Same as [accent]; kept for legacy call sites.
  static const accentDark = Color(0xFF16A34A);

  /// Text, icons, links on light backgrounds.
  static const accentReadable = Color(0xFF15803D);

  /// Text, icons, links on dark backgrounds (soft mint).
  static const accentReadableOnDark = Color(0xFF86EFAC);

  /// Theme-aware accent for icons, links, and inline highlights.
  static Color forTheme(bool isDarkMode) =>
      isDarkMode ? accentReadableOnDark : accentReadable;

  /// Theme-aware accent for back arrows and navigation chrome.
  static Color navigation(bool isDarkMode) => forTheme(isDarkMode);
}
