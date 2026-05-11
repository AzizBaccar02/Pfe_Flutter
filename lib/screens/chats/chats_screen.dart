// lib/screens/chats/chats_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../conf/theme_provider.dart';
import '../../models/chat_conversation_summary_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import 'chat_conversation_screen.dart';
import 'widgets/chat_match_avatar.dart';
import 'widgets/chat_tile.dart';

class ChatsScreen extends StatefulWidget {
  final List<dynamic>? matchedAgents;
  final VoidCallback? onChatStateChanged;

  const ChatsScreen({
    super.key,
    this.matchedAgents,
    this.onChatStateChanged,
  });

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isRefreshingSilently = false;
  String? _errorMessage;

  int _currentUserId = 0;
  List<ChatConversationSummaryModel> _chats = [];

  int get _totalUnreadCount => _sumUnread(_chats);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrapChats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshChatsSilently();
    }
  }

  Future<void> _bootstrapChats() async {
    final storedUserId = await AuthService.getStoredUserId();

    if (!mounted) return;

    setState(() {
      _currentUserId = storedUserId ?? 0;
    });

    await _loadChats();
  }

  Future<void> _loadChats({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ChatService.getCurrentUserChats();

      if (!mounted) return;

      setState(() {
        _chats = _sortChats(response.chats);
        _errorMessage = null;
      });
    } on ChatServiceException catch (e) {
      if (!mounted) return;

      if (showLoading) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (_) {
      if (!mounted) return;

      if (showLoading) {
        setState(() {
          _errorMessage = 'Unable to load chats. Please try again.';
        });
      }
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshChatsSilently() async {
    if (_isLoading || _isRefreshingSilently) return;

    _isRefreshingSilently = true;

    try {
      final previousUnreadCount = _totalUnreadCount;
      final response = await ChatService.getCurrentUserChats();

      if (!mounted) return;

      final sortedChats = _sortChats(response.chats);
      final nextUnreadCount = _sumUnread(sortedChats);

      setState(() {
        _chats = sortedChats;
        _errorMessage = null;
      });

      if (previousUnreadCount != nextUnreadCount) {
        widget.onChatStateChanged?.call();
      }
    } catch (_) {
      // Silent refresh should never disturb the UI.
    } finally {
      _isRefreshingSilently = false;
    }
  }

  List<ChatConversationSummaryModel> _sortChats(
    List<ChatConversationSummaryModel> chats,
  ) {
    final sortedChats = [...chats];

    sortedChats.sort((a, b) {
      final aDate = a.lastActivityDate;
      final bDate = b.lastActivityDate;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });

    return sortedChats;
  }

  Future<void> _openConversation(ChatConversationSummaryModel chat) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationScreen(chat: chat),
      ),
    );

    if (!mounted) return;

    await _loadChats(showLoading: false);
    widget.onChatStateChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    const accentGreen = Color(0xFF22C55E);

    final backgroundColor =
        isDarkMode ? const Color(0xFF0B0F14) : const Color(0xFFF3F4F6);

    final cardColor =
        isDarkMode ? const Color(0xFF111827) : Colors.white;

    final softColor =
        isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

    final primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF111827);

    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.56);

    return Container(
      color: backgroundColor,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: accentGreen,
                strokeWidth: 2.4,
              ),
            )
          : _errorMessage != null
              ? _ChatsErrorState(
                  message: _errorMessage!,
                  cardColor: cardColor,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  onRetry: () => _loadChats(),
                )
              : _chats.isEmpty
                  ? _EmptyChatsState(
                      cardColor: cardColor,
                      softColor: softColor,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    )
                  : RefreshIndicator(
                      color: accentGreen,
                      onRefresh: () => _loadChats(showLoading: false),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                        children: [
                          _ChatsHeader(
                            totalChats: _chats.length,
                            unreadCount: _totalUnreadCount,
                            isDarkMode: isDarkMode,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                          const SizedBox(height: 24),
                          _SectionTitle(
                            title: 'Active Offers',
                            count: _chats.length,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 122,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _chats.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final chat = _chats[index];

                                return ChatMatchAvatar(
                                  chat: chat,
                                  primaryTextColor: primaryTextColor,
                                  hasUnread: chat.unreadCount > 0,
                                  onTap: () => _openConversation(chat),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 28),
                          _SectionTitle(
                            title: 'Messages',
                            count: _chats.length,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                          const SizedBox(height: 12),
                          ..._chats.map((chat) {
                            return ChatTile(
                              chat: chat,
                              currentUserId: _currentUserId,
                              trailingText:
                                  _formatTrailingTime(chat.lastActivityDate),
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                              onTap: () => _openConversation(chat),
                            );
                          }),
                        ],
                      ),
                    ),
    );
  }

  static int _sumUnread(List<ChatConversationSummaryModel> chats) {
    return chats.fold<int>(
      0,
      (total, chat) => total + chat.unreadCount,
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

class _ChatsHeader extends StatelessWidget {
  final int totalChats;
  final int unreadCount;
  final bool isDarkMode;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const _ChatsHeader({
    required this.totalChats,
    required this.unreadCount,
    required this.isDarkMode,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.18 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accentGreen.withOpacity(isDarkMode ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedMessage02,
                color: accentGreen,
                size: 25,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chats',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unreadCount > 0
                      ? '$unreadCount unread message${unreadCount == 1 ? '' : 's'} waiting'
                      : '$totalChats active conversation${totalChats == 1 ? '' : 's'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Container(
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: const BoxDecoration(
                color: accentGreen,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const _SectionTitle({
    required this.title,
    required this.count,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF22C55E);

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: accentGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: accentGreen.withOpacity(0.20),
            ),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.82)
                  : const Color(0xFF166534),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Spacer(),
        Text(
          title == 'Messages' ? 'Latest first' : 'By offer',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ChatsErrorState extends StatelessWidget {
  final String message;
  final Color cardColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Future<void> Function() onRetry;

  const _ChatsErrorState({
    required this.message,
    required this.cardColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF22C55E);

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
              const HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                color: Colors.redAccent,
                size: 34,
              ),
              const SizedBox(height: 18),
              Text(
                'Could not load chats',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Try again',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    const accentGreen = Color(0xFF22C55E);

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
                  color: accentGreen.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedMessage02,
                    color: accentGreen,
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
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'When a client accepts an interested agent, the conversation will appear here.',
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