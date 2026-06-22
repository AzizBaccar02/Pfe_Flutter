// lib/screens/offers/client/widgets/client_home_search_bar.dart

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'client_home_theme.dart';

class ClientHomeSearchBar extends StatefulWidget {
  final bool isDarkMode;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const ClientHomeSearchBar({
    super.key,
    required this.isDarkMode,
    required this.controller,
    this.onChanged,
  });

  @override
  State<ClientHomeSearchBar> createState() => _ClientHomeSearchBarState();
}

class _ClientHomeSearchBarState extends State<ClientHomeSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final hintColor = ClientHomeTheme.tertiaryText(widget.isDarkMode);
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: ClientHomeTheme.searchFieldBackground(widget.isDarkMode),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ClientHomeTheme.cardBorder(widget.isDarkMode),
        ),
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        style: TextStyle(
          color: ClientHomeTheme.primaryText(widget.isDarkMode),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search your offers…',
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              color: hintColor,
              size: 18,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: _clear,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: hintColor,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
