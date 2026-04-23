import '../models/app_notification_model.dart';

class MockNotificationData {
  static List<AppNotificationModel> _items = [
    AppNotificationModel(
      id: 1,
      type: AppNotificationType.match,
      title: 'New match created',
      body: 'You matched with Sarah Ben Ali for your plumbing offer.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      isRead: false,
    ),
    AppNotificationModel(
      id: 2,
      type: AppNotificationType.message,
      title: 'New message received',
      body: 'Sarah sent you a new message about the job timing.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
      isRead: false,
    ),
    AppNotificationModel(
      id: 3,
      type: AppNotificationType.offer,
      title: 'Offer activity update',
      body: 'A new agent reacted positively to your electrical issue offer.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    AppNotificationModel(
      id: 4,
      type: AppNotificationType.system,
      title: 'Profile reminder',
      body: 'Complete your profile details to improve trust and visibility.',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      isRead: true,
    ),
    AppNotificationModel(
      id: 5,
      type: AppNotificationType.offer,
      title: 'Offer published successfully',
      body: 'Your new home repair offer is now visible to agents.',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      isRead: true,
    ),
    AppNotificationModel(
      id: 6,
      type: AppNotificationType.message,
      title: 'Conversation reopened',
      body: 'A matched agent returned to the conversation after a new reply.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
  ];

  static List<AppNotificationModel> get all {
    final list = List<AppNotificationModel>.from(_items);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static int get unreadCount => _items.where((item) => !item.isRead).length;

  static void markAsRead(int id) {
    _items = _items.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
  }

  static void markAllAsRead() {
    _items = _items.map((item) => item.copyWith(isRead: true)).toList();
  }

  static bool get hasUnread => unreadCount > 0;
}