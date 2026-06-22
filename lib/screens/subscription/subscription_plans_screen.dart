import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:provider/provider.dart';

import '../../conf/theme_provider.dart';
import '../../models/subscription_model.dart';
import '../../models/subscription_plan_model.dart';
import '../../services/checkout_launcher.dart';
import '../../services/subscription_service.dart';
import '../offers/client/widgets/client_home_theme.dart';
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
  int? _submittingPlanId;
  bool _isOpeningPortal = false;
  String? _errorMessage;
  List<SubscriptionPlanModel> _plans = [];
  MySubscriptionModel? _subscription;

  bool get _isCheckoutBusy => _submittingPlanId != null || _isOpeningPortal;

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

  Future<void> _activateSubscriptionAfterCheckout(String? sessionId) async {
    try {
      final trimmed = sessionId?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        await SubscriptionService.confirmCheckoutSession(
          sessionId: trimmed,
        );
      } else {
        await SubscriptionService.syncSubscription();
      }
    } catch (_) {
      try {
        await SubscriptionService.syncSubscription();
      } catch (_) {
        // Plans screen will refresh on next visit.
      }
    }

    if (!mounted) return;
    await _loadData();
  }

  Future<void> _promptBrowserCheckoutComplete({String? sessionId}) async {
    if (!mounted) return;

    final syncNow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish in browser'),
        content: const Text(
          'Complete payment in Chrome (or your default browser), then return '
          'here and tap Sync to activate your subscription.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sync now'),
          ),
        ],
      ),
    );

    if (syncNow == true) {
      await _activateSubscriptionAfterCheckout(sessionId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription status updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _startCheckout(SubscriptionPlanModel plan) async {
    setState(() => _submittingPlanId = plan.id);

    try {
      final checkout = await SubscriptionService.createCheckoutSession(
        planId: plan.id,
      );
      final checkoutUrl = checkout.checkoutUrl;
      final checkoutSessionId = checkout.sessionId;

      if (!mounted) return;

      final stripeReachable = await CheckoutLauncher.canReachStripeCheckout();

      if (!mounted) return;

      SubscriptionCheckoutResult? checkoutResult;

      if (!stripeReachable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Opening checkout in your browser. This is normal on Android emulators.',
              ),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        }

        final opened =
            await CheckoutLauncher.openInExternalBrowser(checkoutUrl);
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not open browser. Check your internet connection and try again.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        await _promptBrowserCheckoutComplete(sessionId: checkoutSessionId);
        return;
      }

      checkoutResult = await Navigator.push<SubscriptionCheckoutResult>(
        context,
        MaterialPageRoute(
          builder: (_) => SubscriptionWebViewScreen(
            url: checkoutUrl,
            title: 'Checkout',
          ),
        ),
      );

      if (!mounted) return;

      if (checkoutResult?.openedInBrowser == true) {
        await _promptBrowserCheckoutComplete(sessionId: checkoutSessionId);
        return;
      }

      if (checkoutResult?.success == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        final sessionId =
            checkoutResult?.sessionId?.trim().isNotEmpty == true
                ? checkoutResult!.sessionId
                : checkoutSessionId;

        unawaited(_activateSubscriptionAfterCheckout(sessionId));
      }
    } on SubscriptionException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submittingPlanId = null);
      }
    }
  }

  Future<void> _openPortal() async {
    setState(() => _isOpeningPortal = true);

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
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningPortal = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = ClientHomeTheme.screenBackground(isDarkMode);
    final primary = ClientHomeTheme.primaryText(isDarkMode);
    final secondary = ClientHomeTheme.secondaryText(isDarkMode);
    final accent = AppColors.accent;

    final hasActive = _subscription?.hasActiveSubscription == true;
    final freeUsage = _subscription?.freeUsage;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AppBackButton(isDarkMode: isDarkMode),
        title: Text(
          'JobMatch Plus',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.navigation(isDarkMode)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accent))
          : _errorMessage != null
              ? _ErrorState(
                  message: _errorMessage!,
                  primary: primary,
                  onRetry: _loadData,
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: accent,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: [
                      _PlansHero(
                        isDarkMode: isDarkMode,
                        isAgent: widget.isAgent,
                      ),
                      const SizedBox(height: 20),
                      if (freeUsage != null) ...[
                        _StatusStrip(
                          isDarkMode: isDarkMode,
                          hasActive: hasActive,
                          title: hasActive ? 'Active plan' : 'Free usage',
                          value: hasActive
                              ? _subscription?.subscription?.plan?.name ??
                                  'JobMatch Plus'
                              : '${freeUsage.remainingFreeUsageCount} of ${freeUsage.freeUsageLimit} free ${widget.isAgent ? 'reactions' : 'offers'} left',
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (hasActive)
                        _ManageBillingButton(
                          isDarkMode: isDarkMode,
                          isLoading: _isOpeningPortal,
                          isBlocked: _isCheckoutBusy && !_isOpeningPortal,
                          onPressed: _openPortal,
                        ),
                      if (hasActive) const SizedBox(height: 22),
                      Text(
                        'Choose a plan',
                        style: TextStyle(
                          color: primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isAgent
                            ? 'Unlock more offer reactions and priority visibility with clients.'
                            : 'Post more offers and reach more agents with a paid plan.',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_plans.isEmpty)
                        Text(
                          'No plans available for your role right now.',
                          style: TextStyle(color: secondary),
                        )
                      else
                        ..._plans.map(
                          (plan) => _PlanCard(
                            plan: plan,
                            isDarkMode: isDarkMode,
                            isSubmitting: _submittingPlanId == plan.id,
                            isBlocked: _isCheckoutBusy &&
                                _submittingPlanId != plan.id,
                            onSubscribe: () => _startCheckout(plan),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _PlansHero extends StatelessWidget {
  final bool isDarkMode;
  final bool isAgent;

  const _PlansHero({
    required this.isDarkMode,
    required this.isAgent,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ClientHomeTheme.primaryText(isDarkMode);
    final secondary = ClientHomeTheme.secondaryText(isDarkMode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  const Color(0xFF1A2E1F),
                  const Color(0xFF121212),
                ]
              : [
                  AppColors.accentSurface,
                  Colors.white,
                ],
        ),
        border: Border.all(color: ClientHomeTheme.cardBorder(isDarkMode)),
        boxShadow: ClientHomeTheme.cardShadow(isDarkMode),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Premium',
              style: TextStyle(
                color: AppColors.accentReadable,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Grow faster with JobMatch Plus',
            style: TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAgent
                ? 'More reactions, more proposals, more visibility.'
                : 'More offers, better reach, priority placement.',
            style: TextStyle(
              color: secondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final bool isDarkMode;
  final bool hasActive;
  final String title;
  final String value;

  const _StatusStrip({
    required this.isDarkMode,
    required this.hasActive,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ClientHomeTheme.primaryText(isDarkMode);
    final secondary = ClientHomeTheme.secondaryText(isDarkMode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ClientHomeTheme.cardBackground(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientHomeTheme.cardBorder(isDarkMode)),
      ),
      child: Row(
        children: [
          Icon(
            hasActive ? Icons.verified_rounded : Icons.info_outline_rounded,
            size: 20,
            color: hasActive ? AppColors.accent : secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: primary,
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

class _ManageBillingButton extends StatelessWidget {
  final bool isDarkMode;
  final bool isLoading;
  final bool isBlocked;
  final VoidCallback onPressed;

  const _ManageBillingButton({
    required this.isDarkMode,
    required this.isLoading,
    required this.isBlocked,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ClientHomeTheme.primaryText(isDarkMode);

    return Opacity(
      opacity: isBlocked ? 0.55 : 1,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: (isLoading || isBlocked) ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: BorderSide(color: ClientHomeTheme.cardBorder(isDarkMode)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primary,
                  ),
                )
              : const Text(
                  'Manage billing',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final bool isDarkMode;
  final bool isSubmitting;
  final bool isBlocked;
  final VoidCallback onSubscribe;

  const _PlanCard({
    required this.plan,
    required this.isDarkMode,
    required this.isSubmitting,
    required this.isBlocked,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ClientHomeTheme.primaryText(isDarkMode);
    final secondary = ClientHomeTheme.secondaryText(isDarkMode);
    final accent = AppColors.accent;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ClientHomeTheme.cardBackground(isDarkMode),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ClientHomeTheme.cardBorder(isDarkMode)),
        boxShadow: ClientHomeTheme.cardShadow(isDarkMode),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    color: primary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (plan.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    plan.description,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.price.toStringAsFixed(0),
                      style: TextStyle(
                        color: primary,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'TND / ${plan.periodLabel}',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (plan.usageLimit > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${plan.usageLimit} uses included',
                    style: TextStyle(
                      color: ClientHomeTheme.tertiaryText(isDarkMode),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (plan.features.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...plan.features.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feature,
                              style: TextStyle(
                                color: secondary,
                                fontSize: 13.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _SubscribeButton(
                  isSubmitting: isSubmitting,
                  isBlocked: isBlocked,
                  onPressed: onSubscribe,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One plan loads at a time; other buttons stay visually active (not greyed out).
class _SubscribeButton extends StatelessWidget {
  final bool isSubmitting;
  final bool isBlocked;
  final VoidCallback onPressed;

  const _SubscribeButton({
    required this.isSubmitting,
    required this.isBlocked,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.accent;

    final canTap = !isSubmitting && !isBlocked;

    return Opacity(
      opacity: isBlocked ? 0.45 : 1,
      child: Material(
        color: accent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: canTap ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            child: isSubmitting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Opening checkout…',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Subscribe',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
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
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
