import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/agent_public_offer_model.dart';
import '../../../models/app_notification_model.dart';
import '../../../models/recommended_offer_model.dart';
import '../../../services/agent_offers_realtime.dart';
import '../../../services/agent_reactions_realtime.dart';
import '../../../services/tab_auto_refresh.dart';
import '../../../services/ai_recommendation_service.dart';
import '../../../services/interaction_service.dart';
import '../../../services/offer_service.dart';
import '../../../services/profile_service.dart';
import '../../../utils/agent_identity_privacy.dart';
import '../../../utils/skills_match_utils.dart';
import '../../../utils/tunisia_location_utils.dart';
import '../../subscription/widgets/usage_limit_dialog.dart';
import '../widgets/offer_swipe_card.dart';

class AgentOffersScreen extends StatefulWidget {
  final bool isTabActive;

  const AgentOffersScreen({
    super.key,
    this.isTabActive = true,
  });

  @override
  State<AgentOffersScreen> createState() => _AgentOffersScreenState();
}

class _AgentOffersScreenState extends State<AgentOffersScreen>
    with WidgetsBindingObserver {
  final List<SwipeOfferCardData> _offers = [];
  final Set<int> _reactedOfferIds = {};

  bool _isLoadingInitial = true;
  bool _isRefiningWithAi = false;
  bool _isRefillingDeck = false;
  String? _loadError;
  bool _isSubmittingReaction = false;
  bool _usingAiRanking = false;

  Offset _dragOffset = Offset.zero;

  late final TabAutoRefresh _autoRefresh;
  StreamSubscription<AppNotificationModel>? _newOfferSubscription;
  bool _isSyncingOffers = false;

  bool get _isEmpty => !_isLoadingInitial && _offers.isEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bindNewOfferPush();
    _autoRefresh = TabAutoRefresh(
      onRefresh: ({showLoader = true}) async {
        await _syncNewOffers(showSnackBar: false);
      },
      isTabActive: () => widget.isTabActive,
      pollInterval: const Duration(seconds: 12),
    );
    _autoRefresh.attach();
    _loadOffers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefresh.dispose();
    _newOfferSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncNewOffers());
    }
  }

  @override
  void didUpdateWidget(covariant AgentOffersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTabActive && !oldWidget.isTabActive) {
      _autoRefresh.onTabBecameActive();
    }
  }

  void _bindNewOfferPush() {
    final hub = AgentOffersRealtime.instance;
    hub.ensureStarted();

    _newOfferSubscription = hub.onNewOffer.listen((notification) {
      if (!mounted) return;
      unawaited(_handleNewOfferNotification(notification));
    });
  }

  Future<void> _handleNewOfferNotification(
    AppNotificationModel notification,
  ) async {
    final offerId = notification.offerId;
    if (offerId != null && offerId > 0) {
      final offer = await OfferService.fetchAgentOfferById(offerId);
      if (offer != null) {
        _prependOffers([offer], showSnackBar: true);
      }
    }

    await _syncNewOffers(showSnackBar: false);
  }

  void _prependOffers(
    List<AgentPublicOfferModel> incoming, {
    bool showSnackBar = false,
  }) {
    if (incoming.isEmpty || !mounted) return;

    final freshCards = incoming
        .where(
          (offer) =>
              offer.id > 0 &&
              !_reactedOfferIds.contains(offer.id) &&
              !_offers.any((card) => card.id == offer.id),
        )
        .map(_publicToSwipeCard)
        .toList();

    if (freshCards.isEmpty) return;

    setState(() {
      _offers.insertAll(0, freshCards);
      _isLoadingInitial = false;
      _loadError = null;
    });

    if (showSnackBar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            freshCards.length == 1
                ? 'New offer: ${freshCards.first.title}'
                : '${freshCards.length} new offers available',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF151515),
        ),
      );
    }
  }

  /// Merges newly posted offers into the deck without clearing reactions.
  Future<void> _syncNewOffers({bool showSnackBar = false}) async {
    if (_isSyncingOffers || !mounted) return;

    _isSyncingOffers = true;
    try {
      final profile = await ProfileService.getAgentProfile();
      final list = await OfferService.fetchAgentOffers();

      final deckIds = _offers.map((o) => o.id).toSet();
      final fresh = list
          .where(
            (offer) =>
                !deckIds.contains(offer.id) &&
                !_reactedOfferIds.contains(offer.id),
          )
          .toList();

      if (fresh.isEmpty || !mounted) return;

      final sorted = _sortPublicOffers(
        fresh,
        agentCity: profile.city,
        agentAddress: profile.address,
        agentSkills: profile.skills,
        agentBio: profile.bio,
      );

      if (!mounted) return;

      final previousCount = _offers.length;
      _prependOffers(sorted, showSnackBar: showSnackBar);

      if (previousCount == 0 && _offers.isNotEmpty && mounted) {
        setState(() {
          _isLoadingInitial = false;
          _loadError = null;
        });
      }
    } on OfferException {
      // Silent — polling should not disrupt the deck.
    } finally {
      _isSyncingOffers = false;
    }
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoadingInitial = true;
      _loadError = null;
      _usingAiRanking = false;
      _reactedOfferIds.clear();
    });

    // Fast preview: location + keyword skills (no NLP wait).
    await _loadOffersFallback(previewOnly: true);

    if (mounted && _offers.isNotEmpty) {
      setState(() {
        _isLoadingInitial = false;
        _isRefiningWithAi = true;
      });
    }

    try {
      final result = await AiRecommendationService.fetchRecommendedOffers(
        limit: 30,
        sort: AiRecommendationService.sortLocationSkills,
      );

      if (!mounted) return;

      if (result.offers.isEmpty) {
        if (_offers.isEmpty) {
          await _loadOffersFallback();
        } else {
          setState(() => _isRefiningWithAi = false);
        }
        return;
      }

      final profile = await ProfileService.getAgentProfile();
      if (!mounted) return;

      _applyAiRecommendations(
        result.offers,
        agentCity: profile.city.isNotEmpty ? profile.city : result.agentCity,
        agentAddress: profile.address,
        agentSkillTokens: SkillsMatchUtils.parseSkillTokens(
          profile.skills,
          profile.bio,
        ),
      );
    } on AiRecommendationException catch (e) {
      if (!mounted) return;

      if (e.isProfileIncomplete) {
        await _loadOffersFallback(profileMessage: e.message);
        return;
      }

      setState(() {
        _loadError = e.message;
        _isLoadingInitial = false;
        _isRefiningWithAi = false;
      });
    } on OfferException catch (e) {
      if (!mounted) return;

      if (_offers.isEmpty) {
        setState(() {
          _offers.clear();
          _loadError = e.message;
          _isLoadingInitial = false;
        });
      }
    }
  }

  Future<void> _loadOffersFallback({
    String? profileMessage,
    bool previewOnly = false,
  }) async {
    try {
      final profile = await ProfileService.getAgentProfile();
      final list = await OfferService.fetchAgentOffers();
      final sorted = _sortPublicOffers(
        list,
        agentCity: profile.city,
        agentAddress: profile.address,
        agentSkills: profile.skills,
        agentBio: profile.bio,
      );

      if (!mounted) return;

      setState(() {
        _offers
          ..clear()
          ..addAll(
            sorted
                .where((offer) => !_reactedOfferIds.contains(offer.id))
                .map(_publicToSwipeCard),
          );
        _usingAiRanking = false;
        if (!previewOnly) {
          _isLoadingInitial = false;
          _isRefiningWithAi = false;
          _loadError = profileMessage;
        }
      });
    } on OfferException catch (e) {
      if (!mounted) return;

      setState(() {
        _offers.clear();
        _loadError = profileMessage ?? e.message;
        _isLoadingInitial = false;
      });
    }
  }

  List<AgentPublicOfferModel> _sortPublicOffers(
    List<AgentPublicOfferModel> list, {
    required String agentCity,
    String? agentAddress,
    required String agentSkills,
    required String agentBio,
  }) {
    final agentCityKey = TunisiaLocationUtils.normalizeAgentLocation(
      city: agentCity,
      address: agentAddress,
    );
    final agentTokens =
        SkillsMatchUtils.parseSkillTokens(agentSkills, agentBio);

    final withSkills = list.where((offer) {
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
    }).toList();

    return List<AgentPublicOfferModel>.from(
      withSkills.isNotEmpty ? withSkills : list,
    )..sort((a, b) {
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
  }

  /// Re-ranks the current deck using AI results instead of replacing it with
  /// only the top AI matches (which could be a single offer).
  void _applyAiRecommendations(
    List<RecommendedOfferModel> aiOffers, {
    required String agentCity,
    List<String> agentSkillTokens = const [],
    String? agentAddress,
  }) {
    if (!mounted) return;

    final agentKey = TunisiaLocationUtils.normalizeAgentLocation(
      city: agentCity,
      address: agentAddress,
    );
    final sortedAi = sortRecommendedOffersByLocationAndNlp(
      offers: aiOffers,
      agentCityKey: agentKey,
      agentCityDisplay: agentCity,
      agentSkillTokens: agentSkillTokens,
    );
    final aiCards = sortedAi.map(_recommendedToSwipeCard).toList();
    final aiRank = <int, int>{
      for (var i = 0; i < aiCards.length; i++) aiCards[i].id: i,
    };

    final knownIds = {..._reactedOfferIds, ..._offers.map((o) => o.id)};
    final newFromAi =
        aiCards.where((card) => !knownIds.contains(card.id)).toList();

    final currentDeck = List<SwipeOfferCardData>.from(_offers);
    currentDeck.sort((a, b) {
      final rankA = aiRank[a.id];
      final rankB = aiRank[b.id];
      if (rankA != null && rankB != null) return rankA.compareTo(rankB);
      if (rankA != null) return -1;
      if (rankB != null) return 1;
      return 0;
    });

    setState(() {
      _offers
        ..clear()
        ..addAll(newFromAi)
        ..addAll(
          currentDeck.where(
            (card) => !newFromAi.any((added) => added.id == card.id),
          ),
        );
      _usingAiRanking = true;
      _isLoadingInitial = false;
      _isRefiningWithAi = false;
      _loadError = null;
    });
  }

  Future<void> _refillDeckAfterSwipe() async {
    if (_isRefillingDeck || !mounted) return;

    _isRefillingDeck = true;
    try {
      final profile = await ProfileService.getAgentProfile();
      final list = await OfferService.fetchAgentOffers();

      final deckIds = _offers.map((o) => o.id).toSet();
      final fresh = list
          .where(
            (offer) =>
                !deckIds.contains(offer.id) &&
                !_reactedOfferIds.contains(offer.id),
          )
          .toList();

      if (fresh.isEmpty || !mounted) return;

      final sorted = _sortPublicOffers(
        fresh,
        agentCity: profile.city,
        agentSkills: profile.skills,
        agentBio: profile.bio,
      );

      if (!mounted) return;

      setState(() {
        _offers.addAll(sorted.map(_publicToSwipeCard));
        _loadError = null;
      });
    } on OfferException {
      // Keep current deck/empty state; user can pull refresh manually.
    } finally {
      _isRefillingDeck = false;
    }
  }

  SwipeOfferCardData _recommendedToSwipeCard(RecommendedOfferModel m) {
    final skills = m.category.isNotEmpty ? [m.category] : <String>[];
    final highlights = m.aiReasons.take(3).toList();

    return SwipeOfferCardData(
      id: m.id,
      clientUserId: m.clientId,
      title: m.title.isEmpty ? 'Untitled offer' : m.title,
      category: m.category.isEmpty ? 'Uncategorized' : m.category,
      city: m.displayCity.isEmpty ? 'Location not specified' : m.displayCity,
      budget: m.budgetLabel,
      clientFullName: m.clientUsername,
      description: m.description.isEmpty
          ? 'No description provided.'
          : m.description,
      imageUrls: const [],
      skills: skills,
      highlights: highlights,
      locationLabel: m.locationLabel.isNotEmpty ? m.locationLabel : null,
      matchScoreLabel: m.matchScoreLabel,
    );
  }

  SwipeOfferCardData _publicToSwipeCard(AgentPublicOfferModel m) {
    final skills = m.skills.isNotEmpty
        ? m.skills
        : (m.categoryName.isNotEmpty ? [m.categoryName] : <String>[]);

    return SwipeOfferCardData(
      id: m.id,
      clientUserId: 0,
      title: m.title.isEmpty ? 'Untitled offer' : m.title,
      category: m.categoryName.isEmpty ? 'Uncategorized' : m.categoryName,
      city: m.city.isEmpty ? 'Location not specified' : m.city,
      budget: m.budgetLabel,
      clientFullName: m.clientName,
      description: m.description.isEmpty
          ? 'No description provided.'
          : m.description,
      imageUrls: m.imageUrls,
      skills: skills,
      highlights: m.highlights,
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isSubmittingReaction) return;

    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isSubmittingReaction) return;

    const threshold = 120.0;

    if (_dragOffset.dx > threshold) {
      _commitSwipe(isLike: true);
      return;
    }

    if (_dragOffset.dx < -threshold) {
      _commitSwipe(isLike: false);
      return;
    }

    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  Future<void> _commitSwipe({required bool isLike}) async {
    if (_offers.isEmpty || _isSubmittingReaction) return;

    final offer = _offers.first;

    setState(() {
      _isSubmittingReaction = true;
    });

    try {
      await InteractionService.reactToOffer(
        offerId: offer.id,
        react: isLike,
      );

      AgentReactionsRealtime.instance.notifyRefresh();

      if (!mounted) return;

      _reactedOfferIds.add(offer.id);

      setState(() {
        _offers.removeAt(0);
        _dragOffset = Offset.zero;
        _isSubmittingReaction = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLike
                ? 'You reacted to "${offer.title}"'
                : 'You skipped "${offer.title}"',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF151515),
        ),
      );

      if (_offers.isEmpty) {
        await _syncNewOffers();
        if (_offers.isEmpty) {
          await _refillDeckAfterSwipe();
        }
      }
    } on InteractionServiceException catch (e) {
      if (!mounted) return;

      setState(() {
        _dragOffset = Offset.zero;
        _isSubmittingReaction = false;
      });

      if (UsageLimitDialog.isUsageLimitMessage(e.message)) {
        await UsageLimitDialog.show(
          context,
          isAgent: true,
          message: e.message,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _dragOffset = Offset.zero;
        _isSubmittingReaction = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your reaction. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
    }
  }

  void _openDetails(SwipeOfferCardData offer) {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.68)
        : Colors.black.withOpacity(0.62);

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    offer.title,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${offer.category} · ${offer.locationLabel ?? offer.city}',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (offer.matchScoreLabel != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      offer.matchScoreLabel!,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Budget: ${offer.budget}',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AgentIdentityPrivacy.clientPublicLabel(
                      offer.clientFullName.isEmpty
                          ? null
                          : offer.clientFullName,
                    ),
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      offer.description,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Required skills',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: offer.skills.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (offer.highlights.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Match insights',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...offer.highlights.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '• $item',
                          style: TextStyle(
                            color: secondaryTextColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileBanner(bool isDarkMode) {
    return const SizedBox.shrink();
  }

  Widget _buildInitialError(bool isDarkMode) {
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.68)
        : Colors.black.withOpacity(0.62);
    final cardColor =
        isDarkMode ? const Color(0xFF151515) : const Color(0xFFF5F5F5);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Text(
                    'Could not load offers',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loadError ?? 'Please try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loadOffers,
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.68)
        : Colors.black.withOpacity(0.62);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async {
        await _syncNewOffers();
        if (_offers.isEmpty) {
          await _loadOffers();
        }
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No offers right now',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'New client offers appear here automatically. Pull down to refresh.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isRefillingDeck || _isSyncingOffers
                          ? null
                          : _loadOffers,
                      child: _isRefillingDeck || _isSyncingOffers
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Refresh offers'),
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

  Widget _buildDeck(bool isDarkMode) {
    final topOffer = _offers.first;
    final nextOffer = _offers.length > 1 ? _offers[1] : null;

    final rotation = _dragOffset.dx / 420;
    final overlayColor = _dragOffset.dx > 0
        ? AppColors.accent
        : const Color(0xFFDC2626);

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 120),
              opacity: _dragOffset.dx.abs() > 18 ? 0.10 : 0,
              child: Container(color: overlayColor),
            ),
          ),

          if (nextOffer != null)
            Positioned.fill(
              child: Transform.scale(
                scale: 1.0,
                child: Opacity(
                  opacity: 0.45,
                  child: OfferSwipeCard(
                    offer: nextOffer,
                    isDarkMode: isDarkMode,
                    onLikeTap: () {},
                    onDislikeTap: () {},
                    onDetailsTap: () => _openDetails(nextOffer),
                    dragDx: 0,
                  ),
                ),
              ),
            ),

          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Transform.translate(
                offset: _dragOffset,
                child: Transform.rotate(
                  angle: rotation,
                  child: OfferSwipeCard(
                    offer: topOffer,
                    isDarkMode: isDarkMode,
                    onLikeTap: () => _commitSwipe(isLike: true),
                    onDislikeTap: () => _commitSwipe(isLike: false),
                    onDetailsTap: () => _openDetails(topOffer),
                    dragDx: _dragOffset.dx,
                  ),
                ),
              ),
            ),
          ),

          if (_isSubmittingReaction)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.12),
                  child: const Center(
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    Widget body;

    if (_isLoadingInitial) {
      body = const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            SizedBox(height: 14),
            Text(
              'Finding nearby offers that match your skills…',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    } else if (_loadError != null && _isEmpty) {
      body = _buildInitialError(isDarkMode);
    } else if (_isEmpty) {
      body = _buildEmptyState(isDarkMode);
    } else {
      body = _buildDeck(isDarkMode);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            if (_isRefiningWithAi)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDarkMode
                    ? const Color(0xFF1A2E1A)
                    : const Color(0xFFECFDF5),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Matching your skills to nearby offers…',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _buildProfileBanner(isDarkMode),
            Expanded(
              child: _isEmpty || _isLoadingInitial
                  ? body
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                      child: body,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
