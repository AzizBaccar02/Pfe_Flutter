import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../conf/theme_provider.dart';
import '../../../data/mock_client_data.dart';
import '../widgets/home_empty_card.dart';
import '../widgets/home_recent_offer_card.dart';
import '../widgets/home_section_title.dart';
import '../widgets/home_stat_card.dart';
import '../widgets/home_interested_agent_card.dart';
import '../widgets/home_hero_card.dart';

class ClientHomeScreen extends StatelessWidget {
  final VoidCallback onCreateOfferTap;
  final VoidCallback onMyOffersTap;
  final VoidCallback onInterestedTap;
  final VoidCallback onChatsTap;

  const ClientHomeScreen({
    super.key,
    required this.onCreateOfferTap,
    required this.onMyOffersTap,
    required this.onInterestedTap,
    required this.onChatsTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    final recentOffers = MockClientData.offers.take(2).toList();
    final interestedAgents = MockClientData.interestedAgents.take(2).toList();

    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeHeroCard(
              isDarkMode: isDarkMode,
              clientName: MockClientData.clientName,
              onCreateOfferTap: onCreateOfferTap,
            ),
            const SizedBox(height: 20),
            HomeSectionTitle(
              title: 'Overview',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: HomeStatCard(
                    title: 'Total Offers',
                    value: MockClientData.totalOffers.toString(),
                    icon: HugeIcons.strokeRoundedWork,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HomeStatCard(
                    title: 'Open Offers',
                    value: MockClientData.openOffers.toString(),
                    icon: HugeIcons.strokeRoundedTaskDone01,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: HomeStatCard(
                    title: 'Interested',
                    value: MockClientData.totalInterestedAgents.toString(),
                    icon: HugeIcons.strokeRoundedFavourite,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HomeStatCard(
                    title: 'Closed Offers',
                    value: MockClientData.closedOffers.toString(),
                    icon: HugeIcons.strokeRoundedArchive,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            HomeSectionTitle(
              title: 'Recent Offers',
              actionText: 'See all',
              onActionTap: onMyOffersTap,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            if (recentOffers.isEmpty)
              HomeEmptyCard(
                text: 'You have not created any offers yet.',
                isDarkMode: isDarkMode,
              )
            else
              SizedBox(
                height: 360,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentOffers.length,
                  itemBuilder: (context, index) {
                    final offer = recentOffers[index];
                    return HomeRecentOfferCard(
                      offer: offer,
                      isDarkMode: isDarkMode,
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            HomeSectionTitle(
              title: 'Interested Agents',
              actionText: 'See all',
              onActionTap: onInterestedTap,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            if (interestedAgents.isEmpty)
              HomeEmptyCard(
                text: 'No agents have shown interest yet.',
                isDarkMode: isDarkMode,
              )
            else
              ...interestedAgents.map(
                (agent) => HomeInterestedAgentCard(
                  agentName: agent.name,
                  jobTitle: agent.jobTitle,
                  offerTitle: agent.offerTitle,
                  imagePath: agent.imageUrl,
                  isDarkMode: isDarkMode,
                ),
              ),
          ],
        ),
      ),
    );
  }
}