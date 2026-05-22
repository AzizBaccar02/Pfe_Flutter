import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();

            if (url.contains('/api/subscriptions/success')) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }

            if (url.contains('/api/subscriptions/cancel')) {
              Navigator.pop(context, false);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF0D0D0D) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}
