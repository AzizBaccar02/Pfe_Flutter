// lib/screens/chats/chats_screen.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../conf/theme_provider.dart';
import '../../models/chat_conversation_summary_model.dart';
import '../../models/chat_message_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_conversation_display_name_service.dart';
import '../../services/chat_local_read_cursor.dart';
import '../../services/app_realtime_coordinator.dart';
import '../../services/chat_realtime_hub.dart';
import '../../services/chat_service.dart';
import '../../utils/chat_unread_merge.dart';
import 'archived_chats_screen.dart';
import 'chat_conversation_screen.dart';
import 'widgets/chat_match_avatar.dart';
import 'widgets/chat_tile.dart';

class ChatsScreen extends StatefulWidget {
  final List<dynamic>? matchedAgents;
  final VoidCallback? onChatStateChanged;
  /// When false, the chats tab is hidden (IndexedStack); still refresh when true.
  final bool isTabActive;

  const ChatsScreen({
    super.key,
    this.matchedAgents,
    this.onChatStateChanged,
    this.isTabActive = true,
  });

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with WidgetsBindingObserver {
  static const String _archivedChatIdsPrefsKey = 'chat_archived_ids_v1';
  static const Duration _listPollInterval = Duration(seconds: 6);

  bool _isLoading = true;
  bool _isRefreshingSilently = false;
  String? _errorMessage;

  int _currentUserId = 0;
  String _viewerRole = '';
  List<ChatConversationSummaryModel> _chats = [];
  Set<int> _archivedChatIds = {};

  StreamSubscription<Map<String, dynamic>>? _inboxHubSubscription;
  StreamSubscription<void>? _coordinatorSubscription;
  Timer? _listPollTimer;

  final TextEditingController _searchController = TextEditingController();

  int get _totalUnreadCount => _sumUnreadForViewer(_chats);

  List<ChatConversationSummaryModel> get _orderedActiveChats {
    return _chats.where((c) => !_archivedChatIds.contains(c.id)).toList();
  }

  /// Active Offers carousel — never filtered by the Discussions search field.
  List<ChatConversationSummaryModel> get _activeOffersChats =>
      _orderedActiveChats;

  String get _searchQuery => _searchController.text.trim().toLowerCase();

  bool _chatMatchesSearch(ChatConversationSummaryModel chat, String query) {
    final title = ChatConversationDisplayNameService.instance
        .resolve(chat.id, chat.displayName)
        .toLowerCase();
    return title.contains(query) ||
        chat.offerTitle.toLowerCase().contains(query) ||
        chat.previewText.toLowerCase().contains(query);
  }

  /// Discussions list only — filtered when the search field has text.
  List<ChatConversationSummaryModel> get _filteredDiscussionChats {
    final q = _searchQuery;
    final base = _orderedActiveChats;
    if (q.isEmpty) return base;
    return base.where((c) => _chatMatchesSearch(c, q)).toList();
  }

  bool get _isSearchingDiscussions => _searchQuery.isNotEmpty;

  bool get _hasNoDiscussionSearchResults =>
      _isSearchingDiscussions && _filteredDiscussionChats.isEmpty;

  Future<Set<int>> _readArchivedChatIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_archivedChatIdsPrefsKey);
    if (raw == null || raw.trim().isEmpty) return {};
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .where((id) => id > 0)
        .toSet();
  }

  Future<void> _writeArchivedChatIds(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    if (ids.isEmpty) {
      await prefs.remove(_archivedChatIdsPrefsKey);
    } else {
      await prefs.setString(_archivedChatIdsPrefsKey, ids.join(','));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(_onSearchChanged);
    _bootstrapChats();
    _startListPolling();
    AppRealtimeCoordinator.instance.ensureStarted();
    _coordinatorSubscription =
        AppRealtimeCoordinator.instance.onRefresh.listen((_) {
      if (!mounted || !widget.isTabActive) return;
      _refreshChatsSilently();
    });
  }

  @override
  void didUpdateWidget(covariant ChatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isTabActive && !oldWidget.isTabActive) {
      _refreshChatsSilently();
      _startListPolling();
    } else if (!widget.isTabActive && oldWidget.isTabActive) {
      _listPollTimer?.cancel();
      _listPollTimer = null;
    }
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _startListPolling() {
    if (!widget.isTabActive) return;

    _listPollTimer?.cancel();
    _listPollTimer = Timer.periodic(_listPollInterval, (_) {
      if (!mounted || !widget.isTabActive) return;
      _refreshChatsSilently();
    });
  }

  @override
  void dispose() {
    _listPollTimer?.cancel();
    _coordinatorSubscription?.cancel();
    _inboxHubSubscription?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshChatsSilently();
      unawaited(ChatRealtimeHub.instance.ensureStarted());
      _startListPolling();
    } else if (state == AppLifecycleState.paused) {
      _listPollTimer?.cancel();
      _listPollTimer = null;
    }
  }

  Future<void> _bootstrapChats() async {
    final storedUserId = await AuthService.getStoredUserId();
    final storedRole = await AuthService.getStoredRole();
    final archivedIds = await _readArchivedChatIds();

    await ChatConversationDisplayNameService.instance.ensureLoaded();
    await ChatLocalReadCursor.instance.ensureLoaded();

    if (!mounted) return;

    setState(() {
      _currentUserId = storedUserId ?? 0;
      _viewerRole = (storedRole ?? '').toUpperCase();
      _archivedChatIds = archivedIds;
    });

    await _loadChats();
    if (mounted) {
      await _subscribeToInboxHub();
    }
  }

  Future<void> _subscribeToInboxHub() async {
    await ChatRealtimeHub.instance.ensureStarted();

    await _inboxHubSubscription?.cancel();
    _inboxHubSubscription = ChatRealtimeHub.instance.onInboxEvent.listen(
      _onUserChatsInboxEvent,
    );
  }

  void _onUserChatsInboxEvent(dynamic raw) {
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) return;

      final data = Map<String, dynamic>.from(decoded);
      final type = data['type']?.toString() ?? '';

      if (type == 'presence_update') {
        final uid = int.tryParse(data['user_id']?.toString() ?? '');
        if (uid == null || uid <= 0) return;
        if (uid == _currentUserId) return;

        final rawOnline = data['is_online'];
        final bool online;
        if (rawOnline is bool) {
          online = rawOnline;
        } else {
          final s = rawOnline?.toString().trim().toLowerCase() ?? '';
          if (s == 'true' || s == '1' || s == 'yes') {
            online = true;
          } else if (s == 'false' || s == '0' || s == 'no') {
            online = false;
          } else {
            return;
          }
        }

        if (!mounted) return;
        setState(() {
          _chats = _chats
              .map(
                (c) => c.withUserOnlineState(userId: uid, isOnline: online),
              )
              .toList();
        });
        return;
      }

      if (type == 'chat_list_updated' ||
          type == 'chat_updated' ||
          type == 'chat_summary_updated') {
        _refreshChatsSilently();
        return;
      }

      if (type == 'new_message' ||
          type == 'message_created' ||
          type == 'chat_message') {
        _handleInboxNewMessage(data);
        return;
      }

      if (type == 'message_seen' || type == 'messages_seen') {
        _handleInboxReadReceipt(data);
        return;
      }
    } catch (_) {
      // Ignore malformed inbox payloads.
    }
  }

  void _handleInboxReadReceipt(Map<String, dynamic> data) {
    final chatId = _parseInboxInt(data['chat_id']) ??
        _parseInboxInt(data['chatId']) ??
        (data['chat'] is Map ? _parseInboxInt((data['chat'] as Map)['id']) : null);

    if (chatId == null || chatId <= 0) {
      _refreshChatsSilently();
      return;
    }

    final index = _chats.indexWhere((chat) => chat.id == chatId);
    if (index < 0) {
      _refreshChatsSilently();
      return;
    }

    final readerId = _parseInboxInt(data['reader_id']) ??
        _parseInboxInt(data['readerId']);
    if (readerId != null && readerId == _currentUserId) {
      return;
    }

    if (readerId != null && !_readerIsPeerForChat(_chats[index], readerId)) {
      return;
    }

    final chat = _chats[index];
    final last = chat.lastMessage;
    if (last == null || !chat.isLastMessageFromViewer(_currentUserId)) {
      _refreshChatsSilently();
      return;
    }

    final messageId = _parseInboxInt(data['message_id']) ??
        _parseInboxInt(data['messageId']);
    if (messageId != null && messageId != last.id) {
      _refreshChatsSilently();
      return;
    }

    if (last.isRead) return;

    final updatedLast = ChatLastMessageSummary(
      id: last.id,
      content: last.content,
      senderId: last.senderId,
      isRead: true,
      sentAt: last.sentAt,
    );

    final merged = ChatUnreadMerge.mergeInboxRow(
      chat: chat,
      lastMessage: updatedLast,
      viewerUserId: _currentUserId,
    );

    if (!mounted) return;

    setState(() {
      final next = [..._chats];
      next[index] = merged;
      _chats = _sortChats(next);
    });
    widget.onChatStateChanged?.call();
  }

  bool _readerIsPeerForChat(ChatConversationSummaryModel chat, int readerId) {
    if (readerId <= 0) return false;
    if (readerId == _currentUserId) return false;

    for (final user in [chat.otherUser, chat.client, chat.agent]) {
      if (user == null) continue;
      if (user.id > 0 && readerId == user.id) return true;
      final uid = user.userId;
      if (uid != null && uid > 0 && readerId == uid) return true;
    }

    return false;
  }

  void _handleInboxNewMessage(Map<String, dynamic> data) {
    final rawChat = data['chat'];
    if (rawChat is Map) {
      try {
        final summary = ChatConversationSummaryModel.fromJson(
          Map<String, dynamic>.from(rawChat),
        );
        if (summary.id > 0) {
          _mergeChatSummary(summary);
          widget.onChatStateChanged?.call();
          return;
        }
      } catch (_) {
        // Fall through to message-level merge.
      }
    }

    final chatId = _parseInboxInt(data['chat_id']) ??
        _parseInboxInt(data['chatId']) ??
        (rawChat is Map ? _parseInboxInt(rawChat['id']) : null);

    final rawMessage = data['message'];
    if (chatId == null || chatId <= 0) {
      _refreshChatsSilently();
      return;
    }

    if (rawMessage is! Map) {
      final serverUnread = _parseInboxInt(data['unread_count']) ??
          _parseInboxInt(data['unreadCount']);
      if (serverUnread != null) {
        final index = _chats.indexWhere((chat) => chat.id == chatId);
        if (index >= 0) {
          final merged = ChatUnreadMerge.mergeChat(
            server: _chats[index].copyWith(unreadCount: serverUnread),
            previous: _chats[index],
            viewerUserId: _currentUserId,
          );
          setState(() {
            final next = [..._chats];
            next[index] = merged;
            _chats = _sortChats(next);
          });
        }
        widget.onChatStateChanged?.call();
        return;
      }
      _refreshChatsSilently();
      return;
    }

    final index = _chats.indexWhere((chat) => chat.id == chatId);
    if (index < 0) {
      _refreshChatsSilently();
      return;
    }

    final chat = _chats[index];
    final messageJson = Map<String, dynamic>.from(rawMessage);

    final message = ChatMessageModel.fromJson(
      json: messageJson,
      clientId: chat.client?.id ?? 0,
      agentId: chat.agent?.id ?? 0,
      clientUserId: chat.client?.userId,
      agentUserId: chat.agent?.userId,
    );

    final isIncoming = !_senderIsViewer(message.senderId, chat);

    final lastSummary = ChatLastMessageSummary(
      id: message.id,
      content: message.text,
      senderId: message.senderId,
      isRead: isIncoming ? false : message.isRead,
      sentAt: message.sentAt,
    );

    final merged = ChatUnreadMerge.mergeInboxRow(
      chat: chat,
      lastMessage: lastSummary,
      viewerUserId: _currentUserId,
    );

    if (!mounted) return;

    setState(() {
      final nextChats = [..._chats];
      nextChats[index] = merged;
      _chats = _sortChats(nextChats);
    });

    widget.onChatStateChanged?.call();
  }

  void _mergeChatSummary(ChatConversationSummaryModel summary) {
    if (!mounted) return;

    final index = _chats.indexWhere((c) => c.id == summary.id);
    final previous = index >= 0 ? _chats[index] : null;
    final merged = ChatUnreadMerge.mergeChat(
      server: summary,
      previous: previous,
      viewerUserId: _currentUserId,
    );

    setState(() {
      if (index >= 0) {
        final next = [..._chats];
        next[index] = merged;
        _chats = _sortChats(next);
      } else {
        _chats = _sortChats([..._chats, merged]);
      }
    });
  }

  int? _parseInboxInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  bool _senderIsViewer(int senderId, ChatConversationSummaryModel chat) {
    if (senderId <= 0 || _currentUserId <= 0) return false;
    if (senderId == _currentUserId) return true;

    final client = chat.client;
    if (client != null) {
      if (senderId == client.id) return true;
      final uid = client.userId;
      if (uid != null && uid > 0 && senderId == uid) return true;
    }

    final agent = chat.agent;
    if (agent != null) {
      if (senderId == agent.id) return true;
      final uid = agent.userId;
      if (uid != null && uid > 0 && senderId == uid) return true;
    }

    return false;
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

      final merged = ChatUnreadMerge.mergeLists(
        serverChats: response.chats,
        previousChats: _chats,
        viewerUserId: _currentUserId,
      );
      final sorted = _sortChats(merged);
      final validIds = sorted.map((c) => c.id).toSet();
      final previousArchived = _archivedChatIds;
      final prunedArchived =
          previousArchived.where((id) => validIds.contains(id)).toSet();

      final role = response.currentUserRole.trim();
      setState(() {
        _chats = sorted;
        _archivedChatIds = prunedArchived;
        _errorMessage = null;
        if (role.isNotEmpty) {
          _viewerRole = role.toUpperCase();
        }
      });

      if (prunedArchived.length != previousArchived.length) {
        await _writeArchivedChatIds(prunedArchived);
      }
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

      final merged = ChatUnreadMerge.mergeLists(
        serverChats: response.chats,
        previousChats: _chats,
        viewerUserId: _currentUserId,
      );
      final sortedChats = _sortChats(merged);
      final validIds = sortedChats.map((c) => c.id).toSet();
      final previousArchived = _archivedChatIds;
      final prunedArchived =
          previousArchived.where((id) => validIds.contains(id)).toSet();
      final nextUnreadCount = _sumUnreadForViewer(sortedChats);
      final role = response.currentUserRole.trim();

      setState(() {
        _chats = sortedChats;
        _archivedChatIds = prunedArchived;
        _errorMessage = null;
        if (role.isNotEmpty) {
          _viewerRole = role.toUpperCase();
        }
      });

      if (prunedArchived.length != previousArchived.length) {
        await _writeArchivedChatIds(prunedArchived);
      }

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

    ChatUnreadMerge.trustServerUnreadForChat(chat.id);
    await _loadChats(showLoading: false);
    widget.onChatStateChanged?.call();
  }

  Future<void> _confirmCloseOffer(ChatConversationSummaryModel chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close offer'),
        content: Text(
          'Close "${chat.offerTitle}"? Agents will no longer be able to '
          'react to this offer. The conversation stays in your list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC9A227),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close offer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ChatService.closeChatOffer(chatId: chat.id);

      if (!mounted) return;

      await _loadChats(showLoading: false);
      widget.onChatStateChanged?.call();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${chat.offerTitle}" closed'),
          behavior: SnackBarBehavior.floating,
        ),
      );

    } on ChatServiceException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to close offer.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeleteChat(ChatConversationSummaryModel chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete conversation'),
        content: Text(
          'Remove "${chat.displayName}" from your list only? '
          'The other user will still have this conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final result = await ChatService.deleteChat(chatId: chat.id);

      if (!mounted) return;

      if (!result.deletedForSelfOnly) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This conversation could not be removed from your side only.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        _chats = _chats.where((item) => item.id != result.chatId).toList();
        _archivedChatIds = {..._archivedChatIds}..remove(chat.id);
      });

      await _writeArchivedChatIds(_archivedChatIds);
      widget.onChatStateChanged?.call();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${chat.displayName} deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ChatServiceException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete conversation.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _archiveChat(ChatConversationSummaryModel chat) async {
    if (chat.id <= 0) return;

    final next = {..._archivedChatIds, chat.id};
    setState(() => _archivedChatIds = next);
    await _writeArchivedChatIds(next);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${chat.displayName} archived'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _unarchiveChat(ChatConversationSummaryModel chat) async {
    if (chat.id <= 0) return;

    final next = {..._archivedChatIds}..remove(chat.id);
    setState(() => _archivedChatIds = next);
    await _writeArchivedChatIds(next);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${chat.displayName} moved back to Discussions'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openArchivedInbox({
    required Color backgroundColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    final archived = _sortChats(
      _chats.where((c) => _archivedChatIds.contains(c.id)).toList(),
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => ArchivedChatsScreen(
          chats: archived,
          currentUserId: _currentUserId,
          viewerRole: _viewerRole,
          backgroundColor: backgroundColor,
          primaryTextColor: primaryTextColor,
          secondaryTextColor: secondaryTextColor,
          formatTrailingTime: _ChatsScreenState._formatTrailingTime,
          conversationTitleFor: (c) =>
              ChatConversationDisplayNameService.instance
                  .resolve(c.id, c.displayName),
          onOpenConversation: (chat) async {
            Navigator.pop(ctx);
            await Future<void>.delayed(Duration.zero);
            if (!mounted) return;
            await _openConversation(chat);
          },
          onCloseOffer: _confirmCloseOffer,
          onDeleteChat: _confirmDeleteChat,
          onUnarchive: _unarchiveChat,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    const accentGreen = AppColors.accent;

    final backgroundColor =
        isDarkMode ? const Color(0xFF000000) : Colors.white;

    final cardColor =
        isDarkMode ? const Color(0xFF111827) : Colors.white;

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
                      isDarkMode: isDarkMode,
                      viewerRole: _viewerRole,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    )
                  : RefreshIndicator(
                      color: accentGreen,
                      onRefresh: () => _loadChats(showLoading: false),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                        children: [
                          _ActiveOffersHeader(
                            count: _activeOffersChats.length,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            accentColor: accentGreen,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: ChatMatchAvatar.listHeight,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _activeOffersChats.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final chat = _activeOffersChats[index];

                                return ChatMatchAvatar(
                                  chat: chat,
                                  currentUserId: _currentUserId,
                                  viewerRole: _viewerRole,
                                  matchedAgents: widget.matchedAgents,
                                  primaryTextColor: primaryTextColor,
                                  secondaryTextColor: secondaryTextColor,
                                  onTap: () => _openConversation(chat),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 28),
                          _DiscussionsTitle(
                            primaryTextColor: primaryTextColor,
                          ),
                          const SizedBox(height: 14),
                          _ChatsSearchBar(
                            controller: _searchController,
                            isDarkMode: isDarkMode,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                          const SizedBox(height: 12),
                          _ArchivedRow(
                            archivedCount: _archivedChatIds.length,
                            primaryTextColor: primaryTextColor,
                            secondaryTextColor: secondaryTextColor,
                            onTap: () => _openArchivedInbox(
                              backgroundColor: backgroundColor,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_hasNoDiscussionSearchResults)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 28,
                                horizontal: 8,
                              ),
                              child: Text(
                                'No results',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            ..._filteredDiscussionChats.map((chat) {
                              return ChatTile(
                                chat: chat,
                                currentUserId: _currentUserId,
                                viewerRole: _viewerRole,
                                matchedAgents: widget.matchedAgents,
                                conversationTitle:
                                    ChatConversationDisplayNameService
                                        .instance
                                        .resolve(chat.id, chat.displayName),
                                trailingText: _formatTrailingTime(
                                  chat.lastActivityDate,
                                ),
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                                onTap: () => _openConversation(chat),
                                onCloseOffer: () => _confirmCloseOffer(chat),
                                onDeleteChat: () => _confirmDeleteChat(chat),
                                onArchiveChat: () => _archiveChat(chat),
                              );
                            }),
                        ],
                      ),
                    ),
    );
  }

  int _sumUnreadForViewer(List<ChatConversationSummaryModel> chats) {
    final cursor = ChatLocalReadCursor.instance;

    return chats.fold<int>(
      0,
      (total, chat) =>
          total + cursor.displayUnreadCount(chat, _currentUserId),
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

class _DiscussionsTitle extends StatelessWidget {
  final Color primaryTextColor;

  const _DiscussionsTitle({
    required this.primaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Discussions',
      style: TextStyle(
        color: primaryTextColor,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.9,
      ),
    );
  }
}

class _ChatsSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDarkMode;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const _ChatsSearchBar({
    required this.controller,
    required this.isDarkMode,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final fill = isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8);
    final border = isDarkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: secondaryTextColor,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchivedRow extends StatelessWidget {
  final int archivedCount;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;

  const _ArchivedRow({
    required this.archivedCount,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: secondaryTextColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                'Archived',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (archivedCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: secondaryTextColor.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$archivedCount',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (archivedCount > 0) const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: secondaryTextColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveOffersHeader extends StatelessWidget {
  final int count;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;

  const _ActiveOffersHeader({
    required this.count,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Active offers',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            height: 1.2,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 6),
          _CompactCountBadge(
            count: count,
            accentColor: accentColor,
          ),
        ],
        const Spacer(),
        Text(
          'Tap to open chat',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Small count pill beside section titles (not a large circle).
class _CompactCountBadge extends StatelessWidget {
  final int count;
  final Color accentColor;

  const _CompactCountBadge({
    required this.count,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';

    return Container(
      height: 16,
      constraints: BoxConstraints(
        minWidth: label.length > 1 ? 20 : 16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accentColor,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
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
    const accentGreen = AppColors.accent;

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
  final bool isDarkMode;
  final String viewerRole;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const _EmptyChatsState({
    required this.isDarkMode,
    required this.viewerRole,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  String get _subtitle {
    if (viewerRole == 'AGENT') {
      return 'Your client conversations will appear here once you are '
          'accepted for an offer.';
    }
    if (viewerRole == 'CLIENT') {
      return 'Your conversations with agents will appear here once you '
          'accept a match for your offer.';
    }
    return 'Your conversations will appear here once a job match is confirmed.';
  }

  @override
  Widget build(BuildContext context) {
    const accentGreen = AppColors.accent;

    final cardColor = isDarkMode ? Colors.black : Colors.white;
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor),
            boxShadow: isDarkMode
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(isDarkMode ? 0.12 : 0.10),
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
                _subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}