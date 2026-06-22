// lib/screens/offers/client/client_main_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../conf/app_providers.dart';
import '../../../conf/theme_provider.dart';
import '../../../data/mock_client_data.dart';
import '../../../models/interested_agent_model.dart';
import '../../../services/chat_local_read_cursor.dart';
import '../../../services/chat_service.dart';
import '../../../services/chat_realtime_hub.dart';
import '../../../utils/chat_unread_merge.dart';
import '../../../services/profile_service.dart';
import '../../auth/client/client_profile_screen.dart';
import '../../chats/chats_screen.dart';
import '../../notifications/notifications_screen.dart';
import '../../../services/app_navigation_bus.dart';
import '../../../services/auth_service.dart';
import '../../../services/offer_service.dart';
import '../../../services/app_realtime_coordinator.dart';
import '../../../services/client_interaction_realtime.dart';
import '../../../services/notification_realtime_hub.dart';
import '../../../services/presence_service.dart';
import 'client_home_screen.dart';
import 'create_offer_screen.dart';
import 'interested_agents_screen.dart';
import 'my_offers_screen.dart';
import '../widgets/offers_app_bar.dart';
import '../widgets/offers_bottom_bar.dart';
import '../widgets/offers_drawer.dart';

class ClientEntryScreen extends StatelessWidget {
  const ClientEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClientMainScreen();
  }
}

class ClientMainScreen extends StatefulWidget {
  const ClientMainScreen({super.key});

  @override
  State<ClientMainScreen> createState() => _ClientMainScreenState();
}

class _ClientMainScreenState extends State<ClientMainScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _homeScrollController = ScrollController();

  int _selectedIndex = 0;
  int _unreadChatCount = 0;
  int _unreadNotificationCount = 0;
  int _interestedPendingCount = 0;
  StreamSubscription<int>? _notificationCountSubscription;
  StreamSubscription<Map<String, dynamic>>? _chatInboxSubscription;
  int _offersRefreshSeed = 0;
  /// Bumped after a successful create so [IndexedStack] rebuilds a fresh form.
  int _createOfferSeed = 0;
  bool _isSyncingUnread = false;

  final Set<int> _processedReactionIds = {};
  final List<InterestedAgentModel> _matchedAgents = [];

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
      _syncClientAccountUserId();
      _hydrateProfileImage();
      _syncUnreadChatCount();
      _bootstrapRealtimeServices();
    });
  }

  void _registerNavigationBus() {
    final bus = AppNavigationBus.instance;
    bus.openNotifications = () => unawaited(_openNotifications());
    bus.reviewAgentInterest = _openInterestedFromNotification;
    bus.agentAccepted = _handleMatchedAgent;
    bus.chatOpened = () async {
      if (!mounted) return;

      setState(() {
        _selectedIndex = 4;
      });

      await _syncUnreadChatCount();
    };
    bus.isChatsTabActive = () => _selectedIndex == 4;
  }

  void _openInterestedFromNotification() {
    ClientInteractionRealtime.instance.notifyRefresh();
    _changeTab(3);
  }

  Future<void> _bootstrapRealtimeServices() async {
    if (!mounted) return;

    await PresenceService.activate();

    AppRealtimeCoordinator.instance.ensureStarted();
    ClientInteractionRealtime.instance.ensureStarted();
    await NotificationRealtimeHub.instance.ensureStarted();
    await _bootstrapChatRealtime();

    if (!mounted) return;
    await _bootstrapNotifications();
  }

  Future<void> _bootstrapChatRealtime() async {
    await ChatRealtimeHub.instance.ensureStarted();
  }

  Future<void> _syncClientAccountUserId() async {
    final userId = await AuthService.getStoredUserId();

    if (userId != null && userId > 0) {
      MockClientData.clientAccountUserId = userId;
    }
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
      // Keep silent. Badge sync should never disturb the UI.
    } finally {
      _isSyncingUnread = false;
    }
  }

  Future<void> _hydrateProfileImage() async {
    final provider = AppProviders.profile;

    try {
      final profile = await ProfileService.getClientProfile();

      if (!mounted) return;

      final remoteUrl = ProfileService.resolveMediaUrl(profile.photoUrl);

      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        provider.setRemoteProfileImageUrl(remoteUrl);
      } else {
        provider.clearProfileImage();
      }
    } catch (_) {
      if (!mounted) return;
      provider.clearProfileImage();
    }
  }

  void _handleOfferCreated() {
    OfferService.invalidateMyOffersCache();
    setState(() {
      _createOfferSeed++;
      _offersRefreshSeed++;
      _selectedIndex = 1;
    });
  }

  Future<void> _openNotifications() async {
    final hub = NotificationRealtimeHub.instance;
    await hub.syncUnreadCount();

    if (mounted && _unreadNotificationCount != hub.unreadCount) {
      setState(() {
        _unreadNotificationCount = hub.unreadCount;
      });
    }

    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          onNotificationsRead: () {
            if (!mounted) return;

            setState(() {
              _unreadNotificationCount = 0;
            });
          },
          onAgentAccepted: _handleMatchedAgent,
        ),
      ),
    );

    if (!mounted) return;

    await hub.syncUnreadCount();
    if (!mounted) return;

    setState(() {
      _unreadNotificationCount = hub.unreadCount;
    });

    if (result is InterestedAgentModel) {
      _handleMatchedAgent(result);
    }
  }

  void _changeTab(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) {
      ClientInteractionRealtime.instance.notifyRefresh();
    }

    if (index == 4) {
      _syncUnreadChatCount();
    }
  }

  void _handleProcessedAgent(InterestedAgentModel agent) {
    if (agent.reactionId <= 0) return;

    setState(() {
      _processedReactionIds.add(agent.reactionId);
    });
    ClientInteractionRealtime.instance.notifyRefresh();
  }

  void _handleMatchedAgent(InterestedAgentModel agent) {
    final alreadyExists = _matchedAgents.any((item) => item.id == agent.id);

    if (!alreadyExists) {
      setState(() {
        _matchedAgents.insert(0, agent);
        _selectedIndex = 4;
      });

      _syncUnreadChatCount();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF151515),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedFavourite,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Match created with ${agent.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = 4;
      });

      _syncUnreadChatCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : const Color(0xFFF5F5F7);

    final screens = [
      ClientHomeScreen(
        scrollController: _homeScrollController,
        isTabActive: _selectedIndex == 0,
        onCreateOfferTap: () => _changeTab(2),
        onMyOffersTap: () => _changeTab(1),
        onInterestedTap: () => _changeTab(3),
        onChatsTap: () => _changeTab(4),
      ),
      MyOffersScreen(
        refreshToken: _offersRefreshSeed,
        isTabActive: _selectedIndex == 1,
      ),
      CreateOfferScreen(
        key: ValueKey(_createOfferSeed),
        onBack: () => _changeTab(0),
        onCreated: _handleOfferCreated,
      ),
      InterestedAgentsScreen(
        showBackButton: false,
        isTabActive: _selectedIndex == 3,
        hiddenReactionIds: _processedReactionIds,
        onProcessed: _handleProcessedAgent,
        onMatched: _handleMatchedAgent,
        onPendingCountChanged: (count) {
          if (!mounted || _interestedPendingCount == count) return;
          setState(() => _interestedPendingCount = count);
        },
      ),
      ChatsScreen(
        matchedAgents: _matchedAgents,
        onChatStateChanged: _syncUnreadChatCount,
        isTabActive: _selectedIndex == 4,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: OffersDrawer(
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
      bottomNavigationBar: OffersBottomBar(
        selectedIndex: _selectedIndex,
        isDarkMode: isDarkMode,
        chatUnreadCount: _unreadChatCount,
        interestedPendingCount: _interestedPendingCount,
        onHomeTap: () => _changeTab(0),
        onOffersTap: () => _changeTab(1),
        onAddTap: () => _changeTab(2),
        onInterestedTap: () => _changeTab(3),
        onChatsTap: () => _changeTab(4),
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

class ClientProfileCompletionScreen extends StatelessWidget {
  const ClientProfileCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: OffersAppBar(
        isDarkMode: isDarkMode,
        onProfileTap: () {},
        onNotificationTap: () {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF161616)
                  : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.7),
                  size: 18,
                ),
                const SizedBox(height: 20),
                Text(
                  'Complete your profile to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Phone number and location are required before posting offers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.68)
                        : Colors.black.withValues(alpha: 0.68),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClientProfileScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.white : Colors.black,
                      foregroundColor: isDarkMode ? Colors.black : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Complete Profile',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}