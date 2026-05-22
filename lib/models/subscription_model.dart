import 'subscription_plan_model.dart';

class SubscriptionModel {
  final int id;
  final SubscriptionPlanModel? plan;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool cancelAtPeriodEnd;
  final bool hasActiveSubscription;
  final int usageLimit;
  final int remainingUsageCount;
  final int usedUsageCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubscriptionModel({
    required this.id,
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.cancelAtPeriodEnd,
    required this.hasActiveSubscription,
    required this.usageLimit,
    required this.remainingUsageCount,
    required this.usedUsageCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    final planJson = json['plan'];

    return SubscriptionModel(
      id: _parseInt(json['id']) ?? 0,
      plan: planJson is Map<String, dynamic>
          ? SubscriptionPlanModel.fromJson(planJson)
          : null,
      status: _parseString(json['status']),
      startDate: _parseDateTime(json['startDate']),
      endDate: _parseDateTime(json['endDate']),
      isActive: json['isActive'] == true,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] == true,
      hasActiveSubscription: json['hasActiveSubscription'] == true,
      usageLimit: _parseInt(json['usageLimit']) ?? 0,
      remainingUsageCount: _parseInt(json['remainingUsageCount']) ?? 0,
      usedUsageCount: _parseInt(json['usedUsageCount']) ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Active';
      case 'INCOMPLETE':
        return 'Incomplete';
      case 'PAST_DUE':
        return 'Past due';
      case 'CANCELED':
        return 'Canceled';
      case 'UNPAID':
        return 'Unpaid';
      case 'EXPIRED':
        return 'Expired';
      default:
        return status;
    }
  }
}

class FreeUsageModel {
  final int freeUsageLimit;
  final int remainingFreeUsageCount;
  final int usedFreeUsageCount;

  const FreeUsageModel({
    required this.freeUsageLimit,
    required this.remainingFreeUsageCount,
    required this.usedFreeUsageCount,
  });

  factory FreeUsageModel.fromJson(Map<String, dynamic> json) {
    return FreeUsageModel(
      freeUsageLimit: _parseInt(json['freeUsageLimit']) ?? 0,
      remainingFreeUsageCount: _parseInt(json['remainingFreeUsageCount']) ?? 0,
      usedFreeUsageCount: _parseInt(json['usedFreeUsageCount']) ?? 0,
    );
  }

  bool get hasRemaining => remainingFreeUsageCount > 0;
}

class MySubscriptionModel {
  final bool hasActiveSubscription;
  final String activeUsageSource;
  final SubscriptionModel? subscription;
  final FreeUsageModel freeUsage;
  final String? message;

  const MySubscriptionModel({
    required this.hasActiveSubscription,
    required this.activeUsageSource,
    required this.subscription,
    required this.freeUsage,
    this.message,
  });

  factory MySubscriptionModel.fromJson(Map<String, dynamic> json) {
    final subscriptionJson = json['subscription'];
    final freeUsageJson = json['freeUsage'];

    return MySubscriptionModel(
      hasActiveSubscription: json['hasActiveSubscription'] == true,
      activeUsageSource: _parseString(json['activeUsageSource']),
      subscription: subscriptionJson is Map<String, dynamic>
          ? SubscriptionModel.fromJson(subscriptionJson)
          : null,
      freeUsage: freeUsageJson is Map<String, dynamic>
          ? FreeUsageModel.fromJson(freeUsageJson)
          : const FreeUsageModel(
              freeUsageLimit: 0,
              remainingFreeUsageCount: 0,
              usedFreeUsageCount: 0,
            ),
      message: json['message']?.toString(),
    );
  }

  bool get isOnFreePlan => activeUsageSource.toUpperCase() == 'FREE';

  bool get canPerformAction {
    if (hasActiveSubscription) return true;
    return freeUsage.hasRemaining;
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

String _parseString(dynamic value) => value?.toString().trim() ?? '';

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;

  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  return DateTime.tryParse(raw);
}
