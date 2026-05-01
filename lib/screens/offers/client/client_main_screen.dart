import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../conf/user_profile_provider.dart';
import '../../../conf/theme_provider.dart';
import '../../../data/mock_client_data.dart';
import '../../../models/interested_agent_model.dart';
import '../../../services/profile_service.dart';
import '../../auth/client/client_profile_screen.dart';
import 'client_home_screen.dart';
import 'interested_agents_screen.dart';
import '../../chats/chats_screen.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateProfileImage();
    });
  }

  Future<void> _hydrateProfileImage() async {
    try {
      final profile = await ProfileService.getClientProfile();
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
      });

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
    }
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
      ),
      ChatsScreen(
        matchedAgents: _matchedAgents,
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
        onProfileTap: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        onNotificationTap: () {},
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