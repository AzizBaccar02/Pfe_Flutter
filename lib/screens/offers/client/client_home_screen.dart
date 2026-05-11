import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/client_offer_model.dart';
import '../../../services/offer_service.dart';
import '../../../services/profile_service.dart';
import '../widgets/home_empty_card.dart';
import '../widgets/home_recent_offer_card.dart';
import '../widgets/home_section_title.dart';
import '../widgets/home_stat_card.dart';
import '../widgets/home_hero_card.dart';

class ClientHomeScreen extends StatefulWidget {
  final VoidCallback onCreateOfferTap;
  final VoidCallback onMyOffersTap;
  final VoidCallback onInterestedTap;
  final VoidCallback onChatsTap;
  final ScrollController? scrollController;

  const ClientHomeScreen({
    super.key,
    required this.onCreateOfferTap,
    required this.onMyOffersTap,
    required this.onInterestedTap,
    required this.onChatsTap,
    this.scrollController,
  });

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<ClientOfferModel> _offers = [];
  String _clientName = 'Client';

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final offers = await OfferService.fetchMyOffers();

      String nextClientName = _clientName;

      try {
        final profile = await ProfileService.getClientProfile();

        final fullName = [
          profile.firstName.trim(),
          profile.lastName.trim(),
        ].where((part) => part.isNotEmpty).join(' ');

        if (fullName.isNotEmpty) {
          nextClientName = fullName;
        }
      } catch (_) {
        // Keep fallback name if profile loading fails.
      }

      if (!mounted) return;

      setState(() {
        _offers = offers;
        _clientName = nextClientName;
        _errorMessage = null;
      });
    } on OfferException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load your offers. Please try again.';
      });
    } finally {
      if (mounted && showLoader) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int get _totalOffers => _offers.length;

  int get _openOffers {
    return _offers.where((offer) => offer.status == OfferStatus.open).length;
  }

  int get _closedOffers {
    return _offers.where((offer) => offer.status == OfferStatus.closed).length;
  }

  int get _totalInterestedAgents {
    return _offers.fold<int>(
      0,
      (total, offer) => total + offer.interestedAgentsCount,
    );
  }

  List<ClientOfferModel> get _recentOffers {
    return _offers.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    return Container(
      color: backgroundColor,
      child: RefreshIndicator(
        onRefresh: () => _loadHomeData(showLoader: false),
        child: SingleChildScrollView(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeroCard(
                isDarkMode: isDarkMode,
                clientName: _clientName,
                onCreateOfferTap: widget.onCreateOfferTap,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                _HomeLoadingState(isDarkMode: isDarkMode)
              else ...[
                if (_errorMessage != null)
                  _HomeErrorCard(
                    message: _errorMessage!,
                    isDarkMode: isDarkMode,
                    onRetry: () => _loadHomeData(),
                  ),
                HomeSectionTitle(
                  title: 'Overview',
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: HomeStatCard(
                        title: 'Total Offers',
                        value: _totalOffers.toString(),
                        icon: HugeIcons.strokeRoundedWork,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HomeStatCard(
                        title: 'Open Offers',
                        value: _openOffers.toString(),
                        icon: HugeIcons.strokeRoundedTaskDone01,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: HomeStatCard(
                        title: 'Interested',
                        value: _totalInterestedAgents.toString(),
                        icon: HugeIcons.strokeRoundedFavourite,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HomeStatCard(
                        title: 'Closed Offers',
                        value: _closedOffers.toString(),
                        icon: HugeIcons.strokeRoundedArchive,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                HomeSectionTitle(
                  title: 'Recent Offers',
                  actionText: 'See all',
                  onActionTap: widget.onMyOffersTap,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
                if (_recentOffers.isEmpty)
                  HomeEmptyCard(
                    text: 'You have not created any offers yet.',
                    isDarkMode: isDarkMode,
                  )
                else
                  SizedBox(
                    height: 360,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentOffers.length,
                      itemBuilder: (context, index) {
                        final offer = _recentOffers[index];

                        return HomeRecentOfferCard(
                          offer: offer,
                          isDarkMode: isDarkMode,
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                HomeSectionTitle(
                  title: 'Interested Agents',
                  actionText: 'See all',
                  onActionTap: widget.onInterestedTap,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 12),
                HomeEmptyCard(
                  text:
                      'Interested agents will appear here after agents react to your offers.',
                  isDarkMode: isDarkMode,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeLoadingState extends StatelessWidget {
  final bool isDarkMode;

  const _HomeLoadingState({
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }
}

class _HomeErrorCard extends StatelessWidget {
  final String message;
  final bool isDarkMode;
  final VoidCallback onRetry;

  const _HomeErrorCard({
    required this.message,
    required this.isDarkMode,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFF3F3F3);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.66)
        : Colors.black.withValues(alpha: 0.66);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Could not refresh home data',
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: isDarkMode ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}