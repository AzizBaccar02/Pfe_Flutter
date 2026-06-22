import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Opens Stripe Checkout when the in-app WebView cannot reach the network
/// (common on Android emulators: `ERR_NAME_NOT_RESOLVED`).
class CheckoutLauncher {
  static const _probeTimeout = Duration(seconds: 4);

  /// Returns true when `checkout.stripe.com` is reachable from this device.
  static Future<bool> canReachStripeCheckout() async {
    try {
      await http
          .head(Uri.parse('https://checkout.stripe.com/'))
          .timeout(_probeTimeout);
      return true;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } on http.ClientException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openInExternalBrowser(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) return false;

    if (!await canLaunchUrl(uri)) return false;

    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  static String friendlyLoadError(String? raw) {
    final lower = (raw ?? '').toLowerCase();

    if (lower.contains('err_name_not_resolved') ||
        lower.contains('name_not_resolved') ||
        lower.contains('hostname could not be found')) {
      return 'Could not reach Stripe checkout (DNS/network issue). '
          'If you are on an Android emulator, tap "Open in browser" below — '
          'Chrome often works when in-app checkout fails.';
    }

    if (lower.contains('err_connection_timed_out') ||
        lower.contains('timed out')) {
      return 'Checkout timed out. Check your internet connection and try again.';
    }

    if (lower.contains('err_internet_disconnected') ||
        lower.contains('network is unreachable')) {
      return 'No internet connection. Connect to Wi‑Fi or mobile data, then retry.';
    }

    if (raw != null && raw.trim().isNotEmpty) {
      return raw.trim();
    }

    return 'Could not load checkout. Check your connection and try again.';
  }
}
