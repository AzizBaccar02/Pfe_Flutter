import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/recommended_offer_model.dart';
import '../../../services/agent_offers_realtime.dart';
import '../../../services/ai_recommendation_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/tab_auto_refresh.dart';
import '../../../utils/skills_match_utils.dart';
import '../../../utils/tunisia_location_utils.dart';
import 'widgets/ai_matches_theme.dart';
import 'widgets/offer_filter_sheet.dart';
import 'widgets/offer_search_bar.dart';
import 'widgets/offer_search_filters.dart';
import '../widgets/agent_bottom_bar.dart';
import 'widgets/recommended_offer_tile.dart';

class AgentHomeScreen extends StatefulWidget {
  final VoidCallback onBrowseOffersTap;
  final VoidCallback onReactionsTap;
  final VoidCallback onChatsTap;
  final void Function({
    String? query,
    OfferSearchFilters? filters,
  }) onAiMatchTap;
  final ScrollController? scrollController;
  final bool isTabActive;

  const AgentHomeScreen({
    super.key,
    required this.onBrowseOffersTap,
    required this.onReactionsTap,
    required this.onChatsTap,
    required this.onAiMatchTap,
    this.scrollController,
    this.isTabActive = true,
  });

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  bool _loadingRecommendations = true;
  String? _recommendationsError;
  bool _profileIncomplete = false;
  AiRecommendationsResult? _recommendations;
  String _agentCityKey = '';
  List<String> _agentSkillTokens = const [];
  final TextEditingController _searchController = TextEditingController();
  OfferSearchFilters _searchFilters = const OfferSearchFilters();

  late final TabAutoRefresh _autoRefresh;

  @override
  void initState() {
    super.initState();
    AgentOffersRealtime.instance.ensureStarted();
    _autoRefresh = TabAutoRefresh(
      onRefresh: ({showLoader = true}) =>
          _loadRecommendations(showLoader: showLoader),
      isTabActive: () => widget.isTabActive,
      pollInterval: const Duration(seconds: 20),
    );
    _autoRefresh.attach();
    if (widget.isTabActive) {
      _loadRecommendations();
    }
  }

  @override
  void dispose() {
    _autoRefresh.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AgentHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTabActive && !oldWidget.isTabActive) {
      _autoRefresh.onTabBecameActive();
    }
  }

  List<RecommendedOfferModel> get _filteredOffers {
    final offers = _recommendations?.offers ?? [];
    return applyOfferSearchAndFilters(
      offers: offers,
      filters: _searchFilters.copyWith(query: _searchController.text),
      agentCityKey: _agentCityKey,
      agentSkillTokens: _agentSkillTokens,
    );
  }

  Future<void> _openFilters() async {
    final categories = collectOfferCategories(_recommendations?.offers ?? []);
    final updated = await showOfferFilterSheet(
      context: context,
      isDarkMode: context.read<ThemeProvider>().isDarkMode,
      current: _searchFilters.copyWith(query: _searchController.text),
      categories: categories,
    );
    if (updated != null && mounted) {
      setState(() => _searchFilters = updated);
    }
  }

  void _openAiMatches({String? query}) {
    widget.onAiMatchTap(
      query: query ?? _searchController.text.trim(),
      filters: _searchFilters.copyWith(
        query: query ?? _searchController.text,
      ),
    );
  }

  void _handleOfferLiked(RecommendedOfferModel offer) {
    if (!mounted || _recommendations == null) return;

    setState(() {
      _recommendations = AiRecommendationsResult(
        agentCity: _recommendations!.agentCity,
        sortBy: _recommendations!.sortBy,
        offers: _recommendations!.offers
            .where((item) => item.id != offer.id)
            .toList(),
      );
    });
  }

  Future<void> _loadRecommendations({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loadingRecommendations = true;
        _recommendationsError = null;
        _profileIncomplete = false;
      });
    }

    try {
      final result = await AiRecommendationService.fetchRecommendedOffers(
        limit: 40,
      );

      if (!mounted) return;

      final profile = await ProfileService.getAgentProfile();

      final agentKey = TunisiaLocationUtils.normalizeAgentLocation(
        city: profile.city.isNotEmpty ? profile.city : result.agentCity,
        address: profile.address,
      );
      final skillTokens = SkillsMatchUtils.parseSkillTokens(
        profile.skills,
        profile.bio,
      );
      setState(() {
        _agentCityKey = agentKey;
        _agentSkillTokens = skillTokens;
        _recommendations = AiRecommendationsResult(
          agentCity: result.agentCity,
          sortBy: result.sortBy,
          offers: sortRecommendedOffersByLocationAndNlp(
            offers: result.offers,
            agentCityKey: agentKey,
            agentCityDisplay: result.agentCity,
            agentSkillTokens: skillTokens,
          ),
        );
        _loadingRecommendations = false;
      });
    } on AiRecommendationException catch (e) {
      if (!mounted) return;

      setState(() {
        _recommendationsError = e.message;
        _profileIncomplete = e.isProfileIncomplete;
        _loadingRecommendations = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    final backgroundColor = AiMatchesTheme.screenBackground(isDarkMode);
    final cardColor = AiMatchesTheme.cardBackground(isDarkMode);
    final borderColor = AiMatchesTheme.cardBorder(isDarkMode);
    final primaryTextColor = AiMatchesTheme.primaryText(isDarkMode);
    final secondaryTextColor = AiMatchesTheme.secondaryText(isDarkMode);

    final listPadding = EdgeInsets.fromLTRB(
      20,
      12,
      20,
      AgentBottomBar.scrollContentPaddingBottom(context),
    );

    return Container(
      color: backgroundColor,
      child: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          await _loadRecommendations();
        },
        child: ListView(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: listPadding,
          children: [
          Text(
            'Overview',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Opportunity dashboard',
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 20),

          _HeroCard(
            matchCount: _filteredOffers.length,
            totalCount: _recommendations?.offers.length ?? 0,
            isLoading: _loadingRecommendations,
            isDarkMode: isDarkMode,
            agentCity: _recommendations?.agentCity ?? '',
            hasSearchActive: _searchFilters.hasActiveFilters ||
                _searchController.text.trim().isNotEmpty,
            onBrowseOffersTap: _openAiMatches,
          ),

          const SizedBox(height: 20),

          OfferSearchBar(
            controller: _searchController,
            isDarkMode: isDarkMode,
            activeFilterCount: _searchFilters.activeFilterCount,
            onFilterTap: _openFilters,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _openAiMatches(),
            onClear: () {
              _searchController.clear();
              setState(() {});
            },
          ),

          const SizedBox(height: 16),

          _SectionHeader(
            title: 'Quick access',
            actionText: '',
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 12),

          _QuickAccessGrid(
            isDarkMode: isDarkMode,
            cardColor: cardColor,
            borderColor: borderColor,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            onBrowseOffersTap: widget.onBrowseOffersTap,
            onAiMatchTap: _openAiMatches,
            onReactionsTap: widget.onReactionsTap,
            onChatsTap: widget.onChatsTap,
          ),

          const SizedBox(height: 26),

          _SectionHeader(
            title: 'Recommended for you',
            actionText: 'See all',
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            onActionTap: _openAiMatches,
          ),
          if ((_recommendations?.agentCity ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _searchFilters.hasActiveFilters || _searchController.text.isNotEmpty
                  ? '${_filteredOffers.length} results · nearby offers matched to your skills'
                  : 'Prioritizing nearby offers around ${_recommendations!.agentCity}',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 14),

          ..._buildRecommendedSection(
            isDarkMode: isDarkMode,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            cardColor: cardColor,
            borderColor: borderColor,
          ),

          const SizedBox(height: 26),

          _SectionHeader(
            title: 'At a glance',
            actionText: '',
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _OverviewStatCard(
                  title: 'AI matches',
                  value: _loadingRecommendations
                      ? '—'
                      : '${_recommendations?.offers.length ?? 0}',
                  accentColor: AppColors.forTheme(isDarkMode),
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewStatCard(
                  title: 'Your area',
                  value: (_recommendations?.agentCity ?? '').isNotEmpty
                      ? _recommendations!.agentCity
                      : '—',
                  accentColor:
                      isDarkMode ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  compactValue: true,
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  List<Widget> _buildRecommendedSection({
    required bool isDarkMode,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color cardColor,
    required Color borderColor,
  }) {
    if (_loadingRecommendations) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        ),
      ];
    }

    if (_recommendationsError != null) {
      return [
        _RecommendationsMessageCard(
          isDarkMode: isDarkMode,
          message: _recommendationsError!,
          isProfileIncomplete: _profileIncomplete,
          cardColor: cardColor,
          borderColor: borderColor,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
          onTap: _profileIncomplete ? null : _openAiMatches,
        ),
      ];
    }

    final allOffers = _recommendations?.offers ?? [];
    if (allOffers.isEmpty) {
      return [
        _RecommendationsMessageCard(
          isDarkMode: isDarkMode,
          message:
              'No AI matches right now. Complete your skills & city, or browse all open offers.',
          cardColor: cardColor,
          borderColor: borderColor,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
          onTap: widget.onBrowseOffersTap,
        ),
      ];
    }

    final offers = _filteredOffers;
    if (offers.isEmpty) {
      return [
        _RecommendationsMessageCard(
          isDarkMode: isDarkMode,
          message:
              'No offers match your search or filters. Try different keywords or reset filters.',
          cardColor: cardColor,
          borderColor: borderColor,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
          onTap: () {
            setState(() {
              _searchController.clear();
              _searchFilters = const OfferSearchFilters();
            });
          },
        ),
      ];
    }

    final preview = offers.take(3).toList();
    final widgets = <Widget>[];

    for (var i = 0; i < preview.length; i++) {
      final offer = preview[i];
      widgets.add(
        RecommendedOfferTile(
          offer: offer,
          isDarkMode: isDarkMode,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
          cardColor: cardColor,
          borderColor: borderColor,
          compact: true,
          onTap: () => showRecommendedOfferDetailsSheet(
            context,
            offer: offer,
            isDarkMode: isDarkMode,
            onLiked: _handleOfferLiked,
          ),
        ),
      );
      if (i < preview.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }

    return widgets;
  }
}

class _RecommendationsMessageCard extends StatelessWidget {
  final bool isDarkMode;
  final String message;
  final bool isProfileIncomplete;
  final Color cardColor;
  final Color borderColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback? onTap;

  const _RecommendationsMessageCard({
    required this.isDarkMode,
    required this.message,
    required this.cardColor,
    required this.borderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    this.isProfileIncomplete = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                isProfileIncomplete
                    ? Icons.person_outline_rounded
                    : Icons.info_outline_rounded,
                color: AppColors.forTheme(isDarkMode),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int matchCount;
  final int totalCount;
  final bool isLoading;
  final bool isDarkMode;
  final String agentCity;
  final bool hasSearchActive;
  final VoidCallback onBrowseOffersTap;

  const _HeroCard({
    required this.matchCount,
    required this.totalCount,
    required this.isLoading,
    required this.isDarkMode,
    required this.agentCity,
    required this.hasSearchActive,
    required this.onBrowseOffersTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AiMatchesTheme.primaryText(isDarkMode);
    final secondary = AiMatchesTheme.secondaryText(isDarkMode);
    final accent = AppColors.forTheme(isDarkMode);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AiMatchesTheme.cardBackground(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AiMatchesTheme.cardBorder(isDarkMode)),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppColors.accent.withOpacity(0.12)
                        : AppColors.accentSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isLoading
                        ? 'Loading matches…'
                        : hasSearchActive
                            ? '$matchCount of $totalCount shown'
                            : matchCount > 0
                                ? '$matchCount matches${agentCity.isNotEmpty ? ' near $agentCity' : ''}'
                                : 'Personalized for your profile',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Find work that fits you',
                  style: TextStyle(
                    color: primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We prioritize nearby offers first, then match to your skills. Use search & filters below.',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onBrowseOffersTap,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('View AI matches'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.accent.withOpacity(0.1)
                  : AppColors.accentSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.insights_outlined,
              color: accent,
              size: 34,
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
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        if (actionText.isNotEmpty) ...[
          const Spacer(),
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionText,
              style: TextStyle(
                color: onActionTap != null
                    ? AppColors.forTheme(
                        Theme.of(context).brightness == Brightness.dark,
                      )
                    : secondaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final bool isDarkMode;
  final Color cardColor;
  final Color borderColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onBrowseOffersTap;
  final VoidCallback onAiMatchTap;
  final VoidCallback onReactionsTap;
  final VoidCallback onChatsTap;

  const _QuickAccessGrid({
    required this.isDarkMode,
    required this.cardColor,
    required this.borderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onBrowseOffersTap,
    required this.onAiMatchTap,
    required this.onReactionsTap,
    required this.onChatsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _QuickAccessCard(
                label: 'Browse offers',
                subtitle: 'Swipe & react',
                icon: HugeIcons.strokeRoundedBriefcase01,
                accentColor: AppColors.forTheme(isDarkMode),
                isDarkMode: isDarkMode,
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: primaryTextColor,
                subtitleColor: secondaryTextColor,
                onTap: onBrowseOffersTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAccessCard(
                label: 'AI matches',
                subtitle: 'Smart ranking',
                icon: HugeIcons.strokeRoundedSparkles,
                accentColor: AppColors.forTheme(isDarkMode),
                isDarkMode: isDarkMode,
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: primaryTextColor,
                subtitleColor: secondaryTextColor,
                onTap: onAiMatchTap,
                highlighted: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _QuickAccessCard(
                label: 'Reactions',
                subtitle: 'Your activity',
                icon: HugeIcons.strokeRoundedFavourite,
                accentColor: isDarkMode
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFB91C1C),
                isDarkMode: isDarkMode,
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: primaryTextColor,
                subtitleColor: secondaryTextColor,
                onTap: onReactionsTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAccessCard(
                label: 'Messages',
                subtitle: 'Client chats',
                icon: HugeIcons.strokeRoundedMessage02,
                accentColor: isDarkMode
                    ? const Color(0xFF5EEAD4)
                    : const Color(0xFF0F766E),
                isDarkMode: isDarkMode,
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: primaryTextColor,
                subtitleColor: secondaryTextColor,
                onTap: onChatsTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final dynamic icon;
  final Color accentColor;
  final bool isDarkMode;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback onTap;
  final bool highlighted;

  const _QuickAccessCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isDarkMode,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted
                  ? AppColors.accent.withOpacity(isDarkMode ? 0.45 : 0.35)
                  : borderColor,
              width: highlighted ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(isDarkMode ? 0.12 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: icon,
                    color: accentColor,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accentColor;
  final Color cardColor;
  final Color borderColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final bool compactValue;

  const _OverviewStatCard({
    required this.title,
    required this.value,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    this.compactValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: compactValue ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: compactValue ? 18 : 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
