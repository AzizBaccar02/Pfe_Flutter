import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../utils/media_url_resolver.dart';

/// Displays an offer cover from network, assets, or local file path.
class OfferCoverImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Color? placeholderColor;
  final bool isDarkMode;

  const OfferCoverImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholderColor,
    this.isDarkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = placeholderColor ??
        (isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0));

    final resolved = MediaUrlResolver.resolve(imageUrl);
    if (resolved == null || resolved.isEmpty) {
      return _placeholder(placeholder);
    }

    if (resolved.startsWith('assets/')) {
      return Image.asset(
        resolved,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(placeholder),
      );
    }

    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      return Image.network(
        resolved,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(placeholder),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return ColoredBox(
            color: placeholder,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }

    return Image.file(
      File(resolved),
      fit: fit,
      errorBuilder: (_, __, ___) => _placeholder(placeholder),
    );
  }

  Widget _placeholder(Color color) {
    return ColoredBox(
      color: color,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedBriefcase01,
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.35),
          size: 28,
        ),
      ),
    );
  }
}
