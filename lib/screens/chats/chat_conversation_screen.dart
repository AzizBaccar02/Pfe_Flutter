import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../conf/theme_provider.dart';
import '../../data/mock_chat_data.dart';
import '../../models/chat_message_model.dart';
import '../../models/interested_agent_model.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_composer.dart';

class ChatConversationScreen extends StatefulWidget {
  final InterestedAgentModel agent;

  const ChatConversationScreen({
    super.key,
    required this.agent,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
    _reloadMessages(markRead: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(jump: true);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _reloadMessages({bool markRead = false}) {
    if (markRead) {
      MockChatData.markConversationAsRead(widget.agent.id);
    }

    _messages = MockChatData.getMessagesForAgent(widget.agent.id);
    if (mounted) {
      setState(() {});
    }
  }

  void _scrollToBottom({bool jump = false}) {
    if (!_scrollController.hasClients) return;

    final target = _scrollController.position.maxScrollExtent + 80;

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
    if (text.isEmpty) return;

    MockChatData.sendClientMessage(
      agentId: widget.agent.id,
      text: text,
    );

    _messageController.clear();
    _reloadMessages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    MockChatData.sendAgentAutoReply(
      agentId: widget.agent.id,
      text: _buildAutoReply(),
    );
    MockChatData.markConversationAsRead(widget.agent.id);

    _reloadMessages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  String _buildAutoReply() {
    final replies = [
      'Perfect, I can take care of that.',
      'That works for me. I will confirm the timing shortly.',
      'Thanks, I saw your message. I am available.',
      'Great, I will prepare everything needed for this job.',
    ];

    final sentCount = _messages.where((message) => message.isFromClient).length;
    return replies[sentCount % replies.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);
        
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: primaryTextColor,
            size: 20,
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(widget.agent.imageUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.agent.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.agent.jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withOpacity(isDarkMode ? 0.10 : 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFFFC107).withOpacity(isDarkMode ? 0.18 : 0.24),
                ),
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedBriefcase01,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.78)
                        : Colors.black.withOpacity(0.78),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Matched on: ${widget.agent.offerTitle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        'Start the conversation with ${widget.agent.name.split(' ').first}.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(
                        message: _messages[index],
                        isDarkMode: isDarkMode,
                      );
                    },
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
                  onSend: _handleSend,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}