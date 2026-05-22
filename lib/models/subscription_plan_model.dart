class SubscriptionPlanModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String period;
  final List<String> features;
  final int usageLimit;
  final bool isActive;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.period,
    required this.features,
    required this.usageLimit,
    required this.isActive,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: _parseInt(json['id']) ?? 0,
      name: _parseString(json['name']),
      description: _parseString(json['description']),
      price: _parseDouble(json['price']),
      period: _parseString(json['period']),
      features: _parseFeatures(json['features']),
      usageLimit: _parseInt(json['usageLimit']) ?? 0,
      isActive: json['isActive'] == true,
    );
  }

  String get periodLabel {
    switch (period.toUpperCase()) {
      case 'YEARLY':
        return 'year';
      case 'MONTHLY':
      default:
        return 'month';
    }
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

String _parseString(dynamic value) => value?.toString().trim() ?? '';

List<String> _parseFeatures(dynamic value) {
  if (value is! List) return const [];

  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}
