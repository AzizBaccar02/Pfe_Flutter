import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/recommended_offer_model.dart';
import '../../../models/agent_public_offer_model.dart';
import '../../../services/ai_recommendation_service.dart';
import '../../../services/offer_service.dart';
import '../../../services/tab_auto_refresh.dart';
import '../../../services/profile_service.dart';
import '../../../utils/skills_match_utils.dart';
import '../../../utils/tunisia_location_utils.dart';
import 'widgets/ai_matches_theme.dart';
import 'widgets/offer_filter_sheet.dart';
import 'widgets/offer_search_bar.dart';
import 'widgets/offer_search_filters.dart';
import 'widgets/recommended_offer_tile.dart';

class AgentAiRecommendationsScreen extends StatefulWidget {
  final String? initialQuery;
  final OfferSearchFilters? initialFilters;

  const AgentAiRecommendationsScreen({
    super.key,
    this.initialQuery,
    this.initialFilters,
  });

  @override
  State<AgentAiRecommendationsScreen> createState() =>
      _AgentAiRecommendationsScreenState();
}

class _AgentAiRecommendationsScreenState
    extends State<AgentAiRecommendationsScreen> {
  bool _isLoading = true;
  String? _error;
  bool _profileIncomplete = false;
  AiRecommendationsResult? _result;
  List<String> _agentSkillTokens = const [];
  String _agentCityKey = '';

  late final TextEditingController _searchController;
  late OfferSearchFilters _searchFilters;
  late final TabAutoRefresh _autoRefresh;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _searchFilters = widget.initialFilters ??
        OfferSearchFilters(query: widget.initialQuery ?? '');
    _autoRefresh = TabAutoRefresh(
      onRefresh: ({showLoader = true}) => _load(showLoader: showLoader),
      isTabActive: () => true,
      pollInterval: const Duration(seconds: 20),
      refreshWhenInactive: true,
    );
    _autoRefresh.attach();
    _load();
  }

  @override
  void dispose() {
    _autoRefresh.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<RecommendedOfferModel> get _visibleOffers {
    final offers = _result?.offers ?? [];
    return applyOfferSearchAndFilters(
      offers: offers,
      filters: _searchFilters.copyWith(query: _searchController.text),
      agentCityKey: _agentCityKey,
      agentSkillTokens: _agentSkillTokens,
    );
  }

  Future<void> _openFilters() async {
    final categories = collectOfferCategories(_result?.offers ?? []);
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

  void _handleOfferLiked(RecommendedOfferModel offer) {
    if (!mounted || _result == null) return;

    setState(() {
      _result = AiRecommendationsResult(
        agentCity: _result!.agentCity,
        sortBy: _result!.sortBy,
        offers: _result!.offers.where((item) => item.id != offer.id).toList(),
      );
    });
  }

  Future<AiRecommendationsResult> _loadKeywordFallback() async {
    try {
      final profile = await ProfileService.getAgentProfile();
      final list = await OfferService.fetchAgentOffers();
      final agentCityKey = TunisiaLocationUtils.normalizeAgentLocation(
        city: profile.city,
        address: profile.address,
      );
      final agentTokens =
          SkillsMatchUtils.parseSkillTokens(profile.skills, profile.bio);

      final ranked = List<AgentPublicOfferModel>.from(list)
        ..sort((a, b) {
          final keyA = TunisiaLocationUtils.normalizeCityKey(a.city);
          final keyB = TunisiaLocationUtils.normalizeCityKey(b.city);
          final skillsA = SkillsMatchUtils.keywordScore(
            agentTokens,
            SkillsMatchUtils.offerCorpus(
              title: a.title,
              description: a.description,
              category: a.categoryName,
            ),
            category: a.categoryName,
          );
          final skillsB = SkillsMatchUtils.keywordScore(
            agentTokens,
            SkillsMatchUtils.offerCorpus(
              title: b.title,
              description: b.description,
              category: b.categoryName,
            ),
            category: b.categoryName,
          );
          return TunisiaLocationUtils.comparePublicOffersByLocation(
            agentCityKey: agentCityKey,
            offerCityKeyA: keyA,
            offerCityKeyB: keyB,
            skillsA: skillsA,
            skillsB: skillsB,
            idA: a.id,
            idB: b.id,
          );
        });

      final offers = ranked
          .where((offer) {
            final score = SkillsMatchUtils.keywordScore(
              agentTokens,
              SkillsMatchUtils.offerCorpus(
                title: offer.title,
                description: offer.description,
                category: offer.categoryName,
              ),
              category: offer.categoryName,
            );
            return score > 0;
          })
          .map(
            (offer) => RecommendedOfferModel(
              id: offer.id,
              title: offer.title,
              description: offer.description,
              budget: offer.budget,
              status: 'OPEN',
              category: offer.categoryName,
              city: offer.city,
              address: '',
              postalCode: '',
              clientId: 0,
              clientUsername: offer.clientName,
              clientRating: 0,
              clientCity: '',
              createdAt: null,
              matchScore: SkillsMatchUtils.keywordScore(
                agentTokens,
                SkillsMatchUtils.offerCorpus(
                  title: offer.title,
                  description: offer.description,
                  category: offer.categoryName,
                ),
                category: offer.categoryName,
              ),
              skillsScore: SkillsMatchUtils.keywordScore(
                agentTokens,
                SkillsMatchUtils.offerCorpus(
                  title: offer.title,
                  description: offer.description,
                  category: offer.categoryName,
                ),
                category: offer.categoryName,
              ),
              semanticScore: 0,
              keywordSkillsScore: 0,
              locationBoost: 0,
              locationTier: TunisiaLocationUtils.locationTier(
                agentCityKey: agentCityKey,
                offerCityKey: TunisiaLocationUtils.normalizeCityKey(offer.city),
              ),
              locationLabel: TunisiaLocationUtils.buildProximityLabel(
                agentCityDisplay: profile.city,
                agentCityKey: agentCityKey,
                offerCityDisplay: offer.city,
                offerCityKey: TunisiaLocationUtils.normalizeCityKey(offer.city),
                locationTier: TunisiaLocationUtils.locationTier(
                  agentCityKey: agentCityKey,
                  offerCityKey:
                      TunisiaLocationUtils.normalizeCityKey(offer.city),
                ),
              ),
              budgetBoost: 0,
              clientRatingBoost: 0,
              matchLevel: 'Skills match',
              aiReasons: [
                'Matched from your skills: ${profile.skills}',
              ],
            ),
          )
          .toList();

      final agentKey = TunisiaLocationUtils.normalizeAgentLocation(
        city: profile.city,
        address: profile.address,
      );
      final skillTokens = SkillsMatchUtils.parseSkillTokens(
        profile.skills,
        profile.bio,
      );
      return AiRecommendationsResult(
        agentCity: profile.city,
        sortBy: 'keyword_fallback',
        offers: sortRecommendedOffersByLocationAndNlp(
          offers: offers,
          agentCityKey: agentKey,
          agentCityDisplay: profile.city,
          agentSkillTokens: skillTokens,
        ),
      );
    } catch (_) {
      return AiRecommendationsResult(
        agentCity: '',
        sortBy: 'keyword_fallback',
        offers: [],
      );
    }
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
        _profileIncomplete = false;
      });
    }

    try {
      final result = await AiRecommendationService.fetchRecommendedOffers(
        limit: 50,
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
      final sortedOffers = sortRecommendedOffersByLocationAndNlp(
        offers: result.offers,
        agentCityKey: agentKey,
        agentCityDisplay: result.agentCity,
        agentSkillTokens: skillTokens,
      );
      final sortedResult = AiRecommendationsResult(
        agentCity: result.agentCity,
        sortBy: result.sortBy,
        offers: sortedOffers,
      );

      if (sortedResult.offers.isEmpty) {
        final fallback = await _loadKeywordFallback();
        if (!mounted) return;

        setState(() {
          _result = fallback;
          _agentSkillTokens = skillTokens;
          _isLoading = false;
          _error = fallback.offers.isEmpty
              ? 'No offers match your skills right now. Try updating your skills list.'
              : null;
        });
        return;
      }

      setState(() {
        _result = sortedResult;
        _agentSkillTokens = skillTokens;
        _agentCityKey = agentKey;
        _isLoading = false;
      });
    } on AiRecommendationException catch (e) {
      if (!mounted) return;

      if (e.isProfileIncomplete) {
        setState(() {
          _error = e.message;
          _profileIncomplete = true;
          _isLoading = false;
        });
        return;
      }

      final isSlowAi = e.message.toLowerCase().contains('too long') ||
          e.message.toLowerCase().contains('unable to reach');

      if (isSlowAi) {
        final fallback = await _loadKeywordFallback();
        if (!mounted) return;

        String agentKey = '';
        List<String> skillTokens = const [];
        try {
          final profile = await ProfileService.getAgentProfile();
          agentKey = TunisiaLocationUtils.normalizeAgentLocation(
            city: profile.city,
            address: profile.address,
          );
          skillTokens = SkillsMatchUtils.parseSkillTokens(
            profile.skills,
            profile.bio,
          );
        } catch (_) {
          // Profile is optional for displaying fallback results.
        }

        setState(() {
          _result = fallback;
          _agentCityKey = agentKey;
          _agentSkillTokens = skillTokens;
          _isLoading = false;
          _error = fallback.offers.isEmpty
              ? 'Could not load matches. Check your connection and try again.'
              : null;
        });

        if (fallback.offers.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Showing skill-based matches while the AI model warms up.',
              ),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      setState(() {
        _error = e.message;
        _profileIncomplete = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final background = AiMatchesTheme.screenBackground(isDarkMode);
    final cardColor = AiMatchesTheme.cardBackground(isDarkMode);
    final borderColor = AiMatchesTheme.cardBorder(isDarkMode);
    final primaryText = AiMatchesTheme.primaryText(isDarkMode);
    final secondaryText = AiMatchesTheme.secondaryText(isDarkMode);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AppBackButton(isDarkMode: isDarkMode),
        title: Text(
          'AI Matches',
          style: TextStyle(
            color: primaryText,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: OfferSearchBar(
              controller: _searchController,
              isDarkMode: isDarkMode,
              activeFilterCount: _searchFilters.activeFilterCount,
              onFilterTap: _openFilters,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => setState(() {}),
              onClear: () {
                _searchController.clear();
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: _buildBody(
                isDarkMode: isDarkMode,
                cardColor: cardColor,
                borderColor: borderColor,
                primaryText: primaryText,
                secondaryText: secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required bool isDarkMode,
    required Color cardColor,
    required Color borderColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator(color: AppColors.accent)),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _EmptyStateCard(
            isDarkMode: isDarkMode,
            icon: _profileIncomplete
                ? Icons.person_outline_rounded
                : Icons.error_outline_rounded,
            title: _profileIncomplete
                ? 'Complete your profile'
                : 'Could not load matches',
            message: _error!,
            actionLabel: _profileIncomplete ? null : 'Try again',
            onAction: _profileIncomplete ? null : _load,
          ),
        ],
      );
    }

    final allOffers = _result?.offers ?? [];
    if (allOffers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _EmptyStateCard(
            isDarkMode: isDarkMode,
            icon: Icons.work_outline_rounded,
            title: 'No matches yet',
            message:
                'There are no open offers that fit your profile right now. Check back later or browse all offers.',
            actionLabel: 'Refresh',
            onAction: _load,
          ),
        ],
      );
    }

    final offers = _visibleOffers;
    if (offers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _EmptyStateCard(
            isDarkMode: isDarkMode,
            icon: Icons.search_off_rounded,
            title: 'No results',
            message:
                'Nothing matches your search or filters. Try "pet", a category name, or reset filters.',
            actionLabel: 'Clear search',
            onAction: () {
              setState(() {
                _searchController.clear();
                _searchFilters = const OfferSearchFilters();
              });
            },
          ),
        ],
      );
    }

    final sections = groupRecommendedOffersWithSkillsHighlight(
      offers: offers,
      agentCityKey: _agentCityKey,
      agentSkillTokens: _agentSkillTokens,
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _SortBanner(
          totalCount: offers.length,
          totalAvailable: allOffers.length,
          isDarkMode: isDarkMode,
          primaryText: primaryText,
        ),
        const SizedBox(height: 20),
        for (final section in sections) ...[
          _SectionHeader(
            title: section.title,
            subtitle: section.subtitle,
            count: section.offers.length,
            isDarkMode: isDarkMode,
            primaryText: primaryText,
            secondaryText: secondaryText,
          ),
          const SizedBox(height: 12),
          for (final offer in section.offers) ...[
            RecommendedOfferTile(
              offer: offer,
              isDarkMode: isDarkMode,
              primaryTextColor: primaryText,
              secondaryTextColor: secondaryText,
              cardColor: cardColor,
              borderColor: borderColor,
              onTap: () => showRecommendedOfferDetailsSheet(
                context,
                offer: offer,
                isDarkMode: isDarkMode,
                onLiked: _handleOfferLiked,
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SortBanner extends StatelessWidget {
  final int totalCount;
  final int totalAvailable;
  final bool isDarkMode;
  final Color primaryText;

  const _SortBanner({
    required this.totalCount,
    required this.totalAvailable,
    required this.isDarkMode,
    required this.primaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AiMatchesTheme.cardBackground(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AiMatchesTheme.cardBorder(isDarkMode)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.accent.withOpacity(0.12)
                  : AppColors.accentSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.route_outlined,
              color: AppColors.forTheme(isDarkMode),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalCount < totalAvailable
                      ? '$totalCount of $totalAvailable recommended offers'
                      : '$totalCount recommended offers for you',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final bool isDarkMode;
  final Color primaryText;
  final Color secondaryText;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.isDarkMode,
    required this.primaryText,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF1F2937)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: AiMatchesTheme.primaryText(isDarkMode),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final bool isDarkMode;
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyStateCard({
    required this.isDarkMode,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AiMatchesTheme.primaryText(isDarkMode);
    final secondary = AiMatchesTheme.secondaryText(isDarkMode);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AiMatchesTheme.cardBackground(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AiMatchesTheme.cardBorder(isDarkMode)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.forTheme(isDarkMode)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: secondary, height: 1.4),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
