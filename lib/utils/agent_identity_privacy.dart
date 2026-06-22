/// Masks agent identity until a client accepts their interest.
abstract final class AgentIdentityPrivacy {
  static String initials(String? fullName) {
    final parts = (fullName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'A';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  /// Short label shown before acceptance, e.g. "Agent MB".
  static String publicLabel(String? fullName) {
    final inits = initials(fullName);
    if (inits == 'A') return 'Interested agent';
    return 'Agent $inits';
  }

  static String interestHeadline(String? fullName, String offerTitle) {
    final safeOffer = offerTitle.trim().isEmpty ? 'your offer' : offerTitle.trim();
    return '${publicLabel(fullName)} is interested in "$safeOffer".';
  }

  static String sanitizeMessage({
    required String? message,
    required String? fullName,
    required String offerTitle,
  }) {
    final trimmed = message?.trim() ?? '';
    if (trimmed.isEmpty) {
      return interestHeadline(fullName, offerTitle);
    }

    final name = fullName?.trim();
    if (name == null || name.isEmpty) return trimmed;

    var sanitized = trimmed.replaceAll(name, publicLabel(fullName));

    final firstName = name.split(RegExp(r'\s+')).first;
    if (firstName.length > 1) {
      sanitized = sanitized.replaceAll(firstName, publicLabel(fullName));
    }

    return sanitized;
  }

  static const String hiddenContactValue = 'Available after acceptance';

  static const String profileGateHint =
      'Contact details and full identity are shared after you accept this agent.';

  /// True while the client has not accepted the agent's interest.
  static bool shouldHidePhoto(String? status) {
    final normalized = status?.trim().toUpperCase() ?? '';
    return normalized.isEmpty || normalized == 'PENDING';
  }

  /// True once the client has accepted the agent on an offer.
  static bool shouldRevealClientIdentity(String? interactionStatus) {
    final normalized = interactionStatus?.trim().toUpperCase() ?? '';
    return normalized == 'ACCEPTED' || normalized == 'MATCHED';
  }

  /// Client label for agents before acceptance, e.g. "Client : MB".
  static String clientPublicLabel(String? fullName) {
    final trimmed = (fullName ?? '').trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'client') {
      return 'Client';
    }

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('client :') || lower.startsWith('client:')) {
      return trimmed;
    }

    final inits = initials(trimmed);
    if (inits == 'A') return 'Client';
    return 'Client : $inits';
  }

  /// Full name after acceptance; initials-only label otherwise.
  static String clientDisplayLabel({
    required String? fullName,
    required String? interactionStatus,
  }) {
    if (shouldRevealClientIdentity(interactionStatus)) {
      final trimmed = (fullName ?? '').trim();
      return trimmed.isEmpty ? 'Client' : trimmed;
    }
    return clientPublicLabel(fullName);
  }
}
