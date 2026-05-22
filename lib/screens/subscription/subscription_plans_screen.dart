import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../conf/theme_provider.dart';
import '../../models/subscription_model.dart';
import '../../models/subscription_plan_model.dart';
import '../../services/subscription_service.dart';
import 'subscription_webview_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  final bool isAgent;

  const SubscriptionPlansScreen({
    super.key,
    required this.isAgent,
  });

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<SubscriptionPlanModel> _plans = [];
  MySubscriptionModel? _subscription;

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
        SubscriptionService.fetchPlans(),
        SubscriptionService.fetchMySubscription(),
      ]);

      if (!mounted) return;

      setState(() {
        _plans = results[0] as List<SubscriptionPlanModel>;
        _subscription = results[1] as MySubscriptionModel;
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

  Future<void> _startCheckout(SubscriptionPlanModel plan) async {
    setState(() => _isSubmitting = true);

    try {
      final checkoutUrl = await SubscriptionService.createCheckoutSession(
        planId: plan.id,
      );

      if (!mounted) return;

      final success = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionWebViewScreen(
            url: checkoutUrl,
            title: 'Checkout',
          ),
        ),
      );

      if (!mounted) return;

      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription updated successfully')),
        );
        await _loadData();
      }
    } on SubscriptionException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
            title: 'Manage subscription',
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
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
    const accent = Color(0xFF6366F1);

    final hasActive = _subscription?.hasActiveSubscription == true;
    final freeUsage = _subscription?.freeUsage;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'JobMatch Plus',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: primary),
            )
          : _errorMessage != null
              ? _ErrorState(
                  message: _errorMessage!,
                  primary: primary,
                  onRetry: _loadData,
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: [
                      if (freeUsage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasActive ? 'Active plan' : 'Free usage',
                                style: TextStyle(
                                  color: secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hasActive
                                    ? _subscription?.subscription?.plan?.name ??
                                        'JobMatch Plus'
                                    : '${freeUsage.remainingFreeUsageCount} of ${freeUsage.freeUsageLimit} free ${widget.isAgent ? 'reactions' : 'offers'} left',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (hasActive)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : _openPortal,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primary,
                              side: BorderSide(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.15),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Manage billing',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      if (hasActive) const SizedBox(height: 20),
                      Text(
                        'Choose a plan',
                        style: TextStyle(
                          color: primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.isAgent
                            ? 'Unlock more offer reactions and priority visibility.'
                            : 'Post more offers and get featured listings.',
                        style: TextStyle(
                          color: secondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_plans.isEmpty)
                        Text(
                          'No plans available for your role right now.',
                          style: TextStyle(color: secondary),
                        )
                      else
                        ..._plans.map(
                          (plan) => _PlanCard(
                            plan: plan,
                            cardColor: cardColor,
                            primary: primary,
                            secondary: secondary,
                            accent: accent,
                            isSubmitting: _isSubmitting,
                            onSubscribe: () => _startCheckout(plan),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final Color cardColor;
  final Color primary;
  final Color secondary;
  final Color accent;
  final bool isSubmitting;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.cardColor,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.isSubmitting,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.name,
            style: TextStyle(
              color: primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              plan.description,
              style: TextStyle(color: secondary, height: 1.4),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            '${plan.price.toStringAsFixed(0)} TND / ${plan.periodLabel}',
            style: TextStyle(
              color: primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (plan.usageLimit > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${plan.usageLimit} uses included',
              style: TextStyle(color: secondary, fontSize: 13),
            ),
          ],
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...plan.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_rounded, size: 18, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(color: secondary, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isSubmitting ? null : onSubscribe,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Subscribe',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Color primary;
  final VoidCallback onRetry;

  const _ErrorState({
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
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
