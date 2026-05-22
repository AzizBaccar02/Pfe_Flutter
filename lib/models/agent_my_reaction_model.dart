/// One row from `GET /api/interactions/my-reactions/` ([OffreReactionSerializer]).
class AgentMyReactionModel {
  final int id;
  final int offerId;
  final String offerTitle;
  final bool react;
  final String status;
  final String message;
  final String proposedPriceDisplay;
  final DateTime? createdAt;

  const AgentMyReactionModel({
    required this.id,
    required this.offerId,
    required this.offerTitle,
    required this.react,
    required this.status,
    required this.message,
    required this.proposedPriceDisplay,
    required this.createdAt,
  });

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final s = value.toString().trim().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static String _proposedPrice(dynamic value) {
    if (value == null) return '';
    final s = value.toString().trim();
    return s;
  }

  static AgentMyReactionModel fromJson(Map<String, dynamic> json) {
    final proposed = _proposedPrice(json['proposedPrice']);
    final withDt = proposed.isEmpty
        ? ''
        : (proposed.toUpperCase().endsWith('DT') ? proposed : '$proposed DT');

    return AgentMyReactionModel(
      id: _parseInt(json['id']) ?? 0,
      offerId: _parseInt(json['offre']) ?? 0,
      offerTitle: (json['offer_title'] ?? '').toString().trim(),
      react: _parseBool(json['react']) ?? false,
      status: (json['status'] ?? '').toString().trim().toUpperCase(),
      message: (json['message'] ?? '').toString().trim(),
      proposedPriceDisplay: withDt,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  bool get isPending => status == 'PENDING';

  bool get isAccepted => status == 'ACCEPTED';

  bool get isRejected => status == 'REJECTED';

  /// User-facing outcome line (no i18n keys).
  String get outcomeLabel {
    if (!react) return 'You rejected this offer';

    if (isPending) return 'Awaiting client response';

    if (isAccepted) return 'Client accepted · matched';

    if (isRejected) return 'Client declined';

    return status.isEmpty ? 'Unknown status' : status;
  }
}
