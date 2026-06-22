//lib/screens/offers/agent/agent_main_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../conf/app_providers.dart';
import '../../../conf/theme_provider.dart';
import '../../../services/app_navigation_bus.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_local_read_cursor.dart';
import '../../../services/chat_service.dart';
import '../../../services/profile_service.dart';
import '../../../utils/chat_unread_merge.dart';
import '../../chats/chats_screen.dart';
import '../../notifications/notifications_screen.dart';
import '../../../services/agent_offers_realtime.dart';
import '../../../services/agent_reactions_realtime.dart';
import '../../../services/app_realtime_coordinator.dart';
import '../../../services/notification_realtime_hub.dart';
import '../../../services/chat_realtime_hub.dart';
import '../../../services/presence_service.dart';
import '../widgets/agent_bottom_bar.dart';
import '../widgets/agent_offers_drawer.dart';
import '../widgets/offers_app_bar.dart';
import 'agent_ai_recommendations_screen.dart';
import 'widgets/offer_search_filters.dart';
import 'agent_home_screen.dart';
import 'agent_my_reactions_screen.dart';
import 'agent_offers_screen.dart';

class AgentEntryScreen extends StatelessWidget {
  const AgentEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AgentMainScreen();
  }
}

class AgentMainScreen extends StatefulWidget {
  const AgentMainScreen({super.key});

  @override
  State<AgentMainScreen> createState() => _AgentMainScreenState();
}

class _AgentMainScreenState extends State<AgentMainScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _homeScrollController = ScrollController();

  int _selectedIndex = 0;
  int _unreadChatCount = 0;
  int _unreadNotificationCount = 0;
  StreamSubscription<int>? _notificationCountSubscription;
  StreamSubscription<Map<String, dynamic>>? _chatInboxSubscription;

  bool _isSyncingUnread = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    AppProviders.profile.clearProfileImage();

    _notificationCountSubscription =
        NotificationRealtimeHub.instance.onUnreadCountChanged.listen((count) {
      if (!mounted || _unreadNotificationCount == count) return;
      setState(() => _unreadNotificationCount = count);
    });

    _registerNavigationBus();
    _chatInboxSubscription =
        ChatRealtimeHub.instance.onInboxEvent.listen((event) {
      if (!ChatRealtimeHub.isMessageRelatedEvent(event)) return;
      unawaited(_syncUnreadChatCount());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateProfileImage();
      _syncUnreadChatCount();
      _bootstrapRealtimeServices();
    });
  }

  void _registerNavigationBus() {
    final bus = AppNavigationBus.instance;
    bus.openNotifications = () => unawaited(_openNotifications());
    bus.chatOpened = () async {
      if (!mounted) return;

      setState(() {
        _selectedIndex = 3;
      });

      await _syncUnreadChatCount();
    };
    bus.isChatsTabActive = () => _selectedIndex == 3;
  }

  Future<void> _bootstrapRealtimeServices() async {
    if (!mounted) return;

    await PresenceService.activate();
    await NotificationRealtimeHub.instance.ensureStarted();
    AppRealtimeCoordinator.instance.ensureStarted();
    AgentOffersRealtime.instance.ensureStarted();
    AgentReactionsRealtime.instance.ensureStarted();
    await _bootstrapChatRealtime();

    if (!mounted) return;
    await _bootstrapNotifications();
  }

  Future<void> _syncUnreadChatCount() async {
    if (_isSyncingUnread) return;

    _isSyncingUnread = true;

    try {
      await ChatLocalReadCursor.instance.ensureLoaded();

      final response = await ChatService.getCurrentUserChats();

      final userId = await AuthService.getStoredUserId() ?? 0;

      final chats = ChatUnreadMerge.mergeLists(
        serverChats: response.chats,
        previousChats: const [],
        viewerUserId: userId,
      );

      final cursor = ChatLocalReadCursor.instance;
      final unreadCount = chats.fold<int>(
        0,
        (total, chat) => total + cursor.displayUnreadCount(chat, userId),
      );

      if (!mounted) return;

      if (_unreadChatCount != unreadCount) {
        setState(() {
          _unreadChatCount = unreadCount;
        });
      }
    } catch (_) {
      // Badge sync should stay silent.
    } finally {
      _isSyncingUnread = false;
    }
  }

  Future<void> _bootstrapChatRealtime() async {
    await ChatRealtimeHub.instance.ensureStarted();
  }

  Future<void> _bootstrapNotifications() async {
    final hub = NotificationRealtimeHub.instance;
    await hub.ensureStarted();

    if (!mounted) return;

    if (_unreadNotificationCount != hub.unreadCount) {
      setState(() {
        _unreadNotificationCount = hub.unreadCount;
      });
    }
  }

  Future<void> _hydrateProfileImage() async {
    final provider = AppProviders.profile;

    try {
      final profile = await ProfileService.getAgentProfile();

      if (!mounted) return;

      final remoteUrl = ProfileService.resolveMediaUrl(profile.photoUrl);

      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        provider.setRemoteProfileImageUrl(remoteUrl);
        return;
      }

      if ((provider.localProfileImagePath ?? '').isEmpty) {
        provider.clearProfileImage();
      }
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    final hub = NotificationRealtimeHub.instance;
    await hub.syncUnreadCount();

    if (mounted && _unreadNotificationCount != hub.unreadCount) {
      setState(() {
        _unreadNotificationCount = hub.unreadCount;
      });
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          onNotificationsRead: () {
            if (!mounted) return;

            setState(() {
              _unreadNotificationCount = 0;
            });
          },
        ),
      ),
    );

    if (!mounted) return;

    await hub.syncUnreadCount();
    if (!mounted) return;

    setState(() {
      _unreadNotificationCount = hub.unreadCount;
    });
  }

  void _changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      AgentOffersRealtime.instance.notifyRefresh();
    } else if (index == 2) {
      AgentReactionsRealtime.instance.notifyRefresh();
    }
  }

  Future<void> _openAiRecommendations({
    String? query,
    OfferSearchFilters? filters,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgentAiRecommendationsScreen(
          initialQuery: query,
          initialFilters: filters,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    final screens = [
      AgentHomeScreen(
        scrollController: _homeScrollController,
        isTabActive: _selectedIndex == 0,
        onBrowseOffersTap: () => _changeTab(1),
        onReactionsTap: () => _changeTab(2),
        onChatsTap: () => _changeTab(3),
        onAiMatchTap: _openAiRecommendations,
      ),
      AgentOffersScreen(isTabActive: _selectedIndex == 1),
      AgentMyReactionsScreen(isTabActive: _selectedIndex == 2),
      ChatsScreen(
        onChatStateChanged: _syncUnreadChatCount,
        isTabActive: _selectedIndex == 3,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: AgentOffersDrawer(
        isDarkMode: isDarkMode,
      ),
      appBar: OffersAppBar(
        isDarkMode: isDarkMode,
        notificationUnreadCount: _unreadNotificationCount,
        onProfileTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        onNotificationTap: _openNotifications,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: AgentBottomBar(
        selectedIndex: _selectedIndex,
        isDarkMode: isDarkMode,
        chatUnreadCount: _unreadChatCount,
        onTap: _changeTab,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppNavigationBus.instance.clear();
    _notificationCountSubscription?.cancel();
    _chatInboxSubscription?.cancel();
    _homeScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(PresenceService.refreshOnline());
      unawaited(NotificationRealtimeHub.instance.refreshNow());
      AppRealtimeCoordinator.instance.notifyRefresh(debugLabel: 'resume');
    }
  }
}