import 'package:shared_preferences/shared_preferences.dart';

/// Local record of client–agent matches (survives app restarts).
abstract final class ClientMatchPersistence {
  static const _acceptedPrefix = 'client_match_accepted_';

  static String _pairKey(int offerId, int agentId) =>
      '$_acceptedPrefix${offerId}_$agentId';

  static Future<void> markAccepted({
    required int offerId,
    required int agentId,
    required int reactionId,
  }) async {
    if (offerId <= 0 || agentId <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pairKey(offerId, agentId), 'ACCEPTED');
    if (reactionId > 0) {
      await prefs.setInt('${_acceptedPrefix}rx_$reactionId', reactionId);
    }
  }

  static Future<void> markRejected({
    required int offerId,
    required int agentId,
  }) async {
    if (offerId <= 0 || agentId <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pairKey(offerId, agentId), 'REJECTED');
  }

  static Future<String?> statusFor({
    int? offerId,
    int? agentId,
    int? reactionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (reactionId != null && reactionId > 0) {
      final rx = prefs.getInt('${_acceptedPrefix}rx_$reactionId');
      if (rx != null && rx > 0) {
        return 'ACCEPTED';
      }
    }

    if (offerId != null &&
        offerId > 0 &&
        agentId != null &&
        agentId > 0) {
      return prefs.getString(_pairKey(offerId, agentId));
    }

    return null;
  }

  static Future<bool> isAccepted({
    int? offerId,
    int? agentId,
    int? reactionId,
  }) async {
    final status = await statusFor(
      offerId: offerId,
      agentId: agentId,
      reactionId: reactionId,
    );
    return status?.toUpperCase() == 'ACCEPTED';
  }
}
