import 'package:flutter/material.dart';

import '../screens/chats/widgets/chat_notification_listener.dart';
import '../screens/notifications/widgets/app_notification_listener.dart';
import '../services/app_navigation_bus.dart';

/// Renders in-app notification banners above every route in the app.
class GlobalNotificationOverlay extends StatelessWidget {
  final Widget child;

  const GlobalNotificationOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bus = AppNavigationBus.instance;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: AppNotificationListener(
            onOpenNotifications: bus.openNotifications,
            onReviewAgentInterest: bus.reviewAgentInterest,
            onAgentAccepted: bus.agentAccepted,
            useGlobalTopInset: true,
            child: ChatNotificationListener(
              isChatsTabActive: () =>
                  bus.isChatsTabActive?.call() ?? false,
              onChatOpened: bus.chatOpened,
              useGlobalTopInset: true,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
