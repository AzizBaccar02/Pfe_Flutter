import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/app_colors.dart';
import '../../../conf/theme_provider.dart';

class AgentHomeScreen extends StatelessWidget {
  final VoidCallback onBrowseOffersTap;
  final VoidCallback onReactionsTap;
  final VoidCallback onChatsTap;
  final ScrollController? scrollController;

  const AgentHomeScreen({
    super.key,
    required this.onBrowseOffersTap,
    required this.onReactionsTap,
    required this.onChatsTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    final backgroundColor =
        isDarkMode ? Colors.black : const Color(0xFFF6F8FC);
    final cardColor = isDarkMode ? const Color(0xFF141414) : Colors.white;
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);
    final primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.66)
        : const Color(0xFF6B7280);

    const accentBlue = Color(0xFF3B82F6);
    const accentGreen = Color(0xFF22C55E);
    const accentPurple = Color(0xFF8B5CF6);
    const accentRed = Color(0xFFEF4444);
    const accentBrand = AppColors.accent;

    return Container(
      color: backgroundColor,
      child: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
          children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Agent Workspace',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  height: 1.05,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          _HeroCard(
            onBrowseOffersTap: onBrowseOffersTap,
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        color: secondaryTextColor,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search offers, skills, categories...',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedFilterHorizontal,
                    color: primaryTextColor.withOpacity(0.82),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _SectionHeader(
            title: 'Quick Access',
            actionText: 'See all',
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.92,
            children: [
              _QuickAccessCard(
                label: 'Offers',
                icon: HugeIcons.strokeRoundedBriefcase01,
                backgroundColor: isDarkMode
                    ? accentGreen.withOpacity(0.18)
                    : const Color(0xFFE9F9EF),
                iconColor: isDarkMode
                    ? accentGreen
                    : const Color(0xFF16A34A),
                textColor: primaryTextColor,
                borderColor: borderColor,
                onTap: onBrowseOffersTap,
              ),
              _QuickAccessCard(
                label: 'Reactions',
                icon: HugeIcons.strokeRoundedFavourite,
                backgroundColor: isDarkMode
                    ? accentRed.withOpacity(0.16)
                    : const Color(0xFFFDECEC),
                iconColor: isDarkMode
                    ? accentRed
                    : const Color(0xFFDC2626),
                textColor: primaryTextColor,
                borderColor: borderColor,
                onTap: onReactionsTap,
              ),
              _QuickAccessCard(
                label: 'Chats',
                icon: HugeIcons.strokeRoundedMessage02,
                backgroundColor: isDarkMode
                    ? accentBlue.withOpacity(0.18)
                    : const Color(0xFFEAF2FF),
                iconColor: isDarkMode
                    ? accentBlue
                    : const Color(0xFF2563EB),
                textColor: primaryTextColor,
                borderColor: borderColor,
                onTap: onChatsTap,
              ),
              _QuickAccessCard(
                label: 'AI Match',
                icon: HugeIcons.strokeRoundedSparkles,
                backgroundColor: isDarkMode
                    ? accentPurple.withOpacity(0.18)
                    : const Color(0xFFF2ECFF),
                iconColor: isDarkMode
                    ? accentPurple
                    : const Color(0xFF7C3AED),
                textColor: primaryTextColor,
                borderColor: borderColor,
                onTap: onBrowseOffersTap,
              ),
              _QuickAccessCard(
                label: 'Nearby',
                icon: HugeIcons.strokeRoundedLocation01,
                backgroundColor: isDarkMode
                    ? accentBrand.withOpacity(0.16)
                    : AppColors.accentSurface,
                iconColor: isDarkMode
                    ? accentBrand
                    : AppColors.accentDark,
                textColor: primaryTextColor,
                borderColor: borderColor,
                onTap: onBrowseOffersTap,
              ),
              _QuickAccessCard(
                label: 'Subscription',
                icon: HugeIcons.strokeRoundedWallet02,
                backgroundColor: isDarkMode
                    ? Colors.cyan.withOpacity(0.16)
                    : const Color(0xFFE8FAFC),
                iconColor: isDarkMode
                    ? Colors.cyanAccent
                    : const Color(0xFF0891B2),
                textColor: primaryTextColor,
                borderColor: borderColor,
                onTap: onBrowseOffersTap,
              ),
            ],
          ),

          const SizedBox(height: 26),

          _SectionHeader(
            title: 'Recommended Offers',
            actionText: 'See all',
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 14),

          _RecommendedOfferCard(
            isDarkMode: isDarkMode,
            title: 'Flutter service marketplace polish',
            subtitle: 'Tunis · Mobile Development',
            badge: '92% match',
            badgeColor: accentGreen,
            budget: '1200 DT',
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            cardColor: cardColor,
            borderColor: borderColor,
            onTap: onBrowseOffersTap,
          ),
          const SizedBox(height: 12),
          _RecommendedOfferCard(
            isDarkMode: isDarkMode,
            title: 'Restaurant booking app UI redesign',
            subtitle: 'Sousse · UI / UX',
            badge: 'Strong match',
            badgeColor: accentBlue,
            budget: '850 DT',
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            cardColor: cardColor,
            borderColor: borderColor,
            onTap: onBrowseOffersTap,
          ),

          const SizedBox(height: 26),

          _SectionHeader(
            title: 'Workspace Overview',
            actionText: 'Today',
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _OverviewStatCard(
                  title: 'Open offers',
                  value: '24',
                  color: accentBlue,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewStatCard(
                  title: 'Pending',
                  value: '06',
                  color: isDarkMode
                      ? accentBrand
                      : AppColors.accentDark,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OverviewStatCard(
                  title: 'Chats',
                  value: '09',
                  color: accentGreen,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewStatCard(
                  title: 'Rejected',
                  value: '02',
                  color: accentRed,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onBrowseOffersTap;

  const _HeroCard({
    required this.onBrowseOffersTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 225),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2563EB),
            Color(0xFF4F46E5),
            Color(0xFF7C3AED),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -12,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 58,
            right: 32,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedBriefcase01,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -28,
            right: 24,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 181),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '12 new matches 🔥',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SizedBox(
                    width: 210,
                    child: Text(
                      'Today’s best\nopportunities',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        height: 1.02,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 210,
                    child: Text(
                      'Open offers matched to your profile and skills.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.84),
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 46,
                    width: 150,
                    child: ElevatedButton(
                      onPressed: onBrowseOffersTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1D4ED8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Browse offers',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Text(
          actionText,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String label;
  final dynamic icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendedOfferCard extends StatelessWidget {
  final bool isDarkMode;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final String budget;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _RecommendedOfferCard({
    required this.isDarkMode,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.budget,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.cardColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedBriefcase01,
                color: badgeColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      budget,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: primaryTextColor.withOpacity(0.8),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color cardColor;
  final Color borderColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const _OverviewStatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.cardColor,
    required this.borderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}