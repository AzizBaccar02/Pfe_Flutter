import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String? label;
  final String? text;
  final dynamic icon;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final bool isDarkMode;
  final Color? backgroundColor;

  const SocialButton({
    super.key,
    this.label,
    this.text,
    required this.icon,
    this.onTap,
    this.onPressed,
    required this.isDarkMode,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    const accentYellow = Color(0xFFFFC107);
    const accentYellowDeep = Color(0xFF5D4200);

    final displayLabel = label ?? text ?? '';
    final action = onTap ?? onPressed;

    final surfaceColor =
        isDarkMode ? const Color(0xFF141414) : const Color(0xFFF8F8F8);

    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    final textColor = isDarkMode ? Colors.white : Colors.black;

    final iconContainerColor = backgroundColor ??
        accentYellow.withOpacity(isDarkMode ? 0.12 : 0.16);

    Widget resolvedIcon;
    if (icon is Widget) {
      resolvedIcon = icon as Widget;
    } else if (icon is IconData) {
      resolvedIcon = Icon(
        icon as IconData,
        color: accentYellowDeep,
        size: 18,
      );
    } else {
      resolvedIcon = const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: action,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: iconContainerColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: resolvedIcon),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      displayLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}