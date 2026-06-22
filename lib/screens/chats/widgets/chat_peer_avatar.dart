// lib/screens/chats/widgets/chat_peer_avatar.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

import '../../../services/profile_service.dart';

/// Circular peer avatar with correct aspect ratio and sharp network loading.
class ChatPeerAvatar extends StatelessWidget {
  final double size;
  final String? photoUrl;
  final String? localPhotoPath;
  final String initials;
  final Color? accentColor;
  final bool showBorder;
  final bool isDarkMode;

  const ChatPeerAvatar({
    super.key,
    required this.size,
    this.photoUrl,
    this.localPhotoPath,
    required this.initials,
    this.accentColor,
    this.showBorder = true,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.accent;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final placeholderBg = isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE8E8ED);

    final diameter = size;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (diameter * dpr * 2.5).round().clamp(96, 512);

    Widget innerFace() {
      final local = localPhotoPath?.trim() ?? '';
      if (local.isNotEmpty) {
        final file = File(local);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: diameter,
            height: diameter,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _initialsTile(
              diameter: diameter,
              accent: accent,
              placeholderBg: placeholderBg,
              initials: initials,
            ),
          );
        }
      }

      final networkUrl = photoUrl?.trim() ?? '';
      if (networkUrl.isNotEmpty) {
        return Image.network(
          networkUrl,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          cacheWidth: cacheSize,
          cacheHeight: cacheSize,
          errorBuilder: (_, _, _) => _initialsTile(
            diameter: diameter,
            accent: accent,
            placeholderBg: placeholderBg,
            initials: initials,
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _initialsTile(
              diameter: diameter,
              accent: accent,
              placeholderBg: placeholderBg,
              initials: initials,
              showSpinner: true,
            );
          },
        );
      }

      return _initialsTile(
        diameter: diameter,
        accent: accent,
        placeholderBg: placeholderBg,
        initials: initials,
      );
    }

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: accent.withValues(alpha: 0.85),
                width: 2,
              )
            : Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(child: innerFace()),
    );
  }

  static Widget _initialsTile({
    required double diameter,
    required Color accent,
    required Color placeholderBg,
    required String initials,
    bool showSpinner = false,
  }) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.88),
            accent.withValues(alpha: 0.45),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: showSpinner
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            )
          : Text(
              initials,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: Colors.white,
                fontSize: (diameter * 0.34).clamp(12, 18),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
    );
  }
}
