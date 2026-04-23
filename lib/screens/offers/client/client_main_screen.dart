import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../auth/client/client_profile_screen.dart';
import '../../chats/chat_conversation_screen.dart';
import '../../chats/chats_screen.dart';
import '../../notifications/notification_center_screen.dart';
import '../../../conf/theme_provider.dart';
import '../../../data/mock_client_data.dart';
import '../../../data/mock_notification_data.dart';
import '../../../data/mock_chat_data.dart';
import '../../../models/interested_agent_model.dart';
import 'client_home_screen.dart';
import 'interested_agents_screen.dart';
import 'create_offer_screen.dart';
import 'my_offers_screen.dart';
import '../widgets/offers_app_bar.dart';
import '../widgets/offers_bottom_bar.dart';
import '../widgets/offers_drawer.dart';

class ClientEntryScreen extends StatelessWidget {
  const ClientEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!MockClientData.isProfileCompleted) {
      return const ClientProfileCompletionScreen();
    }

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
  final Set<int> _processedAgentIds = {};
  final List<InterestedAgentModel> _matchedAgents = [];

  bool get _hasUnreadChats {
    return _matchedAgents.any(
      (agent) => MockChatData.getUnreadCountForAgent(agent.id) > 0,
    );
  }

  void _handleProcessedAgent(InterestedAgentModel agent) {
    setState(() {
      _processedAgentIds.add(agent.id);
    });
  }

  void _handleMatchedAgent(InterestedAgentModel agent) {
    final alreadyExists = _matchedAgents.any((item) => item.id == agent.id);

    if (alreadyExists) return;

    setState(() {
      _matchedAgents.insert(0, agent);
    });
  }

  void _openMatchedChat(InterestedAgentModel agent) {
    final alreadyExists = _matchedAgents.any((item) => item.id == agent.id);

    if (!alreadyExists) {
      setState(() {
        _matchedAgents.insert(0, agent);
      });
    }

    setState(() {
      _selectedIndex = 4;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(agent: agent),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationCenterScreen(),
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    final screens = [
      ClientHomeScreen(
        onCreateOfferTap: () => setState(() => _selectedIndex = 2),
        onMyOffersTap: () => setState(() => _selectedIndex = 1),
        onInterestedTap: () => setState(() => _selectedIndex = 3),
        onChatsTap: () => setState(() => _selectedIndex = 4),
      ),
      const MyOffersScreen(),
      CreateOfferScreen(
        onBack: () => setState(() => _selectedIndex = 0),
      ),
      InterestedAgentsScreen(
        showBackButton: false,
        hiddenAgentIds: _processedAgentIds,
        onProcessed: _handleProcessedAgent,
        onMatched: _handleMatchedAgent,
        onStartChatting: _openMatchedChat,
      ),
      ChatsScreen(
        matchedAgents: _matchedAgents,
        onChatStateChanged: () {
          if (!mounted) return;
          setState(() {});
        },
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: OffersDrawer(
        isDarkMode: isDarkMode,
        fallbackAssetPath: 'assets/images/Profil.jpg',
      ),
      appBar: OffersAppBar(
        isDarkMode: isDarkMode,
        fallbackAssetPath: 'assets/images/Profil.jpg',
        onProfileTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        onNotificationTap: _openNotifications,
        showNotificationDot: MockNotificationData.hasUnread,
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: OffersBottomBar(
        selectedIndex: _selectedIndex,
        isDarkMode: isDarkMode,
        onHomeTap: () => setState(() => _selectedIndex = 0),
        onOffersTap: () => setState(() => _selectedIndex = 1),
        onAddTap: () => setState(() => _selectedIndex = 2),
        onInterestedTap: () => setState(() => _selectedIndex = 3),
        onChatsTap: () => setState(() => _selectedIndex = 4),
        showChatsDot: _hasUnreadChats,
      ),
    );
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
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black.withOpacity(0.7),
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
                        ? Colors.white.withOpacity(0.68)
                        : Colors.black.withOpacity(0.68),
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