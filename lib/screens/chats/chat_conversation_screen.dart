// lib/screens/chats/chat_conversation_screen.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../conf/theme_provider.dart';
import '../../models/chat_conversation_summary_model.dart';
import '../../models/chat_message_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_conversation_display_name_service.dart';
import '../../services/chat_active_conversation_tracker.dart';
import '../../services/chat_local_read_cursor.dart';
import '../../services/chat_service.dart';
import '../../utils/chat_peer_media.dart';
import '../../services/profile_service.dart';
import 'chat_peer_profile_screen.dart';
import 'widgets/chat_offer_label.dart';
import 'widgets/edit_message_dialog.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_composer.dart';

Widget _chatPeerAvatar({
  required ChatConversationSummaryModel chat,
  required bool isDarkMode,
  required double radius,
  int viewerUserId = 0,
  String viewerRole = '',
}) {
  final photoRaw = resolveChatPeerPhotoRaw(
    chat: chat,
    viewerUserId: viewerUserId,
    viewerRole: viewerRole,
  );
  final resolved = ProfileService.resolveMediaUrl(
    photoRaw.isEmpty ? null : photoRaw,
  );
  final diameter = radius * 2;
  final bg = isDarkMode ? Colors.black : const Color(0xFFE5E7EB);
  final fg = isDarkMode ? Colors.white : const Color(0xFF111827);
  final initials = chat.peerDisplayInitialsForViewer(
    viewerUserId,
    viewerRole: viewerRole,
  );
  final imageCacheKey = 'conv-peer-${chat.id}-$photoRaw';
  final fontSize = (radius * 0.52).clamp(11.0, 34.0);

  Widget initialsLabel() {
    return Text(
      initials,
      style: TextStyle(
        color: fg,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  if (resolved != null && resolved.isNotEmpty) {
    return ClipOval(
      child: Container(
        width: diameter,
        height: diameter,
        color: bg,
        child: Image.network(
          resolved,
          key: ValueKey(imageCacheKey),
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => Center(child: initialsLabel()),
        ),
      ),
    );
  }

  return CircleAvatar(
    radius: radius,
    backgroundColor: bg,
    child: initialsLabel(),
  );
}

/// Small ring + dot for peer online/offline (same idea as the chats list).
class _ConversationPresenceDot extends StatelessWidget {
  const _ConversationPresenceDot({
    required this.isOnline,
    required this.onlineColor,
    required this.offlineColor,
    required this.dotDiameter,
    required this.ringOuterDiameter,
    required this.ringColor,
  });

  final bool isOnline;
  final Color onlineColor;
  final Color offlineColor;
  final double dotDiameter;
  final double ringOuterDiameter;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ringOuterDiameter,
      height: ringOuterDiameter,
      decoration: BoxDecoration(
        color: ringColor,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Container(
        width: dotDiameter,
        height: dotDiameter,
        decoration: BoxDecoration(
          color: isOnline ? onlineColor : offlineColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ChatConversationScreen extends StatefulWidget {
  final ChatConversationSummaryModel chat;

  const ChatConversationScreen({
    super.key,
    required this.chat,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen>
    with WidgetsBindingObserver {
  static const int _pageSize = 10;
  static const Duration _readReceiptSyncInterval = Duration(seconds: 20);
  static const Duration _peerPresencePollInterval = Duration(seconds: 25);

  /// Latest chat payload (refreshed from API so fields like [phone] stay in sync).
  late ChatConversationSummaryModel _conversation;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  WebSocketChannel? _socketChannel;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _readReceiptTimer;
  Timer? _presencePollTimer;

  bool _isLoading = true;
  bool _isSending = false;
  bool _isSocketConnected = false;
  bool _isSyncingReadReceipts = false;
  bool _isLoadingOlderMessages = false;
  bool _hasMoreMessages = true;
  bool _isMessageActionRunning = false;

  String? _errorMessage;
  int _currentUserId = 0;
  String _viewerRole = '';
  int? _nextBeforeMessageId;
  int _newMessagesCount = 0;

  List<ChatMessageModel> _messages = [];

  bool _isAppInForeground = true;

  int? _lastLocalMessageEditId;
  DateTime? _lastLocalMessageEditAt;

  /// Local nickname or server peer name for the app bar / quick info.
  String _conversationHeaderTitle = '';

  int get _clientId => _conversation.client?.id ?? 0;
  int get _agentId => _conversation.agent?.id ?? 0;

  /// True when [readerId] is the other participant (Django user id or profile id).
  bool _socketReaderIsChatPeer(int readerId) {
    if (readerId <= 0) return false;
    if (readerId == _currentUserId) return false;

    for (final user in [
      _conversation.otherUser,
      _conversation.client,
      _conversation.agent,
    ]) {
      if (user == null) continue;
      if (user.id > 0 && readerId == user.id) return true;
      final uid = user.userId;
      if (uid != null && uid > 0 && readerId == uid) return true;
    }

    return false;
  }

  bool _messageIsFromViewer(ChatMessageModel message) {
    if (message.senderId <= 0 || _currentUserId <= 0) return false;
    if (message.senderId == _currentUserId) return true;

    if (_viewerRole == 'AGENT') {
      if (message.isFromAgent) return true;

      final agent = _conversation.agent;
      if (agent == null) return false;
      if (message.senderId == agent.id) return true;
      final uid = agent.userId;
      if (uid != null && uid > 0 && message.senderId == uid) return true;
      return false;
    }

    if (message.isFromClient) return true;

    final client = _conversation.client;
    if (client == null) return false;
    if (message.senderId == client.id) return true;
    final uid = client.userId;
    if (uid != null && uid > 0 && message.senderId == uid) return true;
    return false;
  }

  /// Sender id the API/WebSocket uses for the logged-in participant.
  int get _outgoingSenderId {
    if (_viewerRole == 'AGENT') {
      final agent = _conversation.agent;
      if (agent != null) {
        final uid = agent.userId;
        if (uid != null && uid > 0) return uid;
        if (agent.id > 0) return agent.id;
      }
    } else {
      final client = _conversation.client;
      if (client != null) {
        final uid = client.userId;
        if (uid != null && uid > 0) return uid;
        if (client.id > 0) return client.id;
      }
    }

    return _currentUserId;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _conversation = widget.chat;
    _conversationHeaderTitle = widget.chat.displayName;
    _scrollController.addListener(_handleScroll);
    _bootstrapConversation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateActiveConversationVisibility();
    });
  }

  Future<void> _updateLocalReadCursor() async {
    if (_messages.isEmpty) return;

    var maxId = 0;
    for (final message in _messages) {
      if (message.id > maxId) maxId = message.id;
    }

    if (maxId > 0) {
      await ChatLocalReadCursor.instance.setLastReadMessageId(
        _conversation.id,
        maxId,
      );
    }
  }

  @override
  void dispose() {
    ChatActiveConversationTracker.instance.setActive(null, visible: false);
    WidgetsBinding.instance.removeObserver(this);
    _presencePollTimer?.cancel();
    _readReceiptTimer?.cancel();
    _socketSubscription?.cancel();
    _socketChannel?.sink.close();
    _scrollController.removeListener(_handleScroll);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapConversation() async {
    final storedUserId = await AuthService.getStoredUserId();
    final storedRole = await AuthService.getStoredRole();

    if (!mounted) return;

    setState(() {
      _currentUserId = storedUserId ?? 0;
      _viewerRole = (storedRole ?? '').toUpperCase();
    });

    await ChatConversationDisplayNameService.instance.ensureLoaded();
    if (!mounted) return;
    setState(_recomputeHeaderTitle);

    await _refreshChatSummaryFromServer();

    await _loadInitialMessages();
    await _connectSocket();

    _startReadReceiptSync();
    _startPeerPresencePolling();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_markMessagesAsReadIfActive());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateActiveConversationVisibility();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    _updateActiveConversationVisibility();

    if (state == AppLifecycleState.resumed) {
      _refreshChatSummaryFromServer();
      unawaited(_markMessagesAsReadIfActive());
    }
  }

  bool get _isConversationActive {
    if (!mounted || !_isAppInForeground) return false;

    final route = ModalRoute.of(context);
    return route != null && route.isCurrent;
  }

  void _updateActiveConversationVisibility() {
    ChatActiveConversationTracker.instance.setActive(
      _conversation.id,
      visible: _isConversationActive,
    );
  }

  Future<void> _markMessagesAsReadIfActive() async {
    if (!_isConversationActive) return;

    try {
      await ChatService.markAllMessagesAsRead(chatId: _conversation.id);
      await _updateLocalReadCursor();
      if (mounted) {
        await _syncReadReceiptsSilently();
        await _refreshChatSummaryFromServer();
        await _patchConversationLastMessageReadFromMessages();
      }
    } catch (_) {
      // Read sync is best-effort.
    }
  }

  void _startPeerPresencePolling() {
    _presencePollTimer?.cancel();
    _presencePollTimer = Timer.periodic(
      _peerPresencePollInterval,
      (_) {
        if (!mounted) return;
        _refreshChatSummaryFromServer();
      },
    );
  }

  void _applyPeerOnline(bool online) {
    final ou = _conversation.otherUser;
    if (ou == null) return;
    final uid = ou.userId ?? ou.id;
    if (uid <= 0) return;
    if (!mounted) return;
    setState(() {
      _conversation = _conversation.withUserOnlineState(
        userId: uid,
        isOnline: online,
      );
    });
  }

  void _handleSocketPresence(String? eventType, Map<String, dynamic> data) {
    final type = eventType ?? '';

    if (type == 'presence_update') {
      final uid = _parseInt(data['user_id']);
      final online = _parseBool(data['is_online']);
      if (uid == null || online == null) return;
      if (uid == _currentUserId) return;
      if (!mounted) return;
      setState(() {
        _conversation = _conversation.withUserOnlineState(
          userId: uid,
          isOnline: online,
        );
      });
      return;
    }

    final peer = _conversation.otherUser;
    if (peer == null) return;

    bool? online;
    if (type == 'user_online') {
      online = true;
    } else if (type == 'user_offline') {
      online = false;
    } else {
      online = _parseBool(data['is_online']) ??
          _parseBool(data['isOnline']) ??
          _parseBool(data['online']);
      final status = data['status']?.toString().trim().toLowerCase();
      if (online == null && status != null && status.isNotEmpty) {
        if (status == 'online' || status == 'away') online = true;
        if (status == 'offline' || status == 'disconnected') online = false;
      }
    }

    if (online == null) return;

    final uid = _parseInt(data['user_id']) ??
        _parseInt(data['userId']) ??
        _parseInt(data['id']);

    final peerUserId = peer.userId ?? peer.id;
    if (uid != null && uid > 0) {
      if (peerUserId > 0 && uid != peerUserId) {
        return;
      }
      _applyPeerOnline(online);
      return;
    }

    if (type == 'user_online' || type == 'user_offline') {
      _applyPeerOnline(online);
    }
  }

  void _recomputeHeaderTitle() {
    _conversationHeaderTitle =
        ChatConversationDisplayNameService.instance.resolve(
      _conversation.id,
      _conversation.displayName,
    );
  }

  Future<void> _refreshChatSummaryFromServer() async {
    try {
      final fresh =
          await ChatService.getChatById(chatId: _conversation.id);
      if (!mounted) return;
      setState(() {
        _conversation = fresh;
        _recomputeHeaderTitle();
      });
    } catch (_) {
      // Keep the list snapshot if detail fails (offline, etc.).
    }
  }

  void _startReadReceiptSync() {
    _readReceiptTimer?.cancel();

    _readReceiptTimer = Timer.periodic(
      _readReceiptSyncInterval,
      (_) {
        if (!_isSocketConnected) {
          _syncReadReceiptsSilently();
        }
      },
    );
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    if (_isNearBottom()) {
      if (_newMessagesCount != 0 && mounted) {
        setState(() {
          _newMessagesCount = 0;
        });
      }
    }

    if (_scrollController.position.pixels <= 70) {
      _loadOlderMessages();
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;

    final distanceFromBottom = _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;

    return distanceFromBottom <= 130;
  }

  ({double extent, double pixels}) _captureScrollAnchor() {
    if (!_scrollController.hasClients) {
      return (extent: 0, pixels: 0);
    }

    return (
      extent: _scrollController.position.maxScrollExtent,
      pixels: _scrollController.position.pixels,
    );
  }

  void _restoreScrollAnchor({
    required double beforeExtent,
    required double beforePixels,
  }) {
    if (!_scrollController.hasClients) return;

    void apply() {
      if (!_scrollController.hasClients) return;

      final delta = _scrollController.position.maxScrollExtent - beforeExtent;
      _scrollController.jumpTo(
        (beforePixels + delta).clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        ),
      );
    }

    apply();
    WidgetsBinding.instance.addPostFrameCallback((_) => apply());
  }

  void _setMessagesPreservingScroll(
    List<ChatMessageModel> nextMessages, {
    required bool scrollToBottomIfNear,
  }) {
    if (!mounted) return;

    final wasNearBottom = _isNearBottom();
    final anchor = _captureScrollAnchor();

    setState(() {
      _messages = _sortMessages(nextMessages);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      if (scrollToBottomIfNear && wasNearBottom) {
        _scrollToBottom(force: true);
        return;
      }

      if (!wasNearBottom) {
        _restoreScrollAnchor(
          beforeExtent: anchor.extent,
          beforePixels: anchor.pixels,
        );
      }
    });
  }

  Future<void> _connectSocket() async {
    try {
      await _socketSubscription?.cancel();
      await _socketChannel?.sink.close();

      final channel = await ChatService.connectToChatSocket(
        chatId: _conversation.id,
      );

      _socketChannel = channel;

      if (mounted) {
        setState(() {
          _isSocketConnected = true;
        });
      }

      _socketSubscription = channel.stream.listen(
        _handleSocketEvent,
        onError: (_) {
          if (!mounted) return;

          setState(() {
            _isSocketConnected = false;
          });
        },
        onDone: () {
          if (!mounted) return;

          setState(() {
            _isSocketConnected = false;
          });
        },
        cancelOnError: false,
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSocketConnected = false;
      });
    }
  }

  Future<void> _loadInitialMessages({bool markRead = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final page = await ChatService.getMessagesPage(
        chat: _conversation,
        limit: _pageSize,
      );

      if (markRead && _isConversationActive) {
        await ChatService.markAllMessagesAsRead(chatId: _conversation.id);
      }

      if (!mounted) return;

      setState(() {
        _messages = _sortMessages(page.messages);
        _hasMoreMessages = page.hasMore;
        _nextBeforeMessageId = page.nextBefore;
        _newMessagesCount = 0;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(jump: true, force: true);
      });
    } on ChatServiceException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load messages.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadOlderMessages() async {
    if (!_hasMoreMessages ||
        _isLoadingOlderMessages ||
        _isLoading ||
        _nextBeforeMessageId == null) {
      return;
    }

    if (!_scrollController.hasClients) return;

    final anchor = _captureScrollAnchor();

    setState(() {
      _isLoadingOlderMessages = true;
    });

    try {
      final page = await ChatService.getMessagesPage(
        chat: _conversation,
        limit: _pageSize,
        beforeMessageId: _nextBeforeMessageId,
      );

      if (!mounted) return;

      final olderMessages = page.messages.where((olderMessage) {
        return !_messages.any((message) => message.id == olderMessage.id);
      }).toList();

      setState(() {
        _messages = _sortMessages([...olderMessages, ..._messages]);
        _hasMoreMessages = page.hasMore;
        _nextBeforeMessageId = page.nextBefore;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _restoreScrollAnchor(
          beforeExtent: anchor.extent,
          beforePixels: anchor.pixels,
        );
      });
    } catch (_) {
      // Loading older messages should not break the current conversation view.
    } finally {
      if (mounted) {
        final loaderAnchor = _captureScrollAnchor();

        setState(() {
          _isLoadingOlderMessages = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _restoreScrollAnchor(
            beforeExtent: loaderAnchor.extent,
            beforePixels: loaderAnchor.pixels,
          );
        });
      }
    }
  }

  Future<void> _syncReadReceiptsSilently() async {
    if (!mounted ||
        _isLoading ||
        _isSyncingReadReceipts ||
        _messages.isEmpty) {
      return;
    }

    _isSyncingReadReceipts = true;

    try {
      final page = await ChatService.getMessagesPage(
        chat: _conversation,
        limit: 30,
      );

      if (!mounted) return;

      final wasNearBottom = _isNearBottom();

      final freshById = {
        for (final message in page.messages) message.id: message,
      };

      bool changed = false;

      final mergedMessages = _messages.map((localMessage) {
        if (localMessage.id < 0) {
          final hasServerReplacement = page.messages.any(
            (freshMessage) => _isLikelySameTemporaryMessage(
              localMessage,
              freshMessage,
            ),
          );

          if (hasServerReplacement) {
            changed = true;
            return null;
          }

          return localMessage;
        }

        final freshMessage = freshById[localMessage.id];

        if (freshMessage == null) return localMessage;

        if (localMessage.isRead != freshMessage.isRead ||
            localMessage.text != freshMessage.text) {
          changed = true;
          return freshMessage;
        }

        return localMessage;
      }).whereType<ChatMessageModel>().toList();

      for (final freshMessage in page.messages) {
        final alreadyExists = mergedMessages.any(
          (message) =>
              message.id == freshMessage.id ||
              _isLikelySameTemporaryMessage(message, freshMessage) ||
              _isDuplicateOutgoingMessage(message, freshMessage),
        );

        if (!alreadyExists) {
          changed = true;
          mergedMessages.add(freshMessage);

          if (!wasNearBottom && !_messageIsFromViewer(freshMessage)) {
            _newMessagesCount += 1;
          }
        }
      }

      if (!changed) return;

      _setMessagesPreservingScroll(
        mergedMessages,
        scrollToBottomIfNear: true,
      );
      unawaited(_patchConversationLastMessageReadFromMessages());
    } catch (_) {
      // Silent sync must never disturb the conversation UI.
    } finally {
      _isSyncingReadReceipts = false;
    }
  }

  bool _isLikelySameTemporaryMessage(
    ChatMessageModel temporaryMessage,
    ChatMessageModel serverMessage,
  ) {
    if (temporaryMessage.id >= 0 || serverMessage.id <= 0) return false;

    if (!_messageIsFromViewer(temporaryMessage)) return false;
    if (!_messageIsFromViewer(serverMessage)) return false;

    return temporaryMessage.text.trim() == serverMessage.text.trim();
  }

  bool _isDuplicateOutgoingMessage(
    ChatMessageModel existing,
    ChatMessageModel incoming,
  ) {
    if (existing.id == incoming.id && incoming.id > 0) return true;

    if (!_messageIsFromViewer(existing) || !_messageIsFromViewer(incoming)) {
      return false;
    }

    if (existing.text.trim() != incoming.text.trim()) return false;

    // Optimistic placeholder vs persisted echo — always the same send.
    if (existing.id <= 0 || incoming.id <= 0) {
      return true;
    }

    // Collapse socket + polling echoes (same outgoing text within 2 minutes).
    final secondsDiff =
        incoming.sentAt.difference(existing.sentAt).inSeconds.abs();
    return secondsDiff <= 120;
  }

  List<ChatMessageModel> _dedupeMessageList(List<ChatMessageModel> messages) {
    final result = <ChatMessageModel>[];

    for (final message in messages) {
      final duplicateIndex = result.indexWhere(
        (existing) =>
            (existing.id == message.id && message.id > 0) ||
            _isDuplicateOutgoingMessage(existing, message),
      );

      if (duplicateIndex < 0) {
        result.add(message);
        continue;
      }

      final existing = result[duplicateIndex];
      if (existing.id <= 0 && message.id > 0) {
        result[duplicateIndex] = message;
      }
    }

    return result;
  }

  void _handleSocketEvent(dynamic event) {
    try {
      final decoded = event is String ? jsonDecode(event) : event;

      if (decoded is! Map) return;

      final data = Map<String, dynamic>.from(decoded);
      final type = data['type']?.toString();

      if (type == 'new_message' ||
          type == 'message_created' ||
          type == 'chat_message') {
        _handleSocketNewMessage(data);
        return;
      }

      if (type == 'message_seen') {
        _handleSocketMessageSeen(data);
        return;
      }

      if (type == 'messages_seen') {
        _handleSocketMessagesSeen(data);
        return;
      }

      if (type == 'message_updated' || type == 'chat_message_updated') {
        _handleSocketMessageUpdated(data);
        return;
      }

      if (type == 'presence_update' ||
          type == 'presence' ||
          type == 'user_presence' ||
          type == 'peer_presence' ||
          type == 'user_online' ||
          type == 'user_offline') {
        _handleSocketPresence(type, data);
        return;
      }

      if (data['error'] != null) {
        debugPrint('[CHAT_SOCKET] ${data['error']}');
      }
    } catch (e) {
      debugPrint('[CHAT_SOCKET] Invalid event: $e');
    }
  }

  void _handleSocketNewMessage(Map<String, dynamic> data) {
    final rawMessage = data['message'];

    if (rawMessage is! Map) return;

    final message = ChatMessageModel.fromJson(
      json: Map<String, dynamic>.from(rawMessage),
      clientId: _clientId,
      agentId: _agentId,
      clientUserId: _conversation.client?.userId,
      agentUserId: _conversation.agent?.userId,
    );

    if (message.id == 0 && message.text.trim().isEmpty) return;

    final wasNearBottom = _isNearBottom();
    final isIncoming = !_messageIsFromViewer(message);

    if (!mounted) return;

    setState(() {
      final existingIndex = _messages.indexWhere(
        (item) => item.id == message.id,
      );

      if (existingIndex >= 0) {
        final updatedMessages = [..._messages];
        updatedMessages[existingIndex] = message;
        _messages = _sortMessages(updatedMessages);
      } else {
        final withoutDuplicates = _messages.where((item) {
          if (item.id == message.id) return false;
          if (_isLikelySameTemporaryMessage(item, message)) return false;
          if (_isDuplicateOutgoingMessage(item, message)) return false;
          if (_messageIsFromViewer(message) &&
              item.id < 0 &&
              _messageIsFromViewer(item) &&
              item.text.trim() == message.text.trim()) {
            return false;
          }
          return true;
        }).toList();

        _messages = _sortMessages([...withoutDuplicates, message]);

        if (!wasNearBottom && isIncoming) {
          _newMessagesCount += 1;
        }
      }
    });

    if (isIncoming && _isConversationActive) {
      unawaited(_markMessagesAsReadIfActive());
    }

    if (wasNearBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(force: true);
      });
    }
  }

  void _handleSocketMessageSeen(Map<String, dynamic> data) {
    final messageId =
        _parseInt(data['message_id']) ?? _parseInt(data['messageId']);

    final readerId = _parseInt(data['reader_id']) ?? _parseInt(data['readerId']);

    if (!mounted) return;

    if (messageId != null) {
      if (readerId != null && readerId == _currentUserId) {
        return;
      }
      if (readerId != null && !_socketReaderIsChatPeer(readerId)) {
        return;
      }

      setState(() {
        _messages = _messages.map((message) {
          if (message.id == messageId && _messageIsFromViewer(message)) {
            return message.copyWith(isRead: true);
          }

          return message;
        }).toList();
      });

      unawaited(_patchConversationLastMessageReadFromMessages());
      return;
    }

    if (readerId == null || _socketReaderIsChatPeer(readerId)) {
      setState(() {
        _messages = _messages.map((message) {
          if (_messageIsFromViewer(message)) {
            return message.copyWith(isRead: true);
          }

          return message;
        }).toList();
      });

      unawaited(_patchConversationLastMessageReadFromMessages());
      return;
    }

    _syncReadReceiptsSilently();
  }

  void _handleSocketMessagesSeen(Map<String, dynamic> data) {
    final readerId = _parseInt(data['reader_id']) ?? _parseInt(data['readerId']);

    if (!mounted) return;

    if (readerId == null || _socketReaderIsChatPeer(readerId)) {
      setState(() {
        _messages = _messages.map((message) {
          if (_messageIsFromViewer(message)) {
            return message.copyWith(isRead: true);
          }

          return message;
        }).toList();
      });

      unawaited(_patchConversationLastMessageReadFromMessages());
    }
  }

  /// Keeps list preview in sync when peer read receipts arrive on the socket.
  Future<void> _patchConversationLastMessageReadFromMessages() async {
    if (!mounted || _messages.isEmpty) return;

    final lastOutgoing = _messages
        .where((m) => m.id > 0 && _messageIsFromViewer(m))
        .fold<ChatMessageModel?>(
          null,
          (best, m) => best == null || m.id > best.id ? m : best,
        );

    if (lastOutgoing == null || !lastOutgoing.isRead) return;

    final last = _conversation.lastMessage;
    if (last == null ||
        last.id != lastOutgoing.id ||
        last.isRead == lastOutgoing.isRead) {
      return;
    }

    setState(() {
      _conversation = _conversation.copyWith(
        lastMessage: ChatLastMessageSummary(
          id: last.id,
          content: last.content,
          senderId: last.senderId,
          isRead: true,
          sentAt: last.sentAt,
        ),
      );
    });
  }

  void _handleSocketMessageUpdated(Map<String, dynamic> data) {
    final rawMessage = data['message'];

    if (rawMessage is! Map) return;

    final updatedMessage = ChatMessageModel.fromJson(
      json: Map<String, dynamic>.from(rawMessage),
      clientId: _clientId,
      agentId: _agentId,
      clientUserId: _conversation.client?.userId,
      agentUserId: _conversation.agent?.userId,
    );

    if (updatedMessage.id <= 0) return;
    if (!mounted) return;

    if (_lastLocalMessageEditId == updatedMessage.id &&
        _lastLocalMessageEditAt != null &&
        DateTime.now().difference(_lastLocalMessageEditAt!) <
            const Duration(seconds: 3)) {
      return;
    }

    _mergeMessageFromSocket(updatedMessage);
  }

  void _scheduleStateUpdate(VoidCallback update) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(update);
    });
  }

  void _applyMessageUpdate(ChatMessageModel updatedMessage) {
    if (!mounted) return;

    final index = _messages.indexWhere((m) => m.id == updatedMessage.id);
    if (index < 0) return;

    final existing = _messages[index];
    if (existing.text == updatedMessage.text &&
        existing.isRead == updatedMessage.isRead &&
        existing.isEdited == updatedMessage.isEdited) {
      return;
    }

    _lastLocalMessageEditId = updatedMessage.id;
    _lastLocalMessageEditAt = DateTime.now();

    setState(() {
      _messages = _messages.map((message) {
        if (message.id == updatedMessage.id) {
          return _withEditedFlag(existing, updatedMessage);
        }

        return message;
      }).toList();
    });
  }

  void _mergeMessageFromSocket(ChatMessageModel updatedMessage) {
    final index = _messages.indexWhere((m) => m.id == updatedMessage.id);
    if (index < 0) return;

    final existing = _messages[index];
    if (existing.text == updatedMessage.text &&
        existing.isRead == updatedMessage.isRead &&
        existing.isEdited == updatedMessage.isEdited) {
      return;
    }

    _scheduleStateUpdate(() {
      _messages = _messages.map((message) {
        if (message.id == updatedMessage.id) {
          return _withEditedFlag(existing, updatedMessage);
        }

        return message;
      }).toList();
    });
  }

  ChatMessageModel _withEditedFlag(
    ChatMessageModel existing,
    ChatMessageModel updatedMessage,
  ) {
    if (updatedMessage.isEdited) return updatedMessage;
    if (existing.text.trim() != updatedMessage.text.trim()) {
      return updatedMessage.copyWith(isEdited: true);
    }
    return updatedMessage;
  }

  void _scrollToBottom({bool jump = false, bool force = false}) {
    if (!_scrollController.hasClients) return;
    if (!force && (_isLoadingOlderMessages || !_isNearBottom())) return;

    final target = _scrollController.position.maxScrollExtent + 80;

    if (mounted) {
      setState(() {
        _newMessagesCount = 0;
      });
    }

    if (jump) {
      _scrollController.jumpTo(target);
      return;
    }

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    final optimisticMessage = ChatMessageModel.temporary(
      chatId: _conversation.id,
      senderId: _outgoingSenderId,
      clientId: _clientId,
      agentId: _agentId,
      clientUserId: _conversation.client?.userId,
      agentUserId: _conversation.agent?.userId,
      text: text,
    );

    setState(() {
      _messages = _sortMessages([..._messages, optimisticMessage]);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(force: true);
    });

    try {
      if (_socketChannel != null && _isSocketConnected) {
        ChatService.sendSocketMessage(
          channel: _socketChannel!,
          content: text,
        );
      } else {
        final message = await ChatService.sendMessage(
          chat: _conversation,
          content: text,
        );

        if (!mounted) return;

        setState(() {
          _messages = _sortMessages(
            _messages.map((item) {
              if (item.id == optimisticMessage.id) return message;
              return item;
            }).toList(),
          );
        });
      }

      if (_socketChannel != null && _isSocketConnected) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          unawaited(_syncReadReceiptsSilently());
        });
      } else {
        await _syncReadReceiptsSilently();
      }
    } on ChatServiceException catch (e) {
      _removeOptimisticMessage(optimisticMessage.id);
      _showErrorSnackBar(e.message);
    } catch (_) {
      _removeOptimisticMessage(optimisticMessage.id);
      _showErrorSnackBar('Unable to send message.');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  List<MapEntry<String, String>> _contactDetailRows() {
    final chat = _conversation;
    final offer = chat.offer;
    final user = chat.otherUser;
    final rows = <MapEntry<String, String>>[];

    final offerTitle = offer?.title.trim() ?? '';
    if (offerTitle.isNotEmpty) {
      rows.add(MapEntry('Offer', offerTitle));
    }
    final category = offer?.category.trim() ?? '';
    if (category.isNotEmpty) {
      rows.add(MapEntry('Category', category));
    }
    if (offer != null && offer.budget > 0) {
      final b = offer.budget;
      final text =
          b == b.roundToDouble() ? b.toInt().toString() : b.toString();
      rows.add(MapEntry('Budget', '$text TND'));
    }
    final city = offer?.city.trim() ?? '';
    final addr = offer?.address.trim() ?? '';
    final location = city.isNotEmpty ? city : addr;
    if (location.isNotEmpty) {
      rows.add(MapEntry('Location', location));
    }
    final phone = chat.resolvePeerPhone(viewerUserId: _currentUserId).trim();
    rows.add(MapEntry('Phone', phone.isNotEmpty ? phone : '\u2014'));
    final email = user?.email.trim() ?? '';
    if (email.isNotEmpty) {
      rows.add(MapEntry('Email', email));
    }
    final role = (user?.role ?? '').trim().toUpperCase();
    if (role.isNotEmpty) {
      rows.add(MapEntry('Role', role));
    }
    return rows;
  }

  void _showPeerQuickInfoDialog() {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final rows = _contactDetailRows();
    final primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.56);
    final cardBg = isDarkMode ? const Color(0xFF000000) : Colors.white;
    final border = isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE5E7EB);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: isDarkMode
          ? Colors.black.withOpacity(0.88)
          : Colors.black.withOpacity(0.5),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
              boxShadow: [
                if (!isDarkMode)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _conversationHeaderTitle,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact & offer',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (rows.isEmpty)
                    Text(
                      'No extra details for this chat yet.',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (var i = 0; i < rows.length; i++) ...[
                              if (i > 0)
                                Divider(
                                    height: 1, thickness: 1, color: border),
                              _QuickInfoRow(
                                label: rows[i].key,
                                value: rows[i].value,
                                valueMuted: rows[i].key == 'Phone' &&
                                    rows[i].value == '\u2014',
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: isDarkMode
                              ? AppColors.accent
                              : AppColors.accent,
                          fontWeight: FontWeight.w800,
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
      },
    );
  }

  Future<void> _openPeerProfileFullPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatPeerProfileScreen(
          chat: _conversation,
          viewerUserId: _currentUserId,
        ),
      ),
    );
    if (!mounted) return;

    await ChatConversationDisplayNameService.instance.ensureLoaded();
    if (!mounted) return;

    _scheduleStateUpdate(_recomputeHeaderTitle);
    await _refreshChatSummaryFromServer();
  }

  Future<void> _showMessageActions(ChatMessageModel message) async {
    if (!_messageIsFromViewer(message) || message.id <= 0) return;
    if (_isMessageActionRunning) return;

    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    const accentGreen = AppColors.accent;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: isDarkMode
          ? Colors.black.withValues(alpha: 0.88)
          : Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) {
        final cardBg = isDarkMode ? const Color(0xFF000000) : Colors.white;
        final primaryTextColor =
            isDarkMode ? Colors.white : const Color(0xFF111827);
        final secondaryTextColor = isDarkMode
            ? Colors.white.withOpacity(0.55)
            : Colors.black.withOpacity(0.54);
        final border = isDarkMode
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFE5E7EB);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
              boxShadow: [
                if (!isDarkMode)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 6, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Message',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.close_rounded,
                          color: secondaryTextColor,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: border),
                _CenteredMessageActionRow(
                  icon: Icons.edit_outlined,
                  title: 'Edit message',
                  subtitle: 'Change the text of this message',
                  accent: accentGreen,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    if (!mounted) return;
                    await _showEditMessageSheet(message);
                  },
                ),
                Divider(height: 1, thickness: 1, indent: 56, color: border),
                _CenteredMessageActionRow(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete message',
                  subtitle: 'Remove from your view only',
                  accent: const Color(0xFFDC2626),
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  onTap: () {
                    Navigator.pop(dialogContext);
                    Future.microtask(() => _confirmDeleteMessage(message));
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditMessageSheet(ChatMessageModel message) async {
    if (!_messageIsFromViewer(message) || message.id <= 0) return;
    if (!mounted) return;

    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    final updatedMessage = await showDialog<ChatMessageModel>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: isDarkMode
          ? Colors.black.withValues(alpha: 0.88)
          : Colors.black.withValues(alpha: 0.5),
      builder: (_) => EditMessageDialog(
        message: message,
        conversation: _conversation,
        isDarkMode: isDarkMode,
      ),
    );

    if (!mounted || updatedMessage == null) return;

    _applyMessageUpdate(updatedMessage);
  }

  Future<void> _confirmDeleteMessage(ChatMessageModel message) async {
    if (!_messageIsFromViewer(message) || message.id <= 0) return;

    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: isDarkMode
          ? Colors.black.withOpacity(0.88)
          : Colors.black.withOpacity(0.5),
      builder: (dialogContext) {
        final shell = isDarkMode ? const Color(0xFF000000) : Colors.white;
        final primaryTextColor =
            isDarkMode ? Colors.white : const Color(0xFF111827);
        final secondaryTextColor = isDarkMode
            ? Colors.white.withOpacity(0.55)
            : Colors.black.withOpacity(0.54);
        final border = isDarkMode
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFE5E7EB);
        const danger = Color(0xFFEF4444);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              color: shell,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
              boxShadow: [
                if (!isDarkMode)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Delete message?',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.close_rounded,
                          color: secondaryTextColor,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    'This message will be removed only from your side. '
                    'The other user will still see it.',
                    style: TextStyle(
                      color: secondaryTextColor,
                      height: 1.45,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryTextColor,
                            side: BorderSide(color: border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: danger,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldDelete == true) {
      await _handleDeleteMessage(message);
    }
  }

  Future<void> _handleDeleteMessage(ChatMessageModel message) async {
    if (_isMessageActionRunning) return;

    try {
      final result = await ChatService.deleteMessage(
        chat: _conversation,
        messageId: message.id,
      );

      if (!mounted) return;

      if (!result.deletedForSelfOnly) {
        _showErrorSnackBar(
          'This message could not be hidden on your side only.',
        );
        return;
      }

      _scheduleStateUpdate(() {
        _messages = _messages
            .where((item) => item.id != result.messageId)
            .toList();
      });
    } on ChatServiceException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (_) {
      _showErrorSnackBar('Unable to delete message.');
    }
  }

  void _removeOptimisticMessage(int messageId) {
    if (!mounted) return;

    setState(() {
      _messages =
          _messages.where((message) => message.id != messageId).toList();
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFB91C1C),
      ),
    );
  }

  List<ChatMessageModel> _sortMessages(List<ChatMessageModel> messages) {
    final deduped = _dedupeMessageList(messages);
    final sortedMessages = [...deduped];
    sortedMessages.sort((a, b) {
      final byTime = a.sentAt.compareTo(b.sentAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
    return sortedMessages;
  }

  List<_TimelineItem> _buildTimelineItems(List<ChatMessageModel> messages) {
    final items = <_TimelineItem>[];
    DateTime? previousDate;

    for (final message in messages) {
      final sentLocal = message.sentAt.toLocal();
      final currentDate = DateTime(
        sentLocal.year,
        sentLocal.month,
        sentLocal.day,
      );

      if (previousDate == null || !_isSameDay(previousDate, currentDate)) {
        items.add(_TimelineItem.date(_formatDateSeparator(currentDate)));
        previousDate = currentDate;
      }

      items.add(_TimelineItem.message(message));
    }

    return items;
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (_isSameDay(date, today)) return 'Today';
    if (_isSameDay(date, yesterday)) return 'Yesterday';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    const accentGreen = AppColors.accent;

    final backgroundColor =
        isDarkMode ? const Color(0xFF000000) : const Color(0xFFF3F4F6);

    final appBarColor = isDarkMode ? const Color(0xFF000000) : Colors.white;

    final primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF111827);

    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.58)
        : Colors.black.withOpacity(0.54);

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: primaryTextColor,
          iconTheme: IconThemeData(color: primaryTextColor),
          toolbarHeight: 58,
          leadingWidth: 42,
          leading: AppBackButton(isDarkMode: isDarkMode),
          titleSpacing: 0,
          title: Row(
            children: [
              GestureDetector(
                onTap: _openPeerProfileFullPage,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _chatPeerAvatar(
                    chat: _conversation,
                    isDarkMode: isDarkMode,
                    radius: 19,
                    viewerUserId: _currentUserId,
                    viewerRole: _viewerRole,
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: _ConversationPresenceDot(
                      isOnline:
                          _conversation.peerOnlineForViewer(_currentUserId),
                      onlineColor: accentGreen,
                      offlineColor: secondaryTextColor,
                      dotDiameter: 6,
                      ringOuterDiameter: 12,
                    ringColor:
                        isDarkMode ? const Color(0xFF000000) : Colors.white,
                    ),
                  ),
                ],
              ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _showPeerQuickInfoDialog,
                      onLongPress: _openPeerProfileFullPage,
                      child: Text(
                        _conversationHeaderTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    ChatOfferLabel(
                      offerTitle: _conversation.offerTitle,
                      color: secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: _buildMessagesBody(
                isDarkMode: isDarkMode,
                accentGreen: accentGreen,
                secondaryTextColor: secondaryTextColor,
              ),
            ),
            SafeArea(
              top: false,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _messageController,
                builder: (context, value, _) {
                  return MessageComposer(
                    controller: _messageController,
                    isDarkMode: isDarkMode,
                    onSend: _isSending ? () {} : _handleSend,
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildMessagesBody({
    required bool isDarkMode,
    required Color accentGreen,
    required Color secondaryTextColor,
  }) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: accentGreen,
          strokeWidth: 2.4,
        ),
      );
    }

    if (_errorMessage != null) {
      return _ConversationErrorState(
        message: _errorMessage!,
        isDarkMode: isDarkMode,
        onRetry: () async {
          await _loadInitialMessages(markRead: true);
          await _connectSocket();
          await _syncReadReceiptsSilently();
        },
      );
    }

    if (_messages.isEmpty) {
      return _EmptyConversationState(
        chat: _conversation,
        headerDisplayName: _conversationHeaderTitle,
        isDarkMode: isDarkMode,
        isPeerOnline: _conversation.peerOnlineForViewer(_currentUserId),
        viewerUserId: _currentUserId,
        viewerRole: _viewerRole,
      );
    }

    final timelineItems = _buildTimelineItems(_messages);
    final peerPhotoRaw = resolveChatPeerPhotoRaw(
      chat: _conversation,
      viewerUserId: _currentUserId,
      viewerRole: _viewerRole,
    );
    final peerAvatarUrl = ProfileService.resolveMediaUrl(
      peerPhotoRaw.isEmpty ? null : peerPhotoRaw,
    );

    return Stack(
      children: [
        RefreshIndicator(
          color: accentGreen,
          onRefresh: () async {
            await _refreshChatSummaryFromServer();
            await _loadInitialMessages(markRead: true);
            await _connectSocket();
            await _syncReadReceiptsSilently();
          },
          child: ListView.builder(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
            itemCount: timelineItems.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _TopHistoryLoader(
                  isVisible: _isLoadingOlderMessages,
                  hasOlderMessages: _hasMoreMessages,
                  isDarkMode: isDarkMode,
                );
              }

              final item = timelineItems[index - 1];

              if (item.isDate) {
                return _DateSeparator(
                  label: item.dateLabel!,
                  isDarkMode: isDarkMode,
                );
              }

              final message = item.message!;
              final isMine = _messageIsFromViewer(message);

              return MessageBubble(
                message: message,
                isDarkMode: isDarkMode,
                isMine: isMine,
                avatarInitials: _conversation.displayInitials,
                avatarPhotoUrl: peerAvatarUrl,
                onAvatarTap: isMine ? null : _openPeerProfileFullPage,
                onLongPress: isMine && message.id > 0
                    ? () => _showMessageActions(message)
                    : null,
              );
            },
          ),
        ),
        if (_newMessagesCount > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Center(
              child: GestureDetector(
                onTap: () => _scrollToBottom(force: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: accentGreen,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.16),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    _newMessagesCount == 1
                        ? 'New message'
                        : '$_newMessagesCount new messages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TimelineItem {
  final String? dateLabel;
  final ChatMessageModel? message;

  const _TimelineItem._({
    this.dateLabel,
    this.message,
  });

  bool get isDate => dateLabel != null;

  factory _TimelineItem.date(String label) {
    return _TimelineItem._(dateLabel: label);
  }

  factory _TimelineItem.message(ChatMessageModel message) {
    return _TimelineItem._(message: message);
  }
}

class _QuickInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueMuted;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const _QuickInfoRow({
    required this.label,
    required this.value,
    this.valueMuted = false,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = valueMuted ? secondaryTextColor : primaryTextColor;
    final weight = valueMuted ? FontWeight.w600 : FontWeight.w700;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: weight,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredMessageActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;

  const _CenteredMessageActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHistoryLoader extends StatelessWidget {
  final bool isVisible;
  final bool hasOlderMessages;
  final bool isDarkMode;

  const _TopHistoryLoader({
    required this.isVisible,
    required this.hasOlderMessages,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasOlderMessages && !isVisible) {
      return const SizedBox(height: 8);
    }

    return SizedBox(
      height: hasOlderMessages ? 46 : 8,
      child: isVisible
          ? Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.72)
                      : Colors.black.withOpacity(0.48),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final String label;
  final bool isDarkMode;

  const _DateSeparator({
    required this.label,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDarkMode
                ? Colors.white.withOpacity(0.66)
                : Colors.black.withOpacity(0.52),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyConversationState extends StatelessWidget {
  final ChatConversationSummaryModel chat;
  final String headerDisplayName;
  final bool isDarkMode;
  final bool isPeerOnline;
  final int viewerUserId;
  final String viewerRole;

  const _EmptyConversationState({
    required this.chat,
    required this.headerDisplayName,
    required this.isDarkMode,
    required this.isPeerOnline,
    required this.viewerUserId,
    required this.viewerRole,
  });

  static String? _formatBudgetLine(ChatOfferSummary? offer) {
    if (offer == null) return null;
    if (offer.budget <= 0) return null;
    final b = offer.budget;
    final text = b == b.roundToDouble() ? b.toInt().toString() : b.toString();
    return '$text TND';
  }

  static String? _formatLocation(ChatOfferSummary? offer) {
    if (offer == null) return null;
    final city = offer.city.trim();
    if (city.isNotEmpty) return city;
    final addr = offer.address.trim();
    if (addr.isNotEmpty) return addr;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const accentGreen = AppColors.accent;
    const cardBlack = Color(0xFF000000);
    const insetBlack = Color(0xFF0D0D0D);

    final primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.58)
        : Colors.black.withOpacity(0.54);
    final cardBg = isDarkMode ? cardBlack : Colors.white;
    final insetBg = isDarkMode ? insetBlack : const Color(0xFFF3F4F6);
    final presenceRingColor =
        isDarkMode ? cardBlack : Colors.white;
    final cardBorderColor = isDarkMode
        ? accentGreen.withOpacity(0.22)
        : Colors.black.withOpacity(0.06);
    final insetBorderColor = isDarkMode
        ? accentGreen.withOpacity(0.14)
        : Colors.black.withOpacity(0.04);

    final offer = chat.offer;
    final user = chat.otherUser;
    final roleLabel = (user?.role ?? '').trim().toUpperCase();

    final detailRows = <MapEntry<String, String>>[];
    final offerTitle = offer?.title.trim() ?? '';
    if (offerTitle.isNotEmpty) {
      detailRows.add(MapEntry('Offer', offerTitle));
    }
    final category = offer?.category.trim() ?? '';
    if (category.isNotEmpty) {
      detailRows.add(MapEntry('Category', category));
    }
    final budgetStr = _formatBudgetLine(offer);
    if (budgetStr != null) {
      detailRows.add(MapEntry('Budget', budgetStr));
    }
    final location = _formatLocation(offer);
    if (location != null) {
      detailRows.add(MapEntry('Location', location));
    }
    final phone = chat.resolvePeerPhone(viewerUserId: viewerUserId).trim();
    detailRows.add(
      MapEntry('Phone', phone.isNotEmpty ? phone : '\u2014'),
    );
    final email = user?.email.trim() ?? '';
    if (email.isNotEmpty) {
      detailRows.add(MapEntry('Email', email));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardBorderColor),
                  boxShadow: isDarkMode
                      ? [
                          BoxShadow(
                            color: accentGreen.withOpacity(0.06),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        _chatPeerAvatar(
                          chat: chat,
                          isDarkMode: isDarkMode,
                          radius: 46,
                          viewerUserId: viewerUserId,
                          viewerRole: viewerRole,
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: _ConversationPresenceDot(
                            isOnline: isPeerOnline,
                            onlineColor: accentGreen,
                            offlineColor: secondaryTextColor,
                            dotDiameter: 10,
                            ringOuterDiameter: 18,
                            ringColor: presenceRingColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      headerDisplayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (roleLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? accentGreen.withOpacity(0.1)
                              : accentGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accentGreen.withOpacity(0.28),
                          ),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            color: isDarkMode
                                ? accentGreen.withOpacity(0.95)
                                : const Color(0xFF166534),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                    if (detailRows.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: insetBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: insetBorderColor),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < detailRows.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.black.withOpacity(0.06),
                                ),
                              _EmptyConversationDetailRow(
                                label: detailRows[i].key,
                                value: detailRows[i].value,
                                valueMuted: detailRows[i].key == 'Phone' &&
                                    detailRows[i].value == '\u2014',
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF0A120E)
                            : accentGreen.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentGreen.withOpacity(
                            isDarkMode ? 0.32 : 0.22,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? cardBlack
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accentGreen.withOpacity(0.35),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.work_outline_rounded,
                              size: 22,
                              color: accentGreen.withOpacity(0.95),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start the conversation',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? accentGreen.withOpacity(0.95)
                                        : const Color(0xFF166534),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Introduce yourself and mention the offer, '
                                  'timing, budget, or next steps.',
                                  style: TextStyle(
                                    color: primaryTextColor.withOpacity(
                                      isDarkMode ? 0.78 : 0.82,
                                    ),
                                    fontSize: 12.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyConversationDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueMuted;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const _EmptyConversationDetailRow({
    required this.label,
    required this.value,
    this.valueMuted = false,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = valueMuted ? secondaryTextColor : primaryTextColor;
    final weight = valueMuted ? FontWeight.w600 : FontWeight.w700;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: weight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationErrorState extends StatelessWidget {
  final String message;
  final bool isDarkMode;
  final Future<void> Function() onRetry;

  const _ConversationErrorState({
    required this.message,
    required this.isDarkMode,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.58)
        : Colors.black.withOpacity(0.54);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.redAccent,
                size: 34,
              ),
              const SizedBox(height: 16),
              Text(
                'Conversation unavailable',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 13.8,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
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

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final s = value.toString().trim().toLowerCase();
  if (s == 'true' || s == '1' || s == 'yes') return true;
  if (s == 'false' || s == '0' || s == 'no') return false;
  return null;
}