import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/client_offer_model.dart';
import '../../../models/interested_agent_model.dart';
import '../../../conf/app_providers.dart';
import '../../../services/client_interaction_realtime.dart';
import '../../../services/interaction_service.dart';
import '../../../services/tab_auto_refresh.dart';
import '../../../services/notification_realtime_hub.dart';
import '../../../services/offer_service.dart';
import '../../../services/profile_service.dart';
import 'widgets/client_home_featured_card.dart';
import 'widgets/client_home_interested_agent_row.dart';
import 'widgets/client_home_offer_row.dart';
import 'widgets/client_home_search_bar.dart';
import 'widgets/client_home_section_header.dart';
import 'widgets/client_home_stats_strip.dart';
import 'widgets/client_home_theme.dart';

class ClientHomeScreen extends StatefulWidget {
  final VoidCallback onCreateOfferTap;
  final VoidCallback onMyOffersTap;
  final VoidCallback onInterestedTap;
  final VoidCallback onChatsTap;
  final ScrollController? scrollController;
  final bool isTabActive;

  const ClientHomeScreen({
    super.key,
    required this.onCreateOfferTap,
    required this.onMyOffersTap,
    required this.onInterestedTap,
    required this.onChatsTap,
    this.scrollController,
    this.isTabActive = true,
  });

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<ClientOfferModel> _offers = [];
  List<InterestedAgentModel> _pendingAgents = [];
  List<InterestedAgentModel> _matchedAgents = [];
  String _clientName = 'Client';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final TabAutoRefresh _autoRefresh;

  @override
  void initState() {
    super.initState();
    ClientInteractionRealtime.instance.ensureStarted();
    _autoRefresh = TabAutoRefresh(
      onRefresh: ({showLoader = true}) => _loadHomeData(showLoader: showLoader),
      isTabActive: () => widget.isTabActive,
      pollInterval: const Duration(seconds: 15),
    );
    _autoRefresh.attach();
    if (widget.isTabActive) {
      _loadHomeData();
    }
  }

  @override
  void dispose() {
    _autoRefresh.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ClientHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isTabActive && !oldWidget.isTabActive) {
      _autoRefresh.onTabBecameActive();
    }
  }

  String get _firstName {
    final parts = _clientName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : 'there';
  }

  List<ClientOfferModel> get _filteredOffers {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _offers;

    return _offers.where((offer) {
      return offer.title.toLowerCase().contains(q) ||
          offer.description.toLowerCase().contains(q) ||
          offer.category.toLowerCase().contains(q) ||
          offer.city.toLowerCase().contains(q);
    }).toList();
  }

  List<ClientOfferModel> get _featuredOffers {
    final base = _filteredOffers;
    if (base.isEmpty) return const [];

    final open = base.where((o) => o.status == OfferStatus.open).toList();
    final source = open.isNotEmpty ? open : base;
    return source.take(6).toList();
  }

  List<ClientOfferModel> get _listOffers {
    return _filteredOffers.take(8).toList();
  }

  Future<void> _loadHomeData({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final profileProvider = AppProviders.profile;

    try {
      final results = await Future.wait([
        OfferService.fetchMyOffers(
          force: !showLoader,
        ),
        InteractionService.fetchInterestedAgents(),
        _agentsFromInterestNotifications(),
        InteractionService.fetchMatchedInterestedAgents(),
      ]);

      final offers = results[0] as List<ClientOfferModel>;
      final fromApi = results[1] as List<InterestedAgentModel>;
      final fromNotifications = results[2] as List<InterestedAgentModel>;
      final matchedAgents = results[3] as List<InterestedAgentModel>;

      final trustedReactionIds = fromApi
          .map((agent) => agent.reactionId)
          .where((id) => id > 0)
          .toSet();

      var pendingAgents = _mergePendingAgents(fromApi, fromNotifications);
      pendingAgents = await InteractionService.filterUnresolvedInterestedAgents(
        pendingAgents,
        trustedReactionIds: trustedReactionIds,
      );

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

        final remoteUrl = ProfileService.resolveMediaUrl(profile.photoUrl);
        if (remoteUrl != null && remoteUrl.isNotEmpty) {
          profileProvider.setRemoteProfileImageUrl(remoteUrl);
        }
      } catch (_) {
        // Keep fallback name if profile loading fails.
      }

      if (!mounted) return;

      setState(() {
        _offers = offers;
        _pendingAgents = pendingAgents;
        _matchedAgents = matchedAgents;
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
      if (mounted) {
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

  List<InterestedAgentModel> get _homePendingAgents {
    return _pendingAgents
        .where((agent) => agent.isActionable && agent.isPendingForDeck)
        .take(5)
        .toList();
  }

  List<InterestedAgentModel> get _homeMatchedAgents {
    if (_homePendingAgents.isNotEmpty) return const [];

    return _matchedAgents
        .where((agent) => agent.isActionable)
        .take(5)
        .toList();
  }

  int get _offerInterestTotal {
    return _offers.fold<int>(
      0,
      (total, offer) => total + offer.interestedAgentsCount,
    );
  }

  String get _interestedAgentsEmptyMessage {
    if (_offerInterestTotal > 0 || _matchedAgents.isNotEmpty) {
      return 'You\'re all caught up. Matched agents are in Messages — tap Interested for details.';
    }
    return 'Agents who react to your offers will show up here.';
  }

  int get _totalInterestedAgents {
    final pending = _pendingAgents
        .where((agent) => agent.isActionable && agent.isPendingForDeck)
        .length;
    if (pending > 0) return pending;

    return _offers.fold<int>(
      0,
      (total, offer) => total + offer.interestedAgentsCount,
    );
  }

  Future<List<InterestedAgentModel>> _agentsFromInterestNotifications() async {
    try {
      final items = await NotificationRealtimeHub.instance.fetchNotifications();
      final agents = <InterestedAgentModel>[];

      for (final notification in items) {
        if (!notification.isAgentInterestNotification) continue;

        final stub = InterestedAgentModel.fromNotification(notification);
        if (stub.offerId <= 0) continue;
        if (stub.id <= 0 && stub.reactionId <= 0) continue;

        agents.add(stub);
      }

      return agents;
    } catch (_) {
      return const [];
    }
  }

  List<InterestedAgentModel> _mergePendingAgents(
    List<InterestedAgentModel> primary,
    List<InterestedAgentModel> secondary,
  ) {
    final merged = <String, InterestedAgentModel>{};

    for (final agent in [...primary, ...secondary]) {
      if (!agent.isActionable || !agent.isPendingForDeck) continue;

      final key = agent.reactionId > 0
          ? 'reaction:${agent.reactionId}'
          : 'agent:${agent.id}:offer:${agent.offerId}';
      final existing = merged[key];
      merged[key] = existing == null ? agent : existing.mergeWith(agent);
    }

    final list = merged.values.toList()
      ..sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;
        if (ad != null && bd != null) return bd.compareTo(ad);
        if (ad != null) return -1;
        if (bd != null) return 1;
        return b.reactionId.compareTo(a.reactionId);
      });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = ClientHomeTheme.screenBackground(isDarkMode);
    final primaryText = ClientHomeTheme.primaryText(isDarkMode);
    final secondaryText = ClientHomeTheme.secondaryText(isDarkMode);

    return Container(
      color: backgroundColor,
      child: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => _loadHomeData(showLoader: false),
        child: SingleChildScrollView(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $_firstName!',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Let's grow your offers",
                style: TextStyle(
                  color: primaryText,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 20),
              ClientHomeSearchBar(
                isDarkMode: isDarkMode,
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 22),
              if (_isLoading)
                _HomeLoadingState(isDarkMode: isDarkMode)
              else ...[
                if (_errorMessage != null) ...[
                  _HomeErrorCard(
                    message: _errorMessage!,
                    isDarkMode: isDarkMode,
                    onRetry: () => _loadHomeData(),
                  ),
                  const SizedBox(height: 18),
                ],
                ClientHomeStatsStrip(
                  isDarkMode: isDarkMode,
                  items: [
                    ClientHomeStatItem(
                      label: 'Total',
                      value: '$_totalOffers',
                    ),
                    ClientHomeStatItem(
                      label: 'Open',
                      value: '$_openOffers',
                    ),
                    ClientHomeStatItem(
                      label: 'Interested',
                      value: '$_totalInterestedAgents',
                    ),
                    ClientHomeStatItem(
                      label: 'Closed',
                      value: '$_closedOffers',
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                ClientHomeSectionHeader(
                  title: 'Your offers',
                  actionText: 'See all',
                  onActionTap: widget.onMyOffersTap,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 14),
                if (_featuredOffers.isEmpty)
                  _HomeEmptyPanel(
                    isDarkMode: isDarkMode,
                    message: _searchQuery.isNotEmpty
                        ? 'No offers match your search.'
                        : 'Create your first offer to get started.',
                  )
                else
                  SizedBox(
                    height: 228,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      itemCount: _featuredOffers.length,
                      itemBuilder: (context, index) {
                        return ClientHomeFeaturedCard(
                          offer: _featuredOffers[index],
                          isDarkMode: isDarkMode,
                          onTap: widget.onMyOffersTap,
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 28),
                ClientHomeSectionHeader(
                  title: 'All offers',
                  actionText: 'See all',
                  onActionTap: widget.onMyOffersTap,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 6),
                if (_listOffers.isEmpty && _featuredOffers.isNotEmpty)
                  _HomeEmptyPanel(
                    isDarkMode: isDarkMode,
                    message: 'No other offers to show.',
                  )
                else if (_listOffers.isNotEmpty)
                  ..._listOffers.map(
                    (offer) => ClientHomeOfferRow(
                      offer: offer,
                      isDarkMode: isDarkMode,
                      onTap: widget.onMyOffersTap,
                    ),
                  ),
                const SizedBox(height: 20),
                ClientHomeSectionHeader(
                  title: 'Interested agents',
                  actionText: 'See all',
                  onActionTap: widget.onInterestedTap,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 8),
                if (_homePendingAgents.isEmpty && _homeMatchedAgents.isEmpty)
                  _HomeEmptyPanel(
                    isDarkMode: isDarkMode,
                    message: _interestedAgentsEmptyMessage,
                    compact: true,
                    onTap: widget.onInterestedTap,
                  )
                else ...[
                  ..._homePendingAgents.map(
                    (agent) => ClientHomeInterestedAgentRow(
                      agent: agent,
                      isDarkMode: isDarkMode,
                      onTap: widget.onInterestedTap,
                    ),
                  ),
                  ..._homeMatchedAgents.map(
                    (agent) => ClientHomeInterestedAgentRow(
                      agent: agent,
                      isDarkMode: isDarkMode,
                      showAsMatched: true,
                      onTap: widget.onChatsTap,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeEmptyPanel extends StatelessWidget {
  final bool isDarkMode;
  final String message;
  final bool compact;
  final VoidCallback? onTap;

  const _HomeEmptyPanel({
    required this.isDarkMode,
    required this.message,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: compact ? 14 : 20,
          ),
          decoration: BoxDecoration(
            color: ClientHomeTheme.cardBackground(isDarkMode),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientHomeTheme.cardBorder(isDarkMode)),
          ),
          child: Text(
            message,
            style: TextStyle(
              color: ClientHomeTheme.secondaryText(isDarkMode),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeLoadingState extends StatelessWidget {
  final bool isDarkMode;

  const _HomeLoadingState({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: ClientHomeTheme.highlight(isDarkMode),
          ),
        ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientHomeTheme.cardBackground(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientHomeTheme.cardBorder(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Could not refresh',
            style: TextStyle(
              color: ClientHomeTheme.primaryText(isDarkMode),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: ClientHomeTheme.secondaryText(isDarkMode),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Try again',
              style: TextStyle(
                color: ClientHomeTheme.highlight(isDarkMode),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
