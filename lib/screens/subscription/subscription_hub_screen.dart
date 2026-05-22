import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../conf/app_colors.dart';
import '../../conf/theme_provider.dart';
import '../../models/subscription_history_item.dart';
import '../../models/subscription_model.dart';
import '../../models/subscription_plan_model.dart';
import '../../services/subscription_service.dart';
import 'subscription_plans_screen.dart';
import 'subscription_webview_screen.dart';

String formatSubscriptionDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final local = date.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${months[local.month - 1]} ${local.day}, ${local.year} · $hour:$minute';
}

class SubscriptionHubScreen extends StatefulWidget {
  final bool isAgent;

  const SubscriptionHubScreen({
    super.key,
    required this.isAgent,
  });

  @override
  State<SubscriptionHubScreen> createState() => _SubscriptionHubScreenState();
}

class _SubscriptionHubScreenState extends State<SubscriptionHubScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  MySubscriptionModel? _subscription;
  List<SubscriptionPlanModel> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        SubscriptionService.fetchMySubscription(),
        SubscriptionService.fetchPlans(),
      ]);

      if (!mounted) return;

      setState(() {
        _subscription = results[0] as MySubscriptionModel;
        _plans = results[1] as List<SubscriptionPlanModel>;
        _isLoading = false;
      });
    } on SubscriptionException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openPortal() async {
    setState(() => _isSubmitting = true);

    try {
      final portalUrl = await SubscriptionService.createPortalSession();

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionWebViewScreen(
            url: portalUrl,
            title: 'Billing & invoices',
          ),
        ),
      );

      if (!mounted) return;
      await _loadData();
    } on SubscriptionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openPlans() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionPlansScreen(isAgent: widget.isAgent),
      ),
    ).then((_) {
      if (mounted) _loadData();
    });
  }

  List<SubscriptionHistoryItem> _buildHistory(MySubscriptionModel data) {
    final items = <SubscriptionHistoryItem>[];
    final sub = data.subscription;
    final free = data.freeUsage;
    final usageLabel =
        widget.isAgent ? 'offer reactions' : 'offer posts';

    items.add(
      SubscriptionHistoryItem(
        type: SubscriptionHistoryType.freeTier,
        title: 'Free tier usage',
        subtitle:
            '${free.usedFreeUsageCount} of ${free.freeUsageLimit} $usageLabel used · ${free.remainingFreeUsageCount} remaining',
        date: sub?.updatedAt ?? sub?.createdAt,
        isHighlight: data.isOnFreePlan,
      ),
    );

    if (sub == null) {
      return items.reversed.toList();
    }

    if (sub.createdAt != null) {
      items.add(
        SubscriptionHistoryItem(
          type: SubscriptionHistoryType.subscriptionCreated,
          title: 'Subscription record created',
          subtitle: sub.plan?.name ?? 'JobMatch Plus',
          date: sub.createdAt,
        ),
      );
    }

    final status = sub.status.toUpperCase();

    if (status == 'INCOMPLETE') {
      items.add(
        SubscriptionHistoryItem(
          type: SubscriptionHistoryType.checkoutStarted,
          title: 'Checkout started',
          subtitle: 'Complete payment to activate your plan',
          date: sub.updatedAt ?? sub.createdAt,
        ),
      );
    }

    if (sub.startDate != null &&
        (status == 'ACTIVE' ||
            status == 'CANCELED' ||
            status == 'EXPIRED')) {
      items.add(
        SubscriptionHistoryItem(
          type: SubscriptionHistoryType.activated,
          title: 'Plan activated',
          subtitle: sub.plan?.name ?? 'Subscription',
          date: sub.startDate,
          isHighlight: sub.hasActiveSubscription,
        ),
      );
    }

    if (sub.usageLimit > 0) {
      items.add(
        SubscriptionHistoryItem(
          type: SubscriptionHistoryType.usageConsumed,
          title: 'Subscription usage',
          subtitle:
              '${sub.usedUsageCount} of ${sub.usageLimit} uses consumed · ${sub.remainingUsageCount} left',
          date: sub.updatedAt,
          isHighlight: data.hasActiveSubscription && sub.usageLimit > 0,
        ),
      );
    }

    if (sub.endDate != null) {
      items.add(
        SubscriptionHistoryItem(
          type: SubscriptionHistoryType.periodEnd,
          title: sub.cancelAtPeriodEnd
              ? 'Ends at period close'
              : 'Current period ends',
          subtitle: _formatDate(sub.endDate!),
          date: sub.endDate,
        ),
      );
    }

    if (status == 'CANCELED') {
      items.add(
        SubscriptionHistoryItem(
          type: SubscriptionHistoryType.canceled,
          title: 'Subscription canceled',
          subtitle: sub.cancelAtPeriodEnd
              ? 'Access until ${_formatDate(sub.endDate)}'
              : 'Plan is no longer active',
          date: sub.updatedAt,
        ),
      );
    }

    if (status == 'EXPIRED') {
      items.add(
        SubscriptionHistoryItem(
          type: SubscriptionHistoryType.expired,
          title: 'Subscription expired',
          subtitle: 'Renew to continue with premium limits',
          date: sub.endDate ?? sub.updatedAt,
        ),
      );
    }

    if (status == 'PAST_DUE' || status == 'UNPAID') {
      items.add(
        SubscriptionHistoryItem(
          type: SubscriptionHistoryType.updated,
          title: sub.statusLabel,
          subtitle: 'Update your payment method in billing',
          date: sub.updatedAt,
          isHighlight: true,
        ),
      );
    }

    if (sub.updatedAt != null && items.length > 1) {
      items.add(
        SubscriptionHistoryItem(
          type: SubscriptionHistoryType.updated,
          title: 'Last update',
          subtitle: 'Status: ${sub.statusLabel}',
          date: sub.updatedAt,
        ),
      );
    }

    items.sort((a, b) {
      final ad = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    return items;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return formatSubscriptionDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor =
        isDarkMode ? const Color(0xFF0D0D0D) : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF171717) : const Color(0xFFF0F0F0);
    final primary = isDarkMode ? Colors.white : Colors.black;
    final secondary = isDarkMode
        ? Colors.white.withValues(alpha: 0.62)
        : Colors.black.withValues(alpha: 0.58);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Subscription',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: IconThemeData(color: primary),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              color: primary,
              size: 20,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : _errorMessage != null
              ? _ErrorBody(
                  message: _errorMessage!,
                  primary: primary,
                  onRetry: _loadData,
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.accent,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      _OverviewCard(
                        data: _subscription!,
                        isAgent: widget.isAgent,
                        cardColor: cardColor,
                        primary: primary,
                        secondary: secondary,
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(title: 'Usage', color: primary),
                      const SizedBox(height: 10),
                      _UsageCard(
                        data: _subscription!,
                        isAgent: widget.isAgent,
                        cardColor: cardColor,
                        primary: primary,
                        secondary: secondary,
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(title: 'History', color: primary),
                      const SizedBox(height: 10),
                      _HistoryTimeline(
                        items: _buildHistory(_subscription!),
                        cardColor: cardColor,
                        primary: primary,
                        secondary: secondary,
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(title: 'Actions', color: primary),
                      const SizedBox(height: 10),
                      _ActionTile(
                        icon: HugeIcons.strokeRoundedWallet02,
                        title: 'View plans',
                        subtitle: '${_plans.length} plans available',
                        cardColor: cardColor,
                        primary: primary,
                        secondary: secondary,
                        onTap: _openPlans,
                      ),
                      const SizedBox(height: 10),
                      if (_subscription!.hasActiveSubscription)
                        _ActionTile(
                          icon: HugeIcons.strokeRoundedInvoice01,
                          title: 'Billing & invoices',
                          subtitle: 'Payment history via Stripe portal',
                          cardColor: cardColor,
                          primary: primary,
                          secondary: secondary,
                          onTap: _isSubmitting ? null : _openPortal,
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: color.withValues(alpha: 0.45),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final MySubscriptionModel data;
  final bool isAgent;
  final Color cardColor;
  final Color primary;
  final Color secondary;

  const _OverviewCard({
    required this.data,
    required this.isAgent,
    required this.cardColor,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final hasActive = data.hasActiveSubscription;
    final planName =
        data.subscription?.plan?.name ?? 'JobMatch Free';
    final status = hasActive
        ? data.subscription?.statusLabel ?? 'Active'
        : 'Free tier';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedWallet02,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName,
                      style: TextStyle(
                        color: primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAgent
                          ? 'Agent subscription'
                          : 'Client subscription',
                      style: TextStyle(color: secondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (hasActive ? AppColors.accent : secondary)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: hasActive ? AppColors.accent : secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.activeUsageSource == 'SUBSCRIPTION'
                ? 'You are on a paid plan. Usage is drawn from your subscription first, then free tier.'
                : 'You are on the free tier. Upgrade for more ${isAgent ? 'reactions' : 'offers'}.',
            style: TextStyle(color: secondary, height: 1.45, fontSize: 13),
          ),
          if (data.subscription?.cancelAtPeriodEnd == true) ...[
            const SizedBox(height: 10),
            Text(
              'Cancellation scheduled at end of billing period.',
              style: TextStyle(
                color: Colors.orange.shade400,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final MySubscriptionModel data;
  final bool isAgent;
  final Color cardColor;
  final Color primary;
  final Color secondary;

  const _UsageCard({
    required this.data,
    required this.isAgent,
    required this.cardColor,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final free = data.freeUsage;
    final sub = data.subscription;
    final usageLabel = isAgent ? 'reactions' : 'offers';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _UsageRow(
            label: 'Free $usageLabel',
            used: free.usedFreeUsageCount,
            total: free.freeUsageLimit,
            primary: primary,
            secondary: secondary,
          ),
          if (sub != null && sub.usageLimit > 0) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: secondary.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            _UsageRow(
              label: 'Plan usage',
              used: sub.usedUsageCount,
              total: sub.usageLimit,
              primary: primary,
              secondary: secondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  final String label;
  final int used;
  final int total;
  final Color primary;
  final Color secondary;

  const _UsageRow({
    required this.label,
    required this.used,
    required this.total,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 1 : total;
    final progress = (used / safeTotal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(
              '$used / $total',
              style: TextStyle(
                color: secondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: secondary.withValues(alpha: 0.12),
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  final List<SubscriptionHistoryItem> items;
  final Color cardColor;
  final Color primary;
  final Color secondary;

  const _HistoryTimeline({
    required this.items,
    required this.cardColor,
    required this.primary,
    required this.secondary,
  });

  IconData _iconFor(SubscriptionHistoryType type) {
    switch (type) {
      case SubscriptionHistoryType.freeTier:
        return Icons.card_giftcard_rounded;
      case SubscriptionHistoryType.activated:
        return Icons.verified_rounded;
      case SubscriptionHistoryType.checkoutStarted:
        return Icons.shopping_cart_checkout_rounded;
      case SubscriptionHistoryType.canceled:
      case SubscriptionHistoryType.expired:
        return Icons.cancel_rounded;
      case SubscriptionHistoryType.periodEnd:
        return Icons.event_rounded;
      case SubscriptionHistoryType.usageConsumed:
        return Icons.pie_chart_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'No subscription activity yet.',
          style: TextStyle(color: secondary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _HistoryRow(
              item: items[i],
              icon: _iconFor(items[i].type),
              isLast: i == items.length - 1,
              primary: primary,
              secondary: secondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final SubscriptionHistoryItem item;
  final IconData icon;
  final bool isLast;
  final Color primary;
  final Color secondary;

  const _HistoryRow({
    required this.item,
    required this.icon,
    required this.isLast,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        item.date != null ? formatSubscriptionDate(item.date!) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (item.isHighlight ? AppColors.accent : secondary)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: item.isHighlight ? AppColors.accent : secondary,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 36,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: secondary.withValues(alpha: 0.15),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: secondary.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String subtitle;
  final Color cardColor;
  final Color primary;
  final Color secondary;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cardColor,
    required this.primary,
    required this.secondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              HugeIcon(icon: icon, color: AppColors.accent, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: secondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: secondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final Color primary;
  final VoidCallback onRetry;

  const _ErrorBody({
    required this.message,
    required this.primary,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
