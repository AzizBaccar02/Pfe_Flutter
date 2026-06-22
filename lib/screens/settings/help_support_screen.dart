import 'package:flutter/material.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../conf/theme_provider.dart';
import '../../services/support_service.dart';
import 'widgets/settings_section_title.dart';
import 'widgets/settings_tile.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _showFaqs(BuildContext context, bool isDarkMode) {
    final backgroundColor =
        isDarkMode ? const Color(0xFF101010) : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF181818) : const Color(0xFFF6F6F6);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);

    final faqs = [
      (
        'How do I create an offer?',
        'Go to the Add tab from the bottom navigation, complete the offer details, and publish it so agents can discover it.'
      ),
      (
        'How do matches work?',
        'When an interested agent appears in your deck and you accept them, the match is created instantly and the conversation becomes available in Chats.'
      ),
      (
        'Where can I find my conversations?',
        'All active and matched conversations appear in the Chats tab, where unread messages are also highlighted.'
      ),
      (
        'How do I update my profile?',
        'Open the drawer, tap your profile header, then update your information from the profile screen.'
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quick answers to the most common questions about using JobMatch.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: faqs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = faqs[index];

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$1,
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.$2,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 13.5,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFeedbackSheet(
    BuildContext context, {
    required bool isDarkMode,
    required String title,
    required String subtitle,
    required String hint,
    required String buttonLabel,
    required String emptyMessageError,
    required String genericErrorMessage,
    required Future<String> Function(String message) send,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF101010) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => _FeedbackBottomSheet(
        isDarkMode: isDarkMode,
        title: title,
        subtitle: subtitle,
        hint: hint,
        buttonLabel: buttonLabel,
        emptyMessageError: emptyMessageError,
        genericErrorMessage: genericErrorMessage,
        send: send,
      ),
    );

    if (result == null || result.isEmpty) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(result),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showContactSupport(BuildContext context, bool isDarkMode) {
    _showFeedbackSheet(
      context,
      isDarkMode: isDarkMode,
      title: 'Contact Support',
      subtitle:
          'Describe your issue and we will send it to the JobMatch support team.',
      hint: 'Tell us what you need help with...',
      buttonLabel: 'Send Request',
      emptyMessageError: 'Please describe your issue before sending.',
      genericErrorMessage:
          'Unable to send your support request. Please try again.',
      send: (message) => SupportService.sendSupportRequest(message: message),
    );
  }

  void _showBugReport(BuildContext context, bool isDarkMode) {
    _showFeedbackSheet(
      context,
      isDarkMode: isDarkMode,
      title: 'Report a Problem',
      subtitle:
          'Tell us what went wrong and we will send it to the JobMatch support team.',
      hint: 'Describe the bug or unexpected behavior...',
      buttonLabel: 'Submit Report',
      emptyMessageError: 'Please describe the problem before submitting.',
      genericErrorMessage:
          'Unable to send your problem report. Please try again.',
      send: (message) => SupportService.sendProblemReport(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF141414) : const Color(0xFFF5F5F5);
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: AppBackButton(isDarkMode: isDarkMode),
        centerTitle: true,
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 21,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSectionTitle(
                title: 'Support',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    SettingsTile(
                      isDarkMode: isDarkMode,
                      title: 'FAQs',
                      subtitle: 'Find answers to common questions',
                      icon: HugeIcons.strokeRoundedMessage02,
                      onTap: () => _showFaqs(context, isDarkMode),
                    ),
                    Divider(color: borderColor, height: 1),
                    SettingsTile(
                      isDarkMode: isDarkMode,
                      title: 'Contact Support',
                      subtitle: 'Reach the JobMatch support team',
                      icon: HugeIcons.strokeRoundedHeadphones,
                      onTap: () => _showContactSupport(context, isDarkMode),
                    ),
                    Divider(color: borderColor, height: 1),
                    SettingsTile(
                      isDarkMode: isDarkMode,
                      title: 'Report a Problem',
                      subtitle: 'Send feedback or report a bug',
                      icon: HugeIcons.strokeRoundedAlert02,
                      onTap: () => _showBugReport(context, isDarkMode),
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

class _FeedbackBottomSheet extends StatefulWidget {
  final bool isDarkMode;
  final String title;
  final String subtitle;
  final String hint;
  final String buttonLabel;
  final String emptyMessageError;
  final String genericErrorMessage;
  final Future<String> Function(String message) send;

  const _FeedbackBottomSheet({
    required this.isDarkMode,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.buttonLabel,
    required this.emptyMessageError,
    required this.genericErrorMessage,
    required this.send,
  });

  @override
  State<_FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<_FeedbackBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      setState(() => _errorMessage = widget.emptyMessageError);
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final responseMessage = await widget.send(message);
      if (!mounted) return;
      Navigator.pop(context, responseMessage);
    } on SupportServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = widget.genericErrorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldColor =
        widget.isDarkMode ? const Color(0xFF181818) : const Color(0xFFF6F6F6);
    final primaryTextColor = widget.isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = widget.isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 5,
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.title,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _messageController,
            enabled: !_isSending,
            minLines: 4,
            maxLines: 6,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 14.5,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
              ),
              filled: true,
              fillColor: fieldColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSending ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isDarkMode ? Colors.white : Colors.black,
                foregroundColor: widget.isDarkMode ? Colors.black : Colors.white,
                disabledBackgroundColor: widget.isDarkMode
                    ? Colors.white.withOpacity(0.45)
                    : Colors.black.withOpacity(0.45),
                disabledForegroundColor: widget.isDarkMode
                    ? Colors.black.withOpacity(0.55)
                    : Colors.white.withOpacity(0.55),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isSending
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color:
                            widget.isDarkMode ? Colors.black : Colors.white,
                      ),
                    )
                  : Text(
                      widget.buttonLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}