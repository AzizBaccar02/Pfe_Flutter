import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';

import '../client/widgets/client_home_theme.dart';

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
    final primaryText = ClientHomeTheme.primaryText(isDarkMode);
    final secondaryText = ClientHomeTheme.secondaryText(isDarkMode);
    final accent = ClientHomeTheme.accent(isDarkMode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: ClientHomeTheme.cardBackground(isDarkMode),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientHomeTheme.cardBorder(isDarkMode)),
        boxShadow: ClientHomeTheme.cardShadow(isDarkMode),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDarkMode
                      ? AppColors.accent.withValues(alpha: 0.14)
                      : AppColors.accentSurface,
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedWork,
                    color: accent,
                    size: 18,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: isDarkMode
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : AppColors.accentSurface,
                ),
                child: Text(
                  'CLIENT',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome back',
            style: TextStyle(
              color: secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            clientName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryText,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Publish offers, monitor responses, and chat with agents from one workspace.',
            style: TextStyle(
              color: secondaryText,
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: onCreateOfferTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Create offer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
