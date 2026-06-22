import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

import '../../../../models/recommended_offer_model.dart';
import 'ai_matches_theme.dart';
import 'offer_search_filters.dart';

Future<OfferSearchFilters?> showOfferFilterSheet({
  required BuildContext context,
  required bool isDarkMode,
  required OfferSearchFilters current,
  required List<String> categories,
}) {
  return showModalBottomSheet<OfferSearchFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _OfferFilterSheet(
      isDarkMode: isDarkMode,
      initial: current,
      categories: categories,
    ),
  );
}

class _OfferFilterSheet extends StatefulWidget {
  final bool isDarkMode;
  final OfferSearchFilters initial;
  final List<String> categories;

  const _OfferFilterSheet({
    required this.isDarkMode,
    required this.initial,
    required this.categories,
  });

  @override
  State<_OfferFilterSheet> createState() => _OfferFilterSheetState();
}

class _OfferFilterSheetState extends State<_OfferFilterSheet> {
  late int? _locationTier;
  late String? _category;
  late OfferSortMode _sortMode;

  @override
  void initState() {
    super.initState();
    _locationTier = widget.initial.locationTier;
    _category = widget.initial.category;
    _sortMode = widget.initial.sortMode;
  }

  void _reset() {
    setState(() {
      _locationTier = null;
      _category = null;
      _sortMode = OfferSortMode.locationThenNlp;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      widget.initial.copyWith(
        locationTier: _locationTier,
        clearLocationTier: _locationTier == null,
        category: _category,
        clearCategory: _category == null,
        sortMode: _sortMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AiMatchesTheme.cardBackground(widget.isDarkMode);
    final border = AiMatchesTheme.cardBorder(widget.isDarkMode);
    final primary = AiMatchesTheme.primaryText(widget.isDarkMode);
    final secondary = AiMatchesTheme.secondaryText(widget.isDarkMode);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Material(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: secondary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Filters',
                          style: TextStyle(
                            color: primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _reset,
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Location',
                      style: TextStyle(
                        color: secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: 'All areas',
                          selected: _locationTier == null,
                          isDarkMode: widget.isDarkMode,
                          onTap: () => setState(() => _locationTier = null),
                        ),
                        _FilterChip(
                          label: 'In your city',
                          selected: _locationTier ==
                              RecommendedOfferModel.tierSameCity,
                          isDarkMode: widget.isDarkMode,
                          onTap: () => setState(
                            () => _locationTier =
                                RecommendedOfferModel.tierSameCity,
                          ),
                        ),
                        _FilterChip(
                          label: 'Near you',
                          selected: _locationTier ==
                              RecommendedOfferModel.tierNearby,
                          isDarkMode: widget.isDarkMode,
                          onTap: () => setState(
                            () => _locationTier =
                                RecommendedOfferModel.tierNearby,
                          ),
                        ),
                        _FilterChip(
                          label: 'Other locations',
                          selected: _locationTier ==
                              RecommendedOfferModel.tierOther,
                          isDarkMode: widget.isDarkMode,
                          onTap: () => setState(
                            () => _locationTier =
                                RecommendedOfferModel.tierOther,
                          ),
                        ),
                      ],
                    ),
                    if (widget.categories.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Category',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: _category == null,
                            isDarkMode: widget.isDarkMode,
                            onTap: () => setState(() => _category = null),
                          ),
                          for (final cat in widget.categories)
                            _FilterChip(
                              label: cat,
                              selected: _category == cat,
                              isDarkMode: widget.isDarkMode,
                              onTap: () => setState(() => _category = cat),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'Sort by',
                      style: TextStyle(
                        color: secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SortTile(
                      title: 'Location, then best skill match',
                      subtitle:
                          'Prioritizes nearby areas, then strongest skill match',
                      selected: _sortMode == OfferSortMode.locationThenNlp,
                      isDarkMode: widget.isDarkMode,
                      onTap: () => setState(
                        () => _sortMode = OfferSortMode.locationThenNlp,
                      ),
                    ),
                    _SortTile(
                      title: 'Best skills match',
                      subtitle: 'Focuses on skills and keyword relevance',
                      selected: _sortMode == OfferSortMode.bestSkills,
                      isDarkMode: widget.isDarkMode,
                      onTap: () => setState(
                        () => _sortMode = OfferSortMode.bestSkills,
                      ),
                    ),
                    _SortTile(
                      title: 'Nearest first',
                      subtitle:
                          'Shortest distance from your profile location',
                      selected: _sortMode == OfferSortMode.nearest,
                      isDarkMode: widget.isDarkMode,
                      onTap: () => setState(
                        () => _sortMode = OfferSortMode.nearest,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: border)),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  12 + MediaQuery.paddingOf(context).bottom,
                ),
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply filters',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forTheme(isDarkMode);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: true,
      selectedColor: isDarkMode
          ? AppColors.accent.withValues(alpha: 0.2)
          : AppColors.accentSurface,
      labelStyle: TextStyle(
        color: selected ? accent : AiMatchesTheme.secondaryText(isDarkMode),
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
      side: BorderSide(
        color: selected ? accent : AiMatchesTheme.cardBorder(isDarkMode),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _SortTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AiMatchesTheme.primaryText(isDarkMode);
    final secondary = AiMatchesTheme.secondaryText(isDarkMode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color:
                    selected ? AppColors.forTheme(isDarkMode) : secondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
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
