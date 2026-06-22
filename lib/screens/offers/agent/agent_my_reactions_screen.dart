import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/agent_my_reaction_model.dart';
import '../../../services/agent_reactions_realtime.dart';
import '../../../services/interaction_service.dart';
import '../../../services/tab_auto_refresh.dart';
import 'agent_my_reaction_detail_screen.dart';

class AgentMyReactionsScreen extends StatefulWidget {
  final bool isTabActive;

  const AgentMyReactionsScreen({
    super.key,
    this.isTabActive = true,
  });

  @override
  State<AgentMyReactionsScreen> createState() => _AgentMyReactionsScreenState();
}

class _AgentMyReactionsScreenState extends State<AgentMyReactionsScreen> {
  static const List<String> _filters = [
    'All',
    'Pending',
    'Accepted',
    'Rejected',
  ];

  String _filter = 'All';
  bool _isLoading = true;
  String? _errorMessage;
  List<AgentMyReactionModel> _items = [];

  late final TabAutoRefresh _autoRefresh;

  @override
  void initState() {
    super.initState();
    AgentReactionsRealtime.instance.ensureStarted();
    _autoRefresh = TabAutoRefresh(
      onRefresh: ({showLoader = true}) => _load(showLoader: showLoader),
      isTabActive: () => widget.isTabActive,
      pollInterval: const Duration(seconds: 12),
    );
    _autoRefresh.attach();
    if (widget.isTabActive) {
      _load();
    }
  }

  @override
  void dispose() {
    _autoRefresh.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AgentMyReactionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isTabActive && !oldWidget.isTabActive) {
      _autoRefresh.onTabBecameActive();
    }
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final list = await InteractionService.fetchMyOfferReactions();
      if (!mounted) return;

      setState(() {
        _items = list;
        _errorMessage = null;
      });
    } on InteractionServiceException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load your reactions. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<AgentMyReactionModel> get _visible {
    switch (_filter) {
      case 'Pending':
        return _items.where((e) => e.isPending).toList();
      case 'Accepted':
        return _items.where((e) => e.isAccepted).toList();
      case 'Rejected':
        return _items.where((e) => e.isRejected).toList();
      default:
        return _items;
    }
  }

  String _statusChipLabel(AgentMyReactionModel r) {
    if (!r.react) return 'Rejected';
    if (r.isPending) return 'Pending';
    if (r.isAccepted) return 'Matched';
    return 'Declined';
  }

  Color _statusAccent(AgentMyReactionModel r) {
    if (!r.react) return const Color(0xFFEF4444);
    if (r.isPending) return AppColors.accent;
    if (r.isAccepted) return AppColors.accent;
    return const Color(0xFFEF4444);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final local = d.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  void _openReactionDetail(AgentMyReactionModel reaction) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AgentMyReactionDetailScreen(reaction: reaction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF151515) : const Color(0xFFF5F5F5);
    final softBorder =
        isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.68)
        : Colors.black.withValues(alpha: 0.62);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
        ),
      );
    }

    if (_errorMessage != null && _items.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load reactions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
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
                    onPressed: () => _load(),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final visible = _visible;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'My Reactions',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final label = _filters[index];
                  final selected = _filter == label;

                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _filter = label;
                      });
                    },
                    selectedColor: isDarkMode
                        ? Colors.white.withValues(alpha: 0.16)
                        : Colors.black.withValues(alpha: 0.08),
                    labelStyle: TextStyle(
                      color: selected
                          ? primaryTextColor
                          : secondaryTextColor,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: selected ? softBorder : softBorder,
                    ),
                    backgroundColor: cardColor,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator(
                color: isDarkMode ? Colors.white : Colors.black,
                onRefresh: () => _load(showLoader: false),
                child: visible.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.45,
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _items.isEmpty
                                          ? 'No reactions yet'
                                          : 'Nothing in this filter',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: primaryTextColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _items.isEmpty
                                          ? 'When you like or reject offers, your history will show up here.'
                                          : 'Try another filter or pull to refresh.',
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
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: visible.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final r = visible[index];
                          final accent = _statusAccent(r);

                          return Material(
                            color: cardColor,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                              side: BorderSide(color: softBorder),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: () => _openReactionDetail(r),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.offerTitle.isEmpty
                                            ? 'Offer #${r.offerId}'
                                            : r.offerTitle,
                                        style: TextStyle(
                                          color: primaryTextColor,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.18),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        _statusChipLabel(r),
                                        style: TextStyle(
                                          color: accent,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  r.outcomeLabel,
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                                if (r.react &&
                                    r.proposedPriceDisplay.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Proposed: ${r.proposedPriceDisplay}',
                                    style: TextStyle(
                                      color: primaryTextColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                if (r.message.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    r.message,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 13,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Text(
                                  _formatDate(r.createdAt),
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
