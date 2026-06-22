import 'package:flutter/foundation.dart';

import '../models/interested_agent_model.dart';

/// Lightweight bridge so global in-app notification overlays can trigger
/// main-shell navigation (tab switches, inbox, interest review) without
/// living inside a specific screen widget tree.
class AppNavigationBus {
  AppNavigationBus._();

  static final AppNavigationBus instance = AppNavigationBus._();

  VoidCallback? openNotifications;
  VoidCallback? reviewAgentInterest;
  void Function(InterestedAgentModel agent)? agentAccepted;
  Future<void> Function()? chatOpened;
  bool Function()? isChatsTabActive;

  void clear() {
    openNotifications = null;
    reviewAgentInterest = null;
    agentAccepted = null;
    chatOpened = null;
    isChatsTabActive = null;
  }
}
