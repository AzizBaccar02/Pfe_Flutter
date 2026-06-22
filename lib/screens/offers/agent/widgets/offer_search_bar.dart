import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

import 'ai_matches_theme.dart';

class OfferSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isDarkMode;
  final int activeFilterCount;
  final VoidCallback onFilterTap;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const OfferSearchBar({
    super.key,
    required this.controller,
    required this.isDarkMode,
    required this.onFilterTap,
    this.activeFilterCount = 0,
    this.onSubmitted,
    this.onChanged,
    this.onClear,
  });

  @override
  State<OfferSearchBar> createState() => _OfferSearchBarState();
}

class _OfferSearchBarState extends State<OfferSearchBar> {
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

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cardColor = AiMatchesTheme.cardBackground(widget.isDarkMode);
    final borderColor = AiMatchesTheme.cardBorder(widget.isDarkMode);
    final secondary = AiMatchesTheme.secondaryText(widget.isDarkMode);
    final primary = AiMatchesTheme.primaryText(widget.isDarkMode);
    final hasText = widget.controller.text.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                color: primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search offers, skills, categories…',
                hintStyle: TextStyle(
                  color: secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: secondary,
                  size: 20,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                suffixIcon: hasText
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: secondary,
                          size: 18,
                        ),
                        onPressed: widget.onClear,
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: widget.onFilterTap,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.activeFilterCount > 0
                      ? AppColors.forTheme(widget.isDarkMode)
                      : borderColor,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: primary.withValues(alpha: 0.75),
                    size: 20,
                  ),
                  if (widget.activeFilterCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardColor, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
