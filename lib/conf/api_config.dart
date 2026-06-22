import 'package:flutter/foundation.dart';

/// Backend host/port for HTTP and WebSocket calls.
///
/// **Android emulator:** uses [defaultAndroidHost] (`10.0.2.2` → your PC's localhost).
/// **Physical phone on Wi‑Fi:** set [physicalDeviceHost] to your PC's LAN IP
/// (e.g. `192.168.1.35`) or run:
/// `flutter run --dart-define=API_HOST=192.168.1.35`
///
/// Start Django so the app can connect, e.g.:
/// `python manage.py runserver 0.0.0.0:8000`
abstract final class ApiConfig {
  static const int port = 8000;

  /// PC LAN IP when testing on a real Android device (same Wi‑Fi as the PC).
  /// Leave empty when using the Android emulator.
  static const String physicalDeviceHost = '';

  /// Emulator alias to the host machine's loopback interface.
  static const String defaultAndroidHost = '10.0.2.2';

  static const String _envHost = String.fromEnvironment('API_HOST');

  static String get host {
    if (_envHost.isNotEmpty) return _envHost;

    if (physicalDeviceHost.isNotEmpty &&
        defaultTargetPlatform == TargetPlatform.android) {
      return physicalDeviceHost;
    }

    if (kIsWeb) return '127.0.0.1';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return defaultAndroidHost;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return '127.0.0.1';
      default:
        return '127.0.0.1';
    }
  }

  static String get httpBaseUrl => 'http://$host:$port';

  static String get wsBaseUrl => 'ws://$host:$port';

  static Uri httpUri(String path) => Uri.parse('$httpBaseUrl$path');

  static Uri wsUri(String path) => Uri.parse('$wsBaseUrl$path');
}
