// lib/models/app_notification_model.dart

enum AppNotificationType {
  message,
  match,
  offer,
  system,
}

class AppNotificationModel {
  final int id;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  const AppNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: _parseInt(json['id']) ?? 0,
      type: _parseType(json['type']),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: _parseDate(json['created_at']) ??
          _parseDate(json['createdAt']) ??
          DateTime.now(),
      isRead: _parseBool(json['isRead']) ??
          _parseBool(json['is_read']) ??
          false,
    );
  }

  AppNotificationModel copyWith({
    int? id,
    AppNotificationType? type,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

AppNotificationType _parseType(dynamic value) {
  final normalized = value?.toString().trim().toUpperCase() ?? '';

  switch (normalized) {
    case 'NEW_MESSAGE':
    case 'MESSAGE':
      return AppNotificationType.message;

    case 'MATCH_CREATED':
    case 'MATCH':
      return AppNotificationType.match;

    case 'PROPOSAL_STATUS':
    case 'OFFER':
    case 'PROPOSAL':
      return AppNotificationType.offer;

    case 'SYSTEM':
    default:
      return AppNotificationType.system;
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;

  final normalized = value.toString().trim().toLowerCase();

  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }

  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }

  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}