import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../services/checkout_launcher.dart';

class SubscriptionCheckoutResult {
  final bool success;
  final String? sessionId;
  final bool openedInBrowser;

  const SubscriptionCheckoutResult({
    required this.success,
    this.sessionId,
    this.openedInBrowser = false,
  });
}

class SubscriptionWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const SubscriptionWebViewScreen({
    super.key,
    required this.url,
    this.title = 'Subscription',
  });

  @override
  State<SubscriptionWebViewScreen> createState() =>
      _SubscriptionWebViewScreenState();
}

class _SubscriptionWebViewScreenState extends State<SubscriptionWebViewScreen> {
  static const _loadTimeout = Duration(seconds: 30);

  late final WebViewController _controller;
  Timer? _loadTimeoutTimer;

  bool _isInitialLoad = true;
  bool _showBlockingLoader = true;
  bool _showWebView = false;
  int _loadProgress = 0;
  String? _errorMessage;
  bool _checkoutHandled = false;
  bool _isOpeningBrowser = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _loadTimeoutTimer?.cancel();
    super.dispose();
  }

  void _initWebView() {
    final isDarkMode =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF0D0D0D) : Colors.white;

    _controller = WebViewController()
      ..setBackgroundColor(backgroundColor)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted || _checkoutHandled) return;

            setState(() {
              _loadProgress = progress.clamp(0, 100);
              if (progress >= 12) {
                _showBlockingLoader = false;
                _showWebView = true;
              }
            });
          },
          onPageStarted: (url) {
            if (!mounted || _checkoutHandled) return;

            if (_tryHandleCheckoutUrl(url)) return;

            _armLoadTimeout();

            if (_isInitialLoad) {
              setState(() {
                _showBlockingLoader = true;
                _showWebView = false;
                _loadProgress = 0;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (url) {
            if (!mounted || _checkoutHandled) return;

            _loadTimeoutTimer?.cancel();

            if (_tryHandleCheckoutUrl(url)) return;

            setState(() {
              _isInitialLoad = false;
              _showBlockingLoader = false;
              _showWebView = true;
              _loadProgress = 100;
              _errorMessage = null;
            });
          },
          onWebResourceError: (error) {
            if (!mounted || _checkoutHandled) return;
            if (error.isForMainFrame != true) return;

            _loadTimeoutTimer?.cancel();
            setState(() {
              _showBlockingLoader = false;
              _showWebView = false;
              _isInitialLoad = false;
              _errorMessage = CheckoutLauncher.friendlyLoadError(
                error.description,
              );
            });
          },
          onNavigationRequest: (request) {
            if (_tryHandleCheckoutUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _armLoadTimeout();
    unawaited(_controller.loadRequest(Uri.parse(widget.url)));
  }

  void _armLoadTimeout() {
    _loadTimeoutTimer?.cancel();
    _loadTimeoutTimer = Timer(_loadTimeout, () {
      if (!mounted || _checkoutHandled || !_showBlockingLoader) return;

      setState(() {
        _showBlockingLoader = false;
        _showWebView = false;
        _errorMessage =
            'Checkout is taking longer than expected. Check your internet, '
            'or open checkout in your browser instead.';
      });
    });
  }

  bool _tryHandleCheckoutUrl(String url) {
    if (_checkoutHandled) return true;

    final lower = url.toLowerCase();

    if (lower.contains('/api/subscriptions/success')) {
      _checkoutHandled = true;
      _loadTimeoutTimer?.cancel();

      final uri = Uri.tryParse(url);
      final sessionId = uri?.queryParameters['session_id'];

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pop(
          context,
          SubscriptionCheckoutResult(
            success: true,
            sessionId: sessionId,
          ),
        );
      });
      return true;
    }

    if (lower.contains('/api/subscriptions/cancel')) {
      _checkoutHandled = true;
      _loadTimeoutTimer?.cancel();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pop(
          context,
          const SubscriptionCheckoutResult(success: false),
        );
      });
      return true;
    }

    return false;
  }

  Future<void> _retryLoad() async {
    setState(() {
      _errorMessage = null;
      _showBlockingLoader = true;
      _showWebView = false;
      _isInitialLoad = true;
      _loadProgress = 0;
    });

    _armLoadTimeout();
    await _controller.loadRequest(Uri.parse(widget.url));
  }

  Future<void> _openInBrowser() async {
    if (_isOpeningBrowser) return;

    setState(() => _isOpeningBrowser = true);

    try {
      final opened = await CheckoutLauncher.openInExternalBrowser(widget.url);

      if (!mounted) return;

      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open a browser. Install Chrome or check your connection.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      Navigator.pop(
        context,
        const SubscriptionCheckoutResult(
          success: false,
          openedInBrowser: true,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpeningBrowser = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF0D0D0D) : Colors.white;
    final primary = isDarkMode ? Colors.white : Colors.black;
    final secondary = isDarkMode
        ? Colors.white.withValues(alpha: 0.62)
        : Colors.black.withValues(alpha: 0.58);

    final showTopProgress = _showWebView &&
        !_checkoutHandled &&
        !_showBlockingLoader &&
        _loadProgress < 100;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AppBackButton(isDarkMode: isDarkMode),
        title: Text(
          widget.title,
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.navigation(isDarkMode)),
        bottom: showTopProgress
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadProgress / 100,
                  minHeight: 3,
                  backgroundColor: isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  color: AppColors.accent,
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          if (_showWebView && _errorMessage == null)
            WebViewWidget(controller: _controller),
          if (_showBlockingLoader && _errorMessage == null)
            ColoredBox(
              color: backgroundColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primary),
                    const SizedBox(height: 16),
                    Text(
                      'Opening secure checkout…',
                      style: TextStyle(
                        color: secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_errorMessage != null)
            ColoredBox(
              color: backgroundColor,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 40,
                        color: secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _isOpeningBrowser ? null : _openInBrowser,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: _isOpeningBrowser
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Open in browser',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _retryLoad,
                        child: Text(
                          'Retry in app',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
