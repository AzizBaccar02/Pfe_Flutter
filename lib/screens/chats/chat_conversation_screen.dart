// lib/screens/chats/chat_conversation_screen.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../conf/theme_provider.dart';
import '../../models/chat_conversation_summary_model.dart';
import '../../models/chat_message_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_composer.dart';

class ChatConversationScreen extends StatefulWidget {
  final ChatConversationSummaryModel chat;

  const ChatConversationScreen({
    super.key,
    required this.chat,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  static const int _pageSize = 10;
  static const Duration _readReceiptSyncInterval = Duration(seconds: 20);

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  WebSocketChannel? _socketChannel;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _readReceiptTimer;

  bool _isLoading = true;
  bool _isSending = false;
  bool _isSocketConnected = false;
  bool _isSyncingReadReceipts = false;
  bool _isLoadingOlderMessages = false;
  bool _hasMoreMessages = true;
  bool _isMessageActionRunning = false;

  String? _errorMessage;
  int _currentUserId = 0;
  int? _nextBeforeMessageId;
  int _newMessagesCount = 0;

  List<ChatMessageModel> _messages = [];

  int get _clientId => widget.chat.client?.id ?? 0;
  int get _agentId => widget.chat.agent?.id ?? 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _bootstrapConversation();
  }

  @override
  void dispose() {
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

    if (!mounted) return;

    setState(() {
      _currentUserId = storedUserId ?? 0;
    });

    await _loadInitialMessages(markRead: true);
    await _connectSocket();

    _startReadReceiptSync();
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

  Future<void> _connectSocket() async {
    try {
      await _socketSubscription?.cancel();
      await _socketChannel?.sink.close();

      final channel = await ChatService.connectToChatSocket(
        chatId: widget.chat.id,
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
        chat: widget.chat,
        limit: _pageSize,
      );

      if (markRead) {
        await ChatService.markAllMessagesAsRead(chatId: widget.chat.id);
      }

      if (!mounted) return;

      setState(() {
        _messages = _sortMessages(page.messages);
        _hasMoreMessages = page.hasMore;
        _nextBeforeMessageId = page.nextBefore;
        _newMessagesCount = 0;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(jump: true);
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

    final previousMaxScrollExtent = _scrollController.position.maxScrollExtent;
    final previousPixels = _scrollController.position.pixels;

    setState(() {
      _isLoadingOlderMessages = true;
    });

    try {
      final page = await ChatService.getMessagesPage(
        chat: widget.chat,
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
        if (!_scrollController.hasClients) return;

        final newMaxScrollExtent = _scrollController.position.maxScrollExtent;
        final addedHeight = newMaxScrollExtent - previousMaxScrollExtent;
        final targetOffset = previousPixels + addedHeight;

        _scrollController.jumpTo(
          targetOffset.clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          ),
        );
      });
    } catch (_) {
      // Loading older messages should not break the current conversation view.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOlderMessages = false;
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
        chat: widget.chat,
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
          (message) => message.id == freshMessage.id,
        );

        if (!alreadyExists) {
          changed = true;
          mergedMessages.add(freshMessage);

          if (!wasNearBottom && freshMessage.senderId != _currentUserId) {
            _newMessagesCount += 1;
          }
        }
      }

      if (!changed) return;

      setState(() {
        _messages = _sortMessages(mergedMessages);
      });

      if (wasNearBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
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
    if (temporaryMessage.id >= 0) return false;

    final sameSender = temporaryMessage.senderId == serverMessage.senderId;
    final sameText = temporaryMessage.text.trim() == serverMessage.text.trim();

    final secondsDiff = serverMessage.sentAt
        .difference(temporaryMessage.sentAt)
        .inSeconds
        .abs();

    return sameSender && sameText && secondsDiff <= 10;
  }

  void _handleSocketEvent(dynamic event) {
    try {
      final decoded = event is String ? jsonDecode(event) : event;

      if (decoded is! Map) return;

      final data = Map<String, dynamic>.from(decoded);
      final type = data['type']?.toString();

      if (type == 'new_message') {
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

      if (type == 'message_deleted' || type == 'chat_message_deleted') {
        _handleSocketMessageDeleted(data);
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
    );

    if (message.id == 0 && message.text.trim().isEmpty) return;

    final wasNearBottom = _isNearBottom();
    final isIncoming = message.senderId != _currentUserId;

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
        final withoutOptimisticDuplicate = _messages.where((item) {
          final isTemporary = item.id < 0;
          final sameText = item.text.trim() == message.text.trim();
          final sameSender = item.senderId == message.senderId;

          return !(isTemporary && sameText && sameSender);
        }).toList();

        _messages = _sortMessages([...withoutOptimisticDuplicate, message]);

        if (!wasNearBottom && isIncoming) {
          _newMessagesCount += 1;
        }
      }
    });

    if (isIncoming) {
      ChatService.markAllMessagesAsRead(chatId: widget.chat.id).then((_) {
        _syncReadReceiptsSilently();
      });
    }

    if (wasNearBottom || !isIncoming) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _handleSocketMessageSeen(Map<String, dynamic> data) {
    final messageId =
        _parseInt(data['message_id']) ?? _parseInt(data['messageId']);

    final readerId = _parseInt(data['reader_id']) ?? _parseInt(data['readerId']);

    if (!mounted) return;

    if (messageId != null) {
      setState(() {
        _messages = _messages.map((message) {
          if (message.id == messageId) {
            return message.copyWith(isRead: true);
          }

          return message;
        }).toList();
      });

      return;
    }

    if (readerId != null && readerId != _currentUserId) {
      setState(() {
        _messages = _messages.map((message) {
          if (message.senderId == _currentUserId) {
            return message.copyWith(isRead: true);
          }

          return message;
        }).toList();
      });

      return;
    }

    _syncReadReceiptsSilently();
  }

  void _handleSocketMessagesSeen(Map<String, dynamic> data) {
    final readerId = _parseInt(data['reader_id']) ?? _parseInt(data['readerId']);

    if (!mounted) return;

    if (readerId != null && readerId != _currentUserId) {
      setState(() {
        _messages = _messages.map((message) {
          if (message.senderId == _currentUserId) {
            return message.copyWith(isRead: true);
          }

          return message;
        }).toList();
      });
    }
  }

  void _handleSocketMessageUpdated(Map<String, dynamic> data) {
    final rawMessage = data['message'];

    if (rawMessage is! Map) return;

    final updatedMessage = ChatMessageModel.fromJson(
      json: Map<String, dynamic>.from(rawMessage),
      clientId: _clientId,
      agentId: _agentId,
    );

    if (updatedMessage.id <= 0) return;
    if (!mounted) return;

    setState(() {
      _messages = _messages.map((message) {
        if (message.id == updatedMessage.id) {
          return updatedMessage;
        }

        return message;
      }).toList();
    });
  }

  void _handleSocketMessageDeleted(Map<String, dynamic> data) {
    final rawMessage = data['message'];

    final messageId = _parseInt(data['message_id']) ??
        _parseInt(data['messageId']) ??
        (rawMessage is Map ? _parseInt(rawMessage['id']) : null);

    if (messageId == null) return;
    if (!mounted) return;

    setState(() {
      _messages = _messages.where((message) => message.id != messageId).toList();
    });
  }

  void _scrollToBottom({bool jump = false}) {
    if (!_scrollController.hasClients) return;

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
      chatId: widget.chat.id,
      senderId: _currentUserId,
      clientId: _clientId,
      agentId: _agentId,
      text: text,
    );

    setState(() {
      _messages = _sortMessages([..._messages, optimisticMessage]);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      if (_socketChannel != null && _isSocketConnected) {
        ChatService.sendSocketMessage(
          channel: _socketChannel!,
          content: text,
        );
      } else {
        final message = await ChatService.sendMessage(
          chat: widget.chat,
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

      await _syncReadReceiptsSilently();
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

  Future<void> _showMessageActions(ChatMessageModel message) async {
    if (message.senderId != _currentUserId || message.id <= 0) return;
    if (_isMessageActionRunning) return;

    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final backgroundColor =
            isDarkMode ? const Color(0xFF111827) : Colors.white;
        final primaryTextColor =
            isDarkMode ? Colors.white : const Color(0xFF111827);
        final secondaryTextColor = isDarkMode
            ? Colors.white.withOpacity(0.58)
            : Colors.black.withOpacity(0.54);

        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: secondaryTextColor.withOpacity(0.38),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                _MessageActionTile(
                  icon: Icons.edit_rounded,
                  title: 'Edit message',
                  subtitle: 'Update the content of this message',
                  color: const Color(0xFF22C55E),
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showEditMessageSheet(message);
                  },
                ),
                const SizedBox(height: 8),
                _MessageActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete message',
                  subtitle: 'Remove this message from the conversation',
                  color: Colors.redAccent,
                  primaryTextColor: primaryTextColor,
                  secondaryTextColor: secondaryTextColor,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDeleteMessage(message);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditMessageSheet(ChatMessageModel message) async {
    if (message.senderId != _currentUserId || message.id <= 0) return;

    final controller = TextEditingController(text: message.text);
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            final backgroundColor =
                isDarkMode ? const Color(0xFF111827) : Colors.white;
            final fieldColor =
                isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);
            final primaryTextColor =
                isDarkMode ? Colors.white : const Color(0xFF111827);
            final secondaryTextColor = isDarkMode
                ? Colors.white.withOpacity(0.58)
                : Colors.black.withOpacity(0.54);

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 26,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: secondaryTextColor.withOpacity(0.38),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Edit message',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Make your changes and save.',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: fieldColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          minLines: 1,
                          maxLines: 5,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Message',
                            hintStyle: TextStyle(
                              color: secondaryTextColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.pop(sheetContext),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryTextColor,
                                side: BorderSide(
                                  color: secondaryTextColor.withOpacity(0.22),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final updatedText =
                                          controller.text.trim();

                                      if (updatedText.isEmpty) {
                                        _showErrorSnackBar(
                                          'Message cannot be empty.',
                                        );
                                        return;
                                      }

                                      if (updatedText == message.text.trim()) {
                                        Navigator.pop(sheetContext);
                                        return;
                                      }

                                      setSheetState(() {
                                        isSaving = true;
                                      });

                                      final success =
                                          await _handleUpdateMessage(
                                        message: message,
                                        updatedText: updatedText,
                                      );

                                      if (!mounted) return;

                                      if (success) {
                                        Navigator.pop(sheetContext);
                                      } else {
                                        setSheetState(() {
                                          isSaving = false;
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22C55E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Save',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<bool> _handleUpdateMessage({
    required ChatMessageModel message,
    required String updatedText,
  }) async {
    if (_isMessageActionRunning) return false;

    setState(() {
      _isMessageActionRunning = true;
    });

    try {
      final updatedMessage = await ChatService.updateMessage(
        chat: widget.chat,
        messageId: message.id,
        content: updatedText,
      );

      if (!mounted) return false;

      setState(() {
        _messages = _messages.map((item) {
          if (item.id == updatedMessage.id) {
            return updatedMessage;
          }

          return item;
        }).toList();
      });

      return true;
    } on ChatServiceException catch (e) {
      _showErrorSnackBar(e.message);
      return false;
    } catch (_) {
      _showErrorSnackBar('Unable to update message.');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isMessageActionRunning = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteMessage(ChatMessageModel message) async {
    if (message.senderId != _currentUserId || message.id <= 0) return;

    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final backgroundColor =
            isDarkMode ? const Color(0xFF111827) : Colors.white;
        final primaryTextColor =
            isDarkMode ? Colors.white : const Color(0xFF111827);
        final secondaryTextColor = isDarkMode
            ? Colors.white.withOpacity(0.58)
            : Colors.black.withOpacity(0.54);

        return AlertDialog(
          backgroundColor: backgroundColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Delete message?',
            style: TextStyle(
              color: primaryTextColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'This message will be removed from the conversation for both users.',
            style: TextStyle(
              color: secondaryTextColor,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _handleDeleteMessage(message);
    }
  }

  Future<void> _handleDeleteMessage(ChatMessageModel message) async {
    if (_isMessageActionRunning) return;

    setState(() {
      _isMessageActionRunning = true;
    });

    try {
      final deletedMessageId = await ChatService.deleteMessage(
        chat: widget.chat,
        messageId: message.id,
      );

      if (!mounted) return;

      setState(() {
        _messages = _messages
            .where((item) => item.id != deletedMessageId)
            .toList();
      });
    } on ChatServiceException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (_) {
      _showErrorSnackBar('Unable to delete message.');
    } finally {
      if (mounted) {
        setState(() {
          _isMessageActionRunning = false;
        });
      }
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
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  List<ChatMessageModel> _sortMessages(List<ChatMessageModel> messages) {
    final sortedMessages = [...messages];
    sortedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return sortedMessages;
  }

  List<_TimelineItem> _buildTimelineItems(List<ChatMessageModel> messages) {
    final items = <_TimelineItem>[];
    DateTime? previousDate;

    for (final message in messages) {
      final currentDate = DateTime(
        message.sentAt.year,
        message.sentAt.month,
        message.sentAt.day,
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

    const accentGreen = Color(0xFF22C55E);

    final backgroundColor =
        isDarkMode ? const Color(0xFF0B0F14) : const Color(0xFFEDEDED);

    final appBarColor = isDarkMode ? const Color(0xFF0B0F14) : Colors.white;

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
        toolbarHeight: 58,
        leadingWidth: 42,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: accentGreen,
            size: 18,
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: isDarkMode
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFE5E7EB),
              child: Text(
                widget.chat.displayInitials,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.chat.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.chat.otherUser?.role ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _isSocketConnected
                              ? accentGreen
                              : secondaryTextColor.withOpacity(0.50),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
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
        name: widget.chat.displayName,
        offerTitle: widget.chat.offerTitle,
        isDarkMode: isDarkMode,
      );
    }

    final timelineItems = _buildTimelineItems(_messages);

    return Stack(
      children: [
        RefreshIndicator(
          color: accentGreen,
          onRefresh: () async {
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
              final isMine = message.senderId == _currentUserId;

              return MessageBubble(
                message: message,
                isDarkMode: isDarkMode,
                isMine: isMine,
                avatarInitials: widget.chat.displayInitials,
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
                onTap: () => _scrollToBottom(),
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

class _MessageActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;

  const _MessageActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12.2,
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: isVisible ? 46 : 12,
      alignment: Alignment.center,
      child: isVisible
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.72)
                    : Colors.black.withOpacity(0.48),
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
  final String name;
  final String offerTitle;
  final bool isDarkMode;

  const _EmptyConversationState({
    required this.name,
    required this.offerTitle,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF22C55E);

    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.58)
        : Colors.black.withOpacity(0.54);

    final firstName = name.trim().isEmpty ? 'your match' : name.split(' ').first;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.18 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(isDarkMode ? 0.14 : 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: accentGreen,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Start the conversation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Send your first message to $firstName about "$offerTitle".',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 13.8,
                  height: 1.5,
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
                  backgroundColor: const Color(0xFF22C55E),
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