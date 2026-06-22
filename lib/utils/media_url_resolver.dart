import '../services/auth_service.dart';

/// Builds absolute URLs for Django media paths (`/media/...`).
abstract final class MediaUrlResolver {
  static String get apiBaseUrl => AuthService.apiBaseUrl;

  static String? resolve(String? rawUrl) {
    if (rawUrl == null) return null;

    final value = rawUrl.trim();
    if (value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('assets/')) {
      return value;
    }

    final path = value.startsWith('/') ? value : '/$value';
    return '$apiBaseUrl$path';
  }

  static List<String> resolveAll(Iterable<String> urls) {
    return urls
        .map((url) => resolve(url))
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();
  }

  /// Extracts image URL strings from common Django/DRF payload shapes.
  static List<String> parseImageList(dynamic value) {
    if (value == null) return const [];

    if (value is String) {
      final resolved = resolve(value);
      return resolved == null ? const [] : [resolved];
    }

    if (value is! List) return const [];

    final urls = <String>[];

    for (final item in value) {
      if (item is String) {
        final resolved = resolve(item);
        if (resolved != null) urls.add(resolved);
        continue;
      }

      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final raw = map['url'] ??
            map['image'] ??
            map['file'] ??
            map['photo'] ??
            map['image_url'] ??
            map['imageUrl'];
        final resolved = resolve(raw?.toString());
        if (resolved != null) urls.add(resolved);
      }
    }

    return urls;
  }
}
