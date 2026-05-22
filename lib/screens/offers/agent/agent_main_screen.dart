//lib/screens/offers/agent/agent_main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../conf/user_profile_provider.dart';
import '../../../services/profile_service.dart';
import '../../chats/chats_screen.dart';
import '../../chats/widgets/chat_notification_listener.dart';
import '../../notifications/notifications_screen.dart';
import '../../notifications/widgets/app_notification_listener.dart';
import '../../../services/notification_realtime_hub.dart';
import '../widgets/agent_bottom_bar.dart';
import '../widgets/agent_offers_drawer.dart';
import '../widgets/offers_app_bar_layout.dart';
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

class _AgentMainScreenState extends State<AgentMainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _homeScrollController = ScrollController();

  int _selectedIndex = 0;
  int _unreadChatCount = 0;
  int _unreadNotificationCount = 0;

  final OffersAppBarScrollBehavior _appBarScroll = OffersAppBarScrollBehavior();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateProfileImage();
      _bootstrapNotifications();
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_selectedIndex != 0) return false;

    if (_appBarScroll.handle(notification)) {
      setState(() {});
    }

    return false;
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
    try {
      final profile = await ProfileService.getAgentProfile();

      if (!mounted) return;

      final provider = context.read<UserProfileProvider>();
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

    setState(() {
      _unreadNotificationCount = 0;
    });
  }

  void _changeTab(int index) {
    setState(() {
      _selectedIndex = index;
      _appBarScroll.reset();
    });
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    final screens = [
      AgentHomeScreen(
        scrollController: _homeScrollController,
        onBrowseOffersTap: () => _changeTab(1),
        onReactionsTap: () => _changeTab(2),
        onChatsTap: () => _changeTab(3),
      ),
      const AgentOffersScreen(),
      const _AgentSectionPlaceholder(
        title: 'My Reactions',
        subtitle:
            'Proposal status, pending reactions, and accepted responses will appear here next.',
        icon: HugeIcons.strokeRoundedFavourite,
      ),
      ChatsScreen(
        isTabActive: _selectedIndex == 3,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: AgentOffersDrawer(
        isDarkMode: isDarkMode,
        onHomeTap: () => _changeTab(0),
        onOffersTap: () => _changeTab(1),
        onReactionsTap: () => _changeTab(2),
        onChatsTap: () => _changeTab(3),
      ),
      appBar: CollapsibleOffersAppBar(
        isDarkMode: isDarkMode,
        notificationUnreadCount: _unreadNotificationCount,
        hideProgress: _appBarScroll.hideProgress,
        collapsible: _selectedIndex == 0,
        onProfileTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        onNotificationTap: _openNotifications,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: AppNotificationListener(
          onUnreadCountChanged: (count) {
            if (!mounted || _unreadNotificationCount == count) return;

            setState(() {
              _unreadNotificationCount = count;
            });
          },
          onOpenNotifications: _openNotifications,
          child: ChatNotificationListener(
            isChatsTabActive: _selectedIndex == 3,
            onUnreadCountChanged: (count) {
              if (!mounted || _unreadChatCount == count) return;

              setState(() {
                _unreadChatCount = count;
              });
            },
            onChatOpened: () async {
              if (!mounted) return;

              setState(() {
                _selectedIndex = 3;
                _appBarScroll.reset();
              });
            },
            child: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),
          ),
        ),
      ),
      bottomNavigationBar: AgentBottomBar(
        selectedIndex: _selectedIndex,
        isDarkMode: isDarkMode,
        chatUnreadCount: _unreadChatCount,
        onTap: _changeTab,
      ),
    );
  }
}