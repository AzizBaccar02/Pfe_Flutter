//lib/screens/offers/agent/agent_main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

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
import '../widgets/offers_app_bar.dart';
import 'agent_home_screen.dart';
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

  double _appBarHideProgress = 0;

  @override
  void initState() {
    super.initState();

    _homeScrollController.addListener(_handleHomeScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateProfileImage();
      _bootstrapNotifications();
    });
  }

  void _handleHomeScroll() {
    if (_selectedIndex != 0) return;

    final offset = _homeScrollController.offset;
    const hideDistance = 90.0;

    final nextProgress = (offset / hideDistance).clamp(0.0, 1.0);

    if ((nextProgress - _appBarHideProgress).abs() > 0.01) {
      setState(() {
        _appBarHideProgress = nextProgress;
      });
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
      _appBarHideProgress = 0;
    });
  }

  @override
  void dispose() {
    _homeScrollController.removeListener(_handleHomeScroll);
    _homeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    const baseAppBarHeight = kToolbarHeight;

    final visibleHeight = _selectedIndex == 0
        ? baseAppBarHeight * (1 - _appBarHideProgress)
        : baseAppBarHeight;

    final visibleOpacity = _selectedIndex == 0
        ? (1 - _appBarHideProgress).clamp(0.0, 1.0)
        : 1.0;

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
      ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(visibleHeight),
        child: ClipRect(
          child: SizedBox(
            height: visibleHeight,
            child: Opacity(
              opacity: visibleOpacity,
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: visibleOpacity <= 0 ? 0 : visibleOpacity,
                child: Transform.translate(
                  offset: Offset(0, -20 * _appBarHideProgress),
                  child: OffersAppBar(
                    isDarkMode: isDarkMode,
                    notificationUnreadCount: _unreadNotificationCount,
                    onProfileTap: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    onNotificationTap: _openNotifications,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: AppNotificationListener(
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
              _appBarHideProgress = 0;
            });
          },
          child: IndexedStack(
            index: _selectedIndex,
            children: screens,
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

class _AgentSectionPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  final dynamic icon;

  const _AgentSectionPlaceholder({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF151515) : const Color(0xFFF5F5F5);
    final softColor =
        isDarkMode ? const Color(0xFF222222) : const Color(0xFFEDEDED);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.68)
        : Colors.black.withOpacity(0.62);

    return Container(
      color: backgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: icon,
                      color: primaryTextColor.withOpacity(0.80),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    height: 1.55,
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