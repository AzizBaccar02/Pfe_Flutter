// lib/screens/chats/widgets/edit_conversation_name_dialog.dart

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

/// Pops with the trimmed custom name, `''` to reset to default, or `null` if cancelled.
class EditConversationNameDialog extends StatefulWidget {
  final String serverName;
  final String initialText;
  final bool isDarkMode;

  const EditConversationNameDialog({
    super.key,
    required this.serverName,
    required this.initialText,
    required this.isDarkMode,
  });

  @override
  State<EditConversationNameDialog> createState() =>
      _EditConversationNameDialogState();
}

class _EditConversationNameDialogState extends State<EditConversationNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.54);
    final shell = isDarkMode ? const Color(0xFF000000) : Colors.white;
    final border =
        isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final fieldFill =
        isDarkMode ? const Color(0xFF141414) : const Color(0xFFF3F4F6);
    const accent = AppColors.accent;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: shell,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: [
            if (!isDarkMode)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
              padding: const EdgeInsets.fromLTRB(18, 16, 6, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Conversation name',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, null),
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
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Only you see this name in the chat list and header.',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Original: ${widget.serverName}',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLength: 48,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: fieldFill,
                      hintText: 'Leave empty to use original name',
                      hintStyle: TextStyle(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: accent,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, ''),
                    child: Text(
                      'Use default',
                      style: TextStyle(
                        color: secondaryTextColor.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, _controller.text.trim()),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
