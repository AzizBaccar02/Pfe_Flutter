enum SubscriptionHistoryType {
  freeTier,
  subscriptionCreated,
  checkoutStarted,
  activated,
  renewed,
  usageConsumed,
  periodEnd,
  canceled,
  expired,
  updated,
}

class SubscriptionHistoryItem {
  final SubscriptionHistoryType type;
  final String title;
  final String subtitle;
  final DateTime? date;
  final bool isHighlight;

  const SubscriptionHistoryItem({
    required this.type,
    required this.title,
    required this.subtitle,
    this.date,
    this.isHighlight = false,
  });
}
