import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

/// Consistent iOS-style back chevron used app-wide (same look as Notifications).
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool? isDarkMode;
  final double size;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.isDarkMode,
    this.size = 18,
  });

  static bool _isDark(BuildContext context, bool? isDarkMode) =>
      isDarkMode ?? Theme.of(context).brightness == Brightness.dark;

  static Color colorFor(BuildContext context, {bool? isDarkMode}) =>
      AppColors.navigation(_isDark(context, isDarkMode));

  static Widget icon(
    BuildContext context, {
    bool? isDarkMode,
    double size = 18,
  }) {
    return Icon(
      Icons.arrow_back_ios_new_rounded,
      color: colorFor(context, isDarkMode: isDarkMode),
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      icon: icon(context, isDarkMode: isDarkMode, size: size),
    );
  }
}
