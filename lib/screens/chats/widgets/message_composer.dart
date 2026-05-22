// lib/screens/chats/widgets/message_composer.dart

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isDarkMode;
  final VoidCallback onSend;

  const MessageComposer({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF22C55E);

    final composerColor = isDarkMode ? const Color(0xFF000000) : Colors.white;

    final fieldColor =
        isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF1F2F4);

    final textColor = isDarkMode ? Colors.white : const Color(0xFF111827);

    final hintColor = isDarkMode
        ? Colors.white.withOpacity(0.42)
        : Colors.black.withOpacity(0.38);

    final hasText = controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: composerColor,
        border: Border(
          top: BorderSide(
            color: isDarkMode
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                cursorColor: accentGreen,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  hintStyle: TextStyle(
                    color: hintColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: hasText ? onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: hasText
                    ? accentGreen.withOpacity(isDarkMode ? 0.16 : 0.10)
                    : (isDarkMode
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSent,
                  color: hasText
                      ? accentGreen
                      : (isDarkMode
                          ? Colors.white.withOpacity(0.35)
                          : Colors.black.withOpacity(0.32)),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}