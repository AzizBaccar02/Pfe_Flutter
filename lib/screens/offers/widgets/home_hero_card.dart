import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../conf/app_colors.dart';

class HomeHeroCard extends StatelessWidget {
  final bool isDarkMode;
  final String clientName;
  final VoidCallback onCreateOfferTap;

  const HomeHeroCard({
    super.key,
    required this.isDarkMode,
    required this.clientName,
    required this.onCreateOfferTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.accent;
    const accentSoft = AppColors.accentSoft;
    const accentDeep = AppColors.accentDeep;

    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.68)
        : Colors.black.withOpacity(0.68);

    final neutralIconColor = isDarkMode
        ? Colors.white.withOpacity(0.78)
        : Colors.black.withOpacity(0.78);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: isDarkMode
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A1A),
                  Color(0xFF111111),
                  Color(0xFF1E1E1E),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF9F9F9),
                  Color(0xFFF1F1F1),
                  Color(0xFFF7F7F7),
                ],
              ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.22)
                : Colors.black.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: accent.withOpacity(isDarkMode ? 0.14 : 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDarkMode
                      ? accent.withOpacity(0.12)
                      : accent.withOpacity(0.14),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedWork,
                    color: neutralIconColor,
                    size: 18,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDarkMode
                      ? accent.withOpacity(0.10)
                      : accent.withOpacity(0.12),
                  border: Border.all(
                    color: accent.withOpacity(isDarkMode ? 0.22 : 0.28),
                  ),
                ),
                child: Text(
                  'Client Dashboard',
                  style: TextStyle(
                    color: neutralIconColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Welcome back,',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            clientName,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create offers, track activity, and connect with interested agents in one place.',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onCreateOfferTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    accentSoft,
                    accent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.26),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAdd01,
                    color: accentDeep,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Create Offer',
                    style: TextStyle(
                      color: accentDeep,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}