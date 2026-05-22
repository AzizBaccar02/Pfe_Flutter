import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../conf/theme_provider.dart';
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

  void _showContactSupport(BuildContext context, bool isDarkMode) {
    final messageController = TextEditingController();
    final backgroundColor =
        isDarkMode ? const Color(0xFF101010) : Colors.white;
    final fieldColor =
        isDarkMode ? const Color(0xFF181818) : const Color(0xFFF6F6F6);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
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
                'Contact Support',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Describe your issue and the frontend will prepare your support request.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: messageController,
                minLines: 4,
                maxLines: 6,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 14.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Tell us what you need help with...',
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
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Your support request has been prepared successfully.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.white : Colors.black,
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Send Request',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBugReport(BuildContext context, bool isDarkMode) {
    final bugController = TextEditingController();
    final backgroundColor =
        isDarkMode ? const Color(0xFF101010) : Colors.white;
    final fieldColor =
        isDarkMode ? const Color(0xFF181818) : const Color(0xFFF6F6F6);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
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
                'Report a Problem',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us what went wrong so the issue can be reviewed later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: bugController,
                minLines: 4,
                maxLines: 6,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 14.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Describe the bug or unexpected behavior...',
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
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Your problem report has been saved successfully.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.white : Colors.black,
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Submit Report',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: isDarkMode ? Colors.white : Colors.black,
            size: 20,
          ),
        ),
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