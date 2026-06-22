import 'package:flutter/material.dart';

import '../conf/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final Widget? icon;
  final bool isDarkMode;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.icon,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final outlineBorderColor = isDarkMode
        ? AppColors.accent.withValues(alpha: 0.55)
        : AppColors.accent.withValues(alpha: 0.80);

    final outlineTextColor =
        isDarkMode ? AppColors.accentSoft : AppColors.accentDeep;

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 55,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: outlineTextColor,
            side: BorderSide(
              color: outlineBorderColor,
              width: 1.4,
            ),
            backgroundColor: isDarkMode
                ? AppColors.accent.withValues(alpha: 0.05)
                : AppColors.accent.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: outlineTextColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.accentSoft,
              AppColors.accent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentDeep,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                IconTheme(
                  data: const IconThemeData(
                    color: AppColors.accentDeep,
                    size: 18,
                  ),
                  child: icon!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
