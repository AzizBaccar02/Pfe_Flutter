// lib/screens/chats/widgets/edit_message_dialog.dart

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

import '../../../models/chat_conversation_summary_model.dart';
import '../../../models/chat_message_model.dart';
import '../../../services/chat_service.dart';

/// Modal to edit a chat message. Pops with [ChatMessageModel] on success.
class EditMessageDialog extends StatefulWidget {
  final ChatMessageModel message;
  final ChatConversationSummaryModel conversation;
  final bool isDarkMode;

  const EditMessageDialog({
    super.key,
    required this.message,
    required this.conversation,
    required this.isDarkMode,
  });

  @override
  State<EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<EditMessageDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updatedText = _controller.text.trim();

    if (updatedText.isEmpty) {
      setState(() => _errorText = 'Message cannot be empty.');
      return;
    }

    if (updatedText == widget.message.text.trim()) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final updated = await ChatService.updateMessage(
        chat: widget.conversation,
        messageId: widget.message.id,
        content: updatedText,
      );

      if (!mounted) return;
      Navigator.pop(context, updated);
    } on ChatServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = 'Unable to update message.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final shell = isDarkMode ? const Color(0xFF000000) : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.54);
    final border =
        isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final fieldFill =
        isDarkMode ? const Color(0xFF141414) : const Color(0xFFF3F4F6);
    const accent = AppColors.accent;
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardBottom),
      child: Dialog(
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
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 6, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit message',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
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
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Make your changes and save.',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Divider(height: 1, thickness: 1, color: border),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: fieldFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        minLines: 3,
                        maxLines: 6,
                        enabled: !_isSaving,
                        cursorColor: accent,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w600,
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
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.pop(context),
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
                            onPressed: _isSaving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  accent.withValues(alpha: 0.45),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
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
            ],
          ),
        ),
      ),
    );
  }
}
