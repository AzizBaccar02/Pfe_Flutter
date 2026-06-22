// lib/utils/chat_peer_media.dart

import 'package:flutter/material.dart';

import '../models/chat_conversation_summary_model.dart';
import '../models/interested_agent_model.dart';
import '../services/profile_service.dart';

/// Resolves the counterparty profile photo for a chat row (list + active offers).
String resolveChatPeerPhotoRaw({
  required ChatConversationSummaryModel chat,
  required int viewerUserId,
  required String viewerRole,
  List<dynamic>? matchedAgents,
}) {
  final candidates = <String>[];

  void add(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isNotEmpty && !candidates.contains(value)) {
      candidates.add(value);
    }
  }

  add(chat.flatPeerPhoto);

  final role = viewerRole.toUpperCase();
  final peer = chat.resolvePeerUserForViewer(
    viewerUserId,
    viewerRole: viewerRole,
  );

  if (role == 'AGENT') {
    add(chat.client?.photoUrl);
  } else if (role == 'CLIENT') {
    add(chat.agent?.photoUrl);
    final reactionAgentId = chat.offreReaction?.agentId ?? 0;
    if (reactionAgentId > 0 && chat.agent != null) {
      final a = chat.agent!;
      if (a.id == reactionAgentId || a.userId == reactionAgentId) {
        add(a.photoUrl);
      }
    }
  }

  add(peer?.photoUrl);
  add(chat.otherUser?.photoUrl);
  add(chat.client?.photoUrl);
  add(chat.agent?.photoUrl);

  if (matchedAgents != null && matchedAgents.isNotEmpty) {
    final agentId = chat.linkedAgentId;
    final offerId = chat.linkedOfferId;

    for (final raw in matchedAgents) {
      if (raw is! InterestedAgentModel) continue;
      final url = raw.imageUrl.trim();
      if (url.isEmpty) continue;

      if (agentId > 0 && raw.id == agentId) {
        add(url);
      } else if (offerId > 0 && raw.offerId == offerId) {
        add(url);
      }
    }
  }

  return candidates.isNotEmpty ? candidates.first : '';
}

/// True when [peerPhotoRaw] is the same asset as the signed-in user's profile.
bool isLikelyViewerOwnPhoto({
  required String peerPhotoRaw,
  String? viewerRemoteUrl,
  String? viewerLocalPath,
}) {
  final peerResolved = ProfileService.resolveMediaUrl(peerPhotoRaw)?.trim() ?? '';
  if (peerResolved.isEmpty) return false;

  final remoteResolved =
      ProfileService.resolveMediaUrl(viewerRemoteUrl)?.trim() ?? '';
  if (remoteResolved.isNotEmpty && _sameMediaUrl(peerResolved, remoteResolved)) {
    return true;
  }

  final local = viewerLocalPath?.trim() ?? '';
  if (local.isNotEmpty && _sameMediaUrl(peerResolved, local)) {
    return true;
  }

  return false;
}

bool _sameMediaUrl(String a, String b) {
  if (a == b) return true;

  final normalizedA = _normalizeMediaUrl(a);
  final normalizedB = _normalizeMediaUrl(b);

  if (normalizedA.isEmpty || normalizedB.isEmpty) return false;
  return normalizedA == normalizedB;
}

String _normalizeMediaUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return '';

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return trimmed.toLowerCase();

  return uri.replace(query: '', fragment: '').toString().toLowerCase();
}

/// Stable accent for initials when no photo is available.
Color avatarAccentForChat(int chatId) {
  const palette = <int>[
    0xFF16A34A,
    0xFF0D9488,
    0xFF0284C7,
    0xFF7C3AED,
    0xFFDB2777,
    0xFFEA580C,
  ];

  final index = chatId.abs() % palette.length;
  return Color(palette[index]);
}
