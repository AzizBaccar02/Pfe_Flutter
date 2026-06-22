// lib/widgets/agent_profile_avatar.dart

import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import '../utils/agent_identity_privacy.dart';

class AgentProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;
  final Color? backgroundColor;
  final Color? initialsColor;

  /// When true, only initials are shown (pre-acceptance client view).
  final bool hidePhoto;

  const AgentProfileAvatar({
    super.key,
    this.photoUrl,
    required this.displayName,
    this.radius = 30,
    this.backgroundColor,
    this.initialsColor,
    this.hidePhoto = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = hidePhoto
        ? null
        : ProfileService.resolveMediaUrl(photoUrl?.trim() ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB));
    final fg = initialsColor ??
        (isDark ? Colors.white : const Color(0xFF374151));

    if (resolved != null && resolved.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          resolved,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(
            radius: radius,
            backgroundColor: bg,
            child: Text(
              AgentIdentityPrivacy.initials(displayName),
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.62,
              ),
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        AgentIdentityPrivacy.initials(displayName),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.62,
        ),
      ),
    );
  }
}
