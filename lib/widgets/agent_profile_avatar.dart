// lib/widgets/agent_profile_avatar.dart

import 'package:flutter/material.dart';

import '../services/profile_service.dart';

class AgentProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;
  final Color? backgroundColor;
  final Color? initialsColor;

  const AgentProfileAvatar({
    super.key,
    this.photoUrl,
    required this.displayName,
    this.radius = 30,
    this.backgroundColor,
    this.initialsColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = ProfileService.resolveMediaUrl(photoUrl?.trim() ?? '');
    final bg = backgroundColor ?? const Color(0xFF1F2937);
    final fg = initialsColor ?? Colors.white;

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
              _initials(displayName),
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
        _initials(displayName),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.62,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
