import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/offer_interaction_model.dart';
import '../../../services/interaction_service.dart';
import '../../../services/offer_reaction_service.dart';
import '../../../services/offer_service.dart';
import '../widgets/offer_swipe_card.dart';

class AgentOffersScreen extends StatefulWidget {
  const AgentOffersScreen({super.key});

  @override
  State<AgentOffersScreen> createState() => _AgentOffersScreenState();
}

class _AgentOffersScreenState extends State<AgentOffersScreen> {
  final List<SwipeOfferCardData> _offers = [];

  bool _isLoadingInitial = true;
  String? _loadError;
  bool _isSubmittingReaction = false;

  Offset _dragOffset = Offset.zero;

  bool get _isEmpty => !_isLoading && _offers.isEmpty;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final remote = await OfferService.getBrowseOffers();
      if (!mounted) return;

      setState(() {
        _offers = remote.isNotEmpty
            ? remote.map(_mapBrowseOffer).toList()
            : List<SwipeOfferCardData>.from(_fallbackOffers);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _offers = List<SwipeOfferCardData>.from(_fallbackOffers);
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  SwipeOfferCardData _mapBrowseOffer(BrowseOfferModel offer) {
    return SwipeOfferCardData(
      id: offer.id,
      clientUserId: offer.clientUserId,
      title: offer.title,
      category: offer.category,
      city: offer.city,
      budget: offer.budgetLabel,
      clientName: offer.clientName,
      description: offer.description,
      imageUrls: offer.imageUrls
          .map(OfferService.resolveImageUrl)
          .where((url) => url.isNotEmpty)
          .toList(),
      skills: const ['Service', 'Professional'],
      highlights: const ['Open offer', 'Client verified'],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoadingInitial = true;
      _loadError = null;
    });

    try {
      final list = await OfferService.fetchAgentOffers();
      if (!mounted) return;

      setState(() {
        _offers
          ..clear()
          ..addAll(list.map(_toSwipeCard));
        _isLoadingInitial = false;
      });
    } on OfferException catch (e) {
      if (!mounted) return;

      setState(() {
        _offers.clear();
        _loadError = e.message;
        _isLoadingInitial = false;
      });
    }
  }

  SwipeOfferCardData _toSwipeCard(AgentPublicOfferModel m) {
    final skills = m.skills.isNotEmpty
        ? m.skills
        : (m.categoryName.isNotEmpty ? [m.categoryName] : <String>[]);

    return SwipeOfferCardData(
      id: m.id,
      title: m.title.isEmpty ? 'Untitled offer' : m.title,
      category: m.categoryName.isEmpty ? 'Uncategorized' : m.categoryName,
      city: m.city.isEmpty ? 'Location not specified' : m.city,
      budget: m.budgetLabel,
      clientName: m.clientName.isEmpty ? 'Client' : m.clientName,
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

      if (!mounted) return;

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
    } on InteractionException catch (e) {
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
                    '${offer.category} · ${offer.city}',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                    'Client: ${offer.clientName}',
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
                  const SizedBox(height: 18),
                  Text(
                    'Highlights',
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
                    children: offer.highlights.map((item) {
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
                ],
              ),
            ),
          ),
        );
      },
    );
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
    final cardColor =
        isDarkMode ? const Color(0xFF151515) : const Color(0xFFF5F5F5);

    return Center(
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No more offers for now',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'New offers will appear here soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeck(bool isDarkMode) {
    final topOffer = _offers.first;
    final nextOffer = _offers.length > 1 ? _offers[1] : null;

    final rotation = _dragOffset.dx / 420;
    final overlayColor = _dragOffset.dx > 0
        ? const Color(0xFF16A34A)
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
                  color: Colors.black.withOpacity(0.12),
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
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      );
    } else if (_loadError != null) {
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
        child: SizedBox.expand(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF22C55E),
                  ),
                )
              : _isEmpty
                  ? _buildEmptyState(isDarkMode)
                  : _buildDeck(isDarkMode),
        ),
      ),
    );
  }
}
