import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

import '../../../../models/recommended_offer_model.dart';

/// Professional palette for agent workspace & AI screens (no purple).
abstract final class AiMatchesTheme {
  static Color screenBackground(bool isDark) =>
      isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF3F4F6);

  static Color cardBackground(bool isDark) =>
      isDark ? const Color(0xFF141414) : Colors.white;

  static Color cardBorder(bool isDark) =>
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);

  static Color primaryText(bool isDark) =>
      isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);

  static Color secondaryText(bool isDark) =>
      isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

  /// Location row: green = same area, teal = nearby, grey = other.
  static Color locationAccent(RecommendedOfferModel offer, bool isDark) {
    if (offer.isSameCity) {
      return isDark ? AppColors.accentReadableOnDark : AppColors.accent;
    }
    if (offer.isNearby) {
      return isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
    }
    return secondaryText(isDark);
  }

  /// Match % chip: green strong, teal medium, neutral low.
  static Color matchScoreAccent(double score, bool isDark) {
    if (score >= 75) {
      return isDark ? AppColors.accentReadableOnDark : AppColors.accent;
    }
    if (score >= 55) {
      return isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
    }
    return secondaryText(isDark);
  }

  static Color matchScoreChipFill(double score, bool isDark) {
    if (score >= 75) {
      return isDark
          ? AppColors.accent.withOpacity(0.14)
          : AppColors.accentSurface;
    }
    if (score >= 55) {
      return isDark
          ? const Color(0xFF134E4A).withOpacity(0.45)
          : const Color(0xFFCCFBF1);
    }
    return isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);
  }

  static Color iconTileFill(RecommendedOfferModel offer, bool isDark) {
    return locationAccent(offer, isDark).withOpacity(isDark ? 0.12 : 0.1);
  }
}
