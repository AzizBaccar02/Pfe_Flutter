import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
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
    const accentYellow = Color(0xFFFFC107);
    const accentYellowSoft = Color(0xFFFFE082);
    const accentYellowDeep = Color(0xFF5D4200);

    final outlineBorderColor = isDarkMode
        ? accentYellow.withOpacity(0.55)
        : accentYellow.withOpacity(0.80);

    final outlineTextColor = isDarkMode ? accentYellowSoft : accentYellowDeep;

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
                ? accentYellow.withOpacity(0.05)
                : accentYellow.withOpacity(0.08),
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
              accentYellowSoft,
              accentYellow,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: accentYellow.withOpacity(0.28),
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
                  color: accentYellowDeep,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                IconTheme(
                  data: const IconThemeData(
                    color: accentYellowDeep,
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