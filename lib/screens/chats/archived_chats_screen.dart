// lib/screens/chats/archived_chats_screen.dart

import 'package:flutter/material.dart';

import '../../models/chat_conversation_summary_model.dart';
import 'widgets/chat_tile.dart';

class ArchivedChatsScreen extends StatefulWidget {
  final List<ChatConversationSummaryModel> chats;
  final int currentUserId;
  final Color backgroundColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final String Function(DateTime?) formatTrailingTime;
  final String Function(ChatConversationSummaryModel chat) conversationTitleFor;
  final Future<void> Function(ChatConversationSummaryModel chat) onOpenConversation;
  final Future<void> Function(ChatConversationSummaryModel chat) onCloseOffer;
  final Future<void> Function(ChatConversationSummaryModel chat) onDeleteChat;
  final Future<void> Function(ChatConversationSummaryModel chat) onUnarchive;

  const ArchivedChatsScreen({
    super.key,
    required this.chats,
    required this.currentUserId,
    required this.backgroundColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.formatTrailingTime,
    required this.conversationTitleFor,
    required this.onOpenConversation,
    required this.onCloseOffer,
    required this.onDeleteChat,
    required this.onUnarchive,
  });

  @override
  State<ArchivedChatsScreen> createState() => _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends State<ArchivedChatsScreen> {
  late List<ChatConversationSummaryModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List<ChatConversationSummaryModel>.of(widget.chats);
  }

  Future<void> _handleUnarchive(ChatConversationSummaryModel chat) async {
    await widget.onUnarchive(chat);
    if (!mounted) return;
    setState(() {
      _items.removeWhere((c) => c.id == chat.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: widget.primaryTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Archived',
          style: TextStyle(
            color: widget.primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: _items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No archived conversations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.secondaryTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                for (final chat in _items)
                  ChatTile(
                    chat: chat,
                    currentUserId: widget.currentUserId,
                    conversationTitle: widget.conversationTitleFor(chat),
                    trailingText: widget.formatTrailingTime(chat.lastActivityDate),
                    primaryTextColor: widget.primaryTextColor,
                    secondaryTextColor: widget.secondaryTextColor,
                    onTap: () => widget.onOpenConversation(chat),
                    onCloseOffer: () => widget.onCloseOffer(chat),
                    onDeleteChat: () => widget.onDeleteChat(chat),
                    onArchiveChat: null,
                    onUnarchive: () => _handleUnarchive(chat),
                    slidableGroupTag: 'archived_chats_screen',
                  ),
              ],
            ),
    );
  }
}
