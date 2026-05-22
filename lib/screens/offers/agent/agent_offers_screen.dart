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
  List<SwipeOfferCardData> _offers = [];
  bool _isLoading = true;
  String? _loadError;

  // Fallback removed after API load — kept empty until _loadOffers runs.
  final List<SwipeOfferCardData> _fallbackOffers = [
    SwipeOfferCardData(
      id: 1,
      clientUserId: 0,
      title: 'Flutter marketplace app polish',
      category: 'Mobile Development',
      city: 'Tunis',
      budget: '1200 DT',
      clientName: 'JobMatch Client',
      description:
          'We need a Flutter developer to refine UI quality, improve user flows, and connect polished screens to backend APIs for a service marketplace app.',
      imageUrls: [
        'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1551650975-87deedd944c3?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1200&q=80',
                'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1551650975-87deedd944c3?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1200&q=80',
                'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1551650975-87deedd944c3?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1200&q=80',
                'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1551650975-87deedd944c3?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1200&q=80',
                'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1551650975-87deedd944c3?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1200&q=80',
                'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1551650975-87deedd944c3?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1200&q=80',
      ],
      skills: ['Flutter', 'UI polish', 'API integration'],
      highlights: ['Responsive UI', 'Clean structure', 'Premium finish'],
    ),
    SwipeOfferCardData(
      id: 2,
      clientUserId: 0,
      title: 'Restaurant booking mobile app UI',
      category: 'UI / UX',
      city: 'Sousse',
      budget: '850 DT',
      clientName: 'Restaurant Group',
      description:
          'The client wants a modern booking experience with smooth navigation, refined layout hierarchy, and clean interactive screens for mobile users.',
      imageUrls: [
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?auto=format&fit=crop&w=1200&q=80',
      ],
      skills: ['UI Design', 'Mobile UX', 'Booking flow'],
      highlights: ['User journey', 'Modern visuals', 'Clear hierarchy'],
    ),
    SwipeOfferCardData(
      id: 3,
      clientUserId: 0,
      title: 'Delivery app frontend integration',
      category: 'Frontend Integration',
      city: 'Ariana',
      budget: '1400 DT',
      clientName: 'Local Startup',
      description:
          'We are looking for a frontend-focused developer to connect production-ready screens, authentication, tracking states, and reusable components.',
      imageUrls: [
        'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?auto=format&fit=crop&w=1200&q=80',
      ],
      skills: ['Reusable widgets', 'Tracking UI', 'Auth flow'],
      highlights: ['Clean architecture', 'API ready', 'Scalable screens'],
    ),
  ];

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

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
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
    if (_offers.isEmpty) return;

    final offer = _offers.first;

    setState(() {
      _offers.removeAt(0);
      _dragOffset = Offset.zero;
    });

    if (isLike) {
      try {
        final price = double.tryParse(
          offer.budget.replaceAll(RegExp(r'[^0-9.]'), ''),
        );

        await OfferReactionService.recordAgentLikeOffer(
          offerId: offer.id,
          proposedPrice: price,
        );
      } on InteractionServiceException catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isLike
              ? 'Interest sent for "${offer.title}"'
              : 'You skipped "${offer.title}"',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF151515),
      ),
    );
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

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