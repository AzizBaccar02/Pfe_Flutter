// lib/screens/offers/client/client_main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../conf/theme_provider.dart';
import '../../../conf/user_profile_provider.dart';
import '../../../models/interested_agent_model.dart';
import '../../../services/chat_service.dart';
import '../../../services/profile_service.dart';
import '../../auth/client/client_profile_screen.dart';
import '../../chats/chats_screen.dart';
import '../../chats/widgets/chat_notification_listener.dart';
import '../../notifications/notifications_screen.dart';
import '../../notifications/widgets/app_notification_listener.dart';
import 'client_home_screen.dart';
import 'interested_agents_screen.dart';
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

class _ClientMainScreenState extends State<ClientMainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  int _unreadChatCount = 0;
  int _unreadNotificationCount = 0;

  bool _isSyncingUnread = false;

  final Set<int> _processedAgentIds = {};
  final List<InterestedAgentModel> _matchedAgents = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateProfileImage();
      _syncUnreadChatCount();
    });
  }

  Future<void> _syncUnreadChatCount() async {
    if (_isSyncingUnread) return;

    _isSyncingUnread = true;

    try {
      final response = await ChatService.getCurrentUserChats();

      final unreadCount = response.chats.fold<int>(
        0,
        (total, chat) => total + chat.unreadCount,
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
    try {
      final profile = await ProfileService.getClientProfile();

      if (!mounted) return;

      final provider = context.read<UserProfileProvider>();
      final remoteUrl = ProfileService.resolveMediaUrl(profile.photoUrl);

      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        provider.setRemoteProfileImageUrl(remoteUrl);
      } else {
        provider.clearProfileImage();
      }
    } catch (_) {
      if (!mounted) return;
      context.read<UserProfileProvider>().clearProfileImage();
    }
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      _appBarHideProgress = 0;
    });
  }

  void _goToHome() {
    _selectTab(0);
  }

  void _goToMyOffers() {
    _selectTab(1);
  }

  void _goToCreateOffer() {
    _selectTab(2);
  }

  void _goToInterestedAgents() {
    _selectTab(3);
  }

  void _goToChats() {
    _selectTab(4);
  }

  void _handleOfferCreated() {
    setState(() {
      _offersRefreshSeed++;
      _selectedIndex = 1;
      _appBarHideProgress = 0;
    });
  }

  Future<void> _openNotifications() async {
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
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 4) {
      _syncUnreadChatCount();
    }
  }

  void _handleProcessedAgent(InterestedAgentModel agent) {
    setState(() {
      _processedAgentIds.add(agent.id);
    });
  }

  void _handleMatchedAgent(InterestedAgentModel agent) {
    final alreadyExists = _matchedAgents.any((item) => item.id == agent.id);

    if (!alreadyExists) {
      setState(() {
        _matchedAgents.insert(0, agent);
        _selectedIndex = 4;
        _appBarHideProgress = 0;
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
                color: Color(0xFF22C55E),
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

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationCenterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    const baseAppBarHeight = kToolbarHeight;

    final visibleHeight = _selectedIndex == 0
        ? baseAppBarHeight * (1 - _appBarHideProgress)
        : baseAppBarHeight;

    final visibleOpacity = _selectedIndex == 0
        ? (1 - _appBarHideProgress).clamp(0.0, 1.0)
        : 1.0;

    final screens = [
      ClientHomeScreen(
        onCreateOfferTap: () => _changeTab(2),
        onMyOffersTap: () => _changeTab(1),
        onInterestedTap: () => _changeTab(3),
        onChatsTap: () => _changeTab(4),
      ),
      CreateOfferScreen(
        onBack: () => _changeTab(0),
      ),
      InterestedAgentsScreen(
        showBackButton: false,
        hiddenAgentIds: _processedAgentIds,
        onProcessed: _handleProcessedAgent,
        onMatched: _handleMatchedAgent,
      ),
      ChatsScreen(
        matchedAgents: _matchedAgents,
        onChatStateChanged: _syncUnreadChatCount,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: OffersDrawer(
        isDarkMode: isDarkMode,
        onMyOffersTap: _goToMyOffers,
        onCreateOfferTap: _goToCreateOffer,
        onInterestedTap: _goToInterestedAgents,
        onChatsTap: _goToChats,
      ),
      appBar: OffersAppBar(
        isDarkMode: isDarkMode,
        notificationUnreadCount: _unreadNotificationCount,
        onProfileTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        onNotificationTap: _openNotifications,
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
          isChatsTabActive: _selectedIndex == 4,
          onUnreadCountChanged: (count) {
            if (!mounted || _unreadChatCount == count) return;

            setState(() {
              _unreadChatCount = count;
            });
          },
          onChatOpened: () async {
            if (!mounted) return;

            setState(() {
              _selectedIndex = 4;
            });

            await _syncUnreadChatCount();
          },
          child: IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
        ),
      ),
      bottomNavigationBar: OffersBottomBar(
        selectedIndex: _selectedIndex,
        isDarkMode: isDarkMode,
        chatUnreadCount: _unreadChatCount,
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
    _homeScrollController.removeListener(_handleHomeScroll);
    _homeScrollController.dispose();
    super.dispose();
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
        notificationUnreadCount: 0,
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