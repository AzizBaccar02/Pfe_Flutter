import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../conf/theme_provider.dart';
import '../../data/mock_chat_data.dart';
import '../../models/interested_agent_model.dart';
import 'chat_conversation_screen.dart';
import 'widgets/chat_match_avatar.dart';
import 'widgets/chat_tile.dart';

class ChatsScreen extends StatefulWidget {
  final List<InterestedAgentModel> matchedAgents;
  final VoidCallback? onChatStateChanged;

  const ChatsScreen({
    super.key,
    required this.matchedAgents,
    this.onChatStateChanged,
  });

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  Future<void> _openConversation(InterestedAgentModel agent) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(agent: agent),
      ),
    );

    if (!mounted) return;
    setState(() {});
    widget.onChatStateChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    const accentYellow = Color(0xFFFFC107);

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF151515) : const Color(0xFFF6F6F6);
    final softColor =
        isDarkMode ? const Color(0xFF232323) : const Color(0xFFEDEDED);
    final dividerColor = isDarkMode
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.68)
        : Colors.black.withOpacity(0.62);

    final neutralAccentText = isDarkMode
        ? Colors.white.withOpacity(0.82)
        : Colors.black.withOpacity(0.82);

    final sortedAgents = [...widget.matchedAgents]
      ..sort((a, b) {
        final aDate = MockChatData.getLastMessageForAgent(a.id)?.sentAt;
        final bDate = MockChatData.getLastMessageForAgent(b.id)?.sentAt;

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

    return Container(
      color: backgroundColor,
      child: widget.matchedAgents.isEmpty
          ? _EmptyChatsState(
              cardColor: cardColor,
              softColor: softColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                Text(
                  'Chats',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your matches and active conversations in one place.',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'New Matches',
                      style: TextStyle(
                        color: neutralAccentText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentYellow.withOpacity(isDarkMode ? 0.14 : 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: accentYellow.withOpacity(isDarkMode ? 0.22 : 0.28),
                        ),
                      ),
                      child: Text(
                        '${widget.matchedAgents.length}',
                        style: TextStyle(
                          color: neutralAccentText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 108,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.matchedAgents.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final agent = widget.matchedAgents[index];
                      final unreadCount =
                          MockChatData.getUnreadCountForAgent(agent.id);

                      return ChatMatchAvatar(
                        agent: agent,
                        primaryTextColor: primaryTextColor,
                        hasUnread: unreadCount > 0,
                        onTap: () => _openConversation(agent),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Text(
                      'Messages',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${sortedAgents.length} conversations',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...sortedAgents.map((agent) {
                  final lastMessage =
                      MockChatData.getLastMessageForAgent(agent.id);
                  final unreadCount =
                      MockChatData.getUnreadCountForAgent(agent.id);

                  final previewText = lastMessage?.text ??
                      'You matched with ${agent.name.split(' ').first}. Start the conversation now.';
                  final trailingText = _formatTrailingTime(lastMessage?.sentAt);

                  return ChatTile(
                    agent: agent,
                    previewText: previewText,
                    trailingText: trailingText,
                    offerTitle: agent.offerTitle,
                    unreadCount: unreadCount,
                    dividerColor: dividerColor,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    onTap: () => _openConversation(agent),
                  );
                }),
              ],
            ),
    );
  }

  static String _formatTrailingTime(DateTime? date) {
    if (date == null) return 'New';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    return '${date.day}/${date.month}';
  }
}

class _EmptyChatsState extends StatelessWidget {
  final Color cardColor;
  final Color softColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const _EmptyChatsState({
    required this.cardColor,
    required this.softColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    const accentYellow = Color(0xFFFFC107);

    final neutralIconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.78)
        : Colors.black.withOpacity(0.78);

    return Center(
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
                  color: accentYellow.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedMessage02,
                    color: neutralIconColor,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'No chats yet',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'When you accept an interested agent, your match will appear here and the conversation can begin.',
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
    );
  }
}