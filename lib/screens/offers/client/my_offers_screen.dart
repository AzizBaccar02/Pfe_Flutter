import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/app_colors.dart';
import '../../../conf/theme_provider.dart';
import '../../../models/client_offer_model.dart';
import '../../../services/offer_service.dart';
import 'offer_detail_screen.dart';
import '../widgets/my_offer_card.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  String _selectedFilter = 'All';

  bool _isLoading = true;
  bool _isMutating = false;
  String? _errorMessage;

  List<ClientOfferModel> _offers = [];

  int get _openCount =>
      _offers.where((o) => o.status == OfferStatus.open).length;

  int get _closedCount =>
      _offers.where((o) => o.status == OfferStatus.closed).length;

  int get _archivedCount =>
      _offers.where((o) => o.status == OfferStatus.archived).length;

  int get _totalInterested =>
      _offers.fold<int>(0, (sum, o) => sum + o.interestedAgentsCount);

  List<ClientOfferModel> get _filteredOffers {
    return switch (_selectedFilter) {
      'Open' => _offers.where((o) => o.status == OfferStatus.open).toList(),
      'Closed' => _offers.where((o) => o.status == OfferStatus.closed).toList(),
      'Archived' =>
        _offers.where((o) => o.status == OfferStatus.archived).toList(),
      _ => _offers,
    };
  }

  int _countForFilter(String filter) => switch (filter) {
        'Open' => _openCount,
        'Closed' => _closedCount,
        'Archived' => _archivedCount,
        _ => _offers.length,
      };

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final offers = await OfferService.fetchMyOffers();

      if (!mounted) return;

      setState(() {
        _offers = offers;
        _errorMessage = null;
      });
    } on OfferException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load your offers. Please try again.';
      });
    } finally {
      if (mounted && showLoader) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateOfferStatus({
    required ClientOfferModel offer,
    required OfferStatus status,
  }) async {
    if (_isMutating) return;

    setState(() => _isMutating = true);

    try {
      final updated = await OfferService.updateOfferStatus(
        offerId: offer.id,
        status: status,
      );

      if (!mounted) return;

      setState(() {
        _offers = _offers
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });

      _showSnackBar('Offer updated successfully');
    } on OfferException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Unable to update offer. Please try again.');
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _confirmDeleteOffer(ClientOfferModel offer) async {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF161616) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Delete offer?',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          '“${offer.title}” will be permanently removed.',
          style: TextStyle(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.black.withValues(alpha: 0.65),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) await _deleteOffer(offer);
  }

  Future<void> _deleteOffer(ClientOfferModel offer) async {
    if (_isMutating) return;

    setState(() => _isMutating = true);

    try {
      await OfferService.deleteOffer(offerId: offer.id);

      if (!mounted) return;

      setState(() {
        _offers = _offers.where((item) => item.id != offer.id).toList();
      });

      _showSnackBar('Offer deleted');
    } on OfferException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Unable to delete offer.');
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF151515),
      ),
    );
  }

  Future<void> _openOfferDetails(ClientOfferModel offer) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => OfferDetailScreen(
          offer: offer,
          onOfferUpdated: () => _loadOffers(showLoader: false),
        ),
      ),
    );

    if (!mounted) return;
    await _loadOffers(showLoader: false);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : const Color(0xFFF6F7F9);
    final primary = isDarkMode ? Colors.white : Colors.black;
    final secondary = isDarkMode
        ? Colors.white.withValues(alpha: 0.62)
        : Colors.black.withValues(alpha: 0.58);

    return Container(
      color: backgroundColor,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : _errorMessage != null && _offers.isEmpty
              ? _ErrorState(
                  message: _errorMessage!,
                  isDarkMode: isDarkMode,
                  onRetry: _loadOffers,
                )
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () => _loadOffers(showLoader: false),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Offers',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _offers.isEmpty
                                    ? 'Manage your posted jobs'
                                    : '${_offers.length} offer${_offers.length == 1 ? '' : 's'} · $_totalInterested interested agents',
                                style: TextStyle(
                                  color: secondary,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatTile(
                                      label: 'Total',
                                      value: '${_offers.length}',
                                      icon: HugeIcons.strokeRoundedWork,
                                      isDarkMode: isDarkMode,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _StatTile(
                                      label: 'Open',
                                      value: '$_openCount',
                                      icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                                      isDarkMode: isDarkMode,
                                      accent: AppColors.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _StatTile(
                                      label: 'Interested',
                                      value: '$_totalInterested',
                                      icon: HugeIcons.strokeRoundedFavourite,
                                      isDarkMode: isDarkMode,
                                      accent: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _FilterChip(
                                      label: 'All',
                                      count: _countForFilter('All'),
                                      selected: _selectedFilter == 'All',
                                      isDarkMode: isDarkMode,
                                      onTap: () => setState(
                                        () => _selectedFilter = 'All',
                                      ),
                                    ),
                                    _FilterChip(
                                      label: 'Open',
                                      count: _openCount,
                                      selected: _selectedFilter == 'Open',
                                      isDarkMode: isDarkMode,
                                      onTap: () => setState(
                                        () => _selectedFilter = 'Open',
                                      ),
                                    ),
                                    _FilterChip(
                                      label: 'Closed',
                                      count: _closedCount,
                                      selected: _selectedFilter == 'Closed',
                                      isDarkMode: isDarkMode,
                                      onTap: () => setState(
                                        () => _selectedFilter = 'Closed',
                                      ),
                                    ),
                                    _FilterChip(
                                      label: 'Archived',
                                      count: _archivedCount,
                                      selected: _selectedFilter == 'Archived',
                                      isDarkMode: isDarkMode,
                                      onTap: () => setState(
                                        () => _selectedFilter = 'Archived',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      if (_filteredOffers.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyFilterState(
                            filter: _selectedFilter,
                            isDarkMode: isDarkMode,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final offer = _filteredOffers[index];

                                return MyOfferCard(
                                  offer: offer,
                                  isDarkMode: isDarkMode,
                                  isBusy: _isMutating,
                                  onTap: () => _openOfferDetails(offer),
                                  onStatusChanged: (status) {
                                    _updateOfferStatus(
                                      offer: offer,
                                      status: status,
                                    );
                                  },
                                  onDelete: () => _confirmDeleteOffer(offer),
                                );
                              },
                              childCount: _filteredOffers.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final dynamic icon;
  final bool isDarkMode;
  final Color? accent;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDarkMode,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDarkMode ? const Color(0xFF161616) : Colors.white;
    final primary = isDarkMode ? Colors.white : Colors.black;
    final iconColor = accent ?? primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, color: iconColor, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent
                : (isDarkMode
                    ? const Color(0xFF161616)
                    : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : (isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : (isDarkMode ? Colors.white : Colors.black),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : (isDarkMode
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : (isDarkMode
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black.withValues(alpha: 0.55)),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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

class _EmptyFilterState extends StatelessWidget {
  final String filter;
  final bool isDarkMode;

  const _EmptyFilterState({
    required this.filter,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDarkMode ? Colors.white : Colors.black;
    final secondary = isDarkMode
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedWork,
                color: AppColors.accent,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              filter == 'All' ? 'No offers yet' : 'No $filter offers',
              style: TextStyle(
                color: primary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filter == 'All'
                  ? 'Create an offer from the + tab to get started.'
                  : 'Try another filter to see your offers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondary, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final bool isDarkMode;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.isDarkMode,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDarkMode ? Colors.white : Colors.black;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: primary, height: 1.45),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
