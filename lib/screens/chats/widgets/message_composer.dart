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
    const accentYellow = Color(0xFFFFC107);
    const accentYellowSoft = Color(0xFFFFE082);
    const accentYellowDeep = Color(0xFF5D4200);

    final fieldColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFF3F3F3);

    final hintColor = isDarkMode
        ? Colors.white.withOpacity(0.48)
        : Colors.black.withOpacity(0.46);

    final iconColor = isDarkMode ? Colors.white : Colors.black;

    final hasText = controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Write a message...',
                  hintStyle: TextStyle(
                    color: hintColor,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: hasText ? onSend : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: hasText
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          accentYellowSoft,
                          accentYellow,
                        ],
                      )
                    : null,
                color: hasText
                    ? null
                    : (isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSent,
                  color: hasText
                      ? accentYellowDeep
                      : iconColor.withOpacity(0.42),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}