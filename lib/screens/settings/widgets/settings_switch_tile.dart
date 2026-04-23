import 'package:flutter/material.dart';

class SettingsSwitchTile extends StatelessWidget {
  final bool isDarkMode;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.isDarkMode,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.60)
        : Colors.black.withOpacity(0.56);

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _PremiumToggle(
              value: value,
              onChanged: onChanged,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDarkMode;

  const _PremiumToggle({
    required this.value,
    required this.onChanged,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final offTrackColor =
        isDarkMode ? const Color(0xFF2A2A33) : const Color(0xFFE8E8EE);

    final offBorderColor =
        isDarkMode ? Colors.white.withOpacity(0.10) : const Color(0xFFD7D7E0);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 62,
        height: 36,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: value
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFFFE082),
                    Color(0xFFFFC107),
                  ],
                )
              : null,
          color: value ? null : offTrackColor,
          border: Border.all(
            color: value ? const Color(0xFFFFC107) : offBorderColor,
            width: 1.2,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFC107).withOpacity(0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value
                  ? const Color(0xFF5D4200)
                  : (isDarkMode
                      ? const Color(0xFF8F8F9B)
                      : const Color(0xFF91919C)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.24 : 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}