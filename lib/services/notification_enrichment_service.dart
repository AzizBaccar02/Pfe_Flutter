// lib/services/notification_enrichment_service.dart

import 'package:flutter/foundation.dart';

import '../models/app_notification_model.dart';
import '../models/offer_interaction_model.dart';
import 'interaction_service.dart';

class NotificationEnrichmentService {
  static Future<List<AppNotificationModel>> enrich(
    List<AppNotificationModel> notifications,
  ) async {
    if (notifications.isEmpty) return notifications;

    final needsWork = notifications.where(_needsEnrichment).toList();
    if (needsWork.isEmpty) return notifications;

    final pending = await _fetchPending(needsWork);
    return notifications.map((n) => _enrichOne(n, pending)).toList();
  }

  static Future<AppNotificationModel> enrichOne(
    AppNotificationModel notification,
  ) async {
    if (!_needsEnrichment(notification)) return notification;
    final pending = await _fetchPending([notification]);
    return _enrichOne(notification, pending);
  }

  static bool _needsEnrichment(AppNotificationModel n) {
    if (!n.isAgentInterestNotification) return false;
    return n.offerId == null || n.agentId == null || n.interactionId == null;
  }

  static Future<List<OfferInteractionModel>> _fetchPending(
    List<AppNotificationModel> notifications,
  ) async {
    final results = <OfferInteractionModel>[];

    try {
      results.addAll(await InteractionService.getClientPendingInteractions());
    } catch (e) {
      debugPrint('[ENRICH] getClientPendingInteractions: $e');
    }

    final knownOfferIds = notifications
        .where((n) => n.offerId != null)
        .map((n) => n.offerId!)
        .toSet();

    for (final offerId in knownOfferIds) {
      try {
        results.addAll(await InteractionService.getPendingForOffer(offerId));
      } catch (e) {
        debugPrint('[ENRICH] getPendingForOffer($offerId): $e');
      }
    }

    final seen = <int>{};
    return results.where((item) {
      if (item.id <= 0) return true;
      return seen.add(item.id);
    }).toList();
  }

  static AppNotificationModel _enrichOne(
    AppNotificationModel n,
    List<OfferInteractionModel> pending,
  ) {
    if (!_needsEnrichment(n)) return n;

    final match = _findMatch(n, pending);
    if (match == null) return n;

    return n.copyWith(
      type:          AppNotificationType.agentLikedOffer,
      tapAction:     NotificationTapAction.reviewAgentInterest,
      offerId:       n.offerId       ?? (match.offerId > 0 ? match.offerId : null),
      agentId:       n.agentId       ?? (match.agentId > 0 ? match.agentId : null),
      interactionId: n.interactionId ?? (match.id > 0 ? match.id : null),
      agentName:     _best(n.agentName, match.agentName),
      agentEmail:    n.agentEmail    ?? match.agentEmail,
      offerTitle:    _best(n.offerTitle, match.offerTitle),
    );
  }

  static OfferInteractionModel? _findMatch(
    AppNotificationModel n,
    List<OfferInteractionModel> pending,
  ) {
    if (n.interactionId != null) {
      final hit = pending.where((p) => p.id == n.interactionId).firstOrNull;
      if (hit != null) return hit;
    }
    if (n.offerId != null && n.agentId != null) {
      final hit = pending
          .where((p) => p.offerId == n.offerId && p.agentId == n.agentId)
          .firstOrNull;
      if (hit != null) return hit;
    }
    if (n.offerId != null) {
      final forOffer = pending.where((p) => p.offerId == n.offerId).toList();
      if (forOffer.length == 1) return forOffer.first;
    }
    return null;
  }

  static String? _best(String? a, String? b) {
    if (a != null && a.trim().isNotEmpty) return a.trim();
    if (b != null && b.trim().isNotEmpty) return b.trim();
    return null;
  }
}