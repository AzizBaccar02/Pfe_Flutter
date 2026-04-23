import 'package:flutter/material.dart';

import 'swipe_feedback_overlay.dart';

class SwipeDeck<T> extends StatelessWidget {
  final List<T> items;
  final bool isDarkMode;
  final void Function(T item, bool liked) onSwiped;
  final Widget Function(BuildContext context, T item) topCardBuilder;
  final Widget Function(
    BuildContext context,
    T item,
    double scale,
    double opacity,
  ) previewCardBuilder;
  final Widget emptyState;
  final String Function(T item, int remainingCount) dismissKeyBuilder;

  const SwipeDeck({
    super.key,
    required this.items,
    required this.isDarkMode,
    required this.onSwiped,
    required this.topCardBuilder,
    required this.previewCardBuilder,
    required this.emptyState,
    required this.dismissKeyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return emptyState;

    final currentItem = items[0];
    final nextItem = items.length > 1 ? items[1] : null;
    final thirdItem = items.length > 2 ? items[2] : null;

    return Stack(
      children: [
        if (thirdItem != null)
          Positioned(
            left: 16,
            right: 16,
            top: 28,
            bottom: 0,
            child: IgnorePointer(
              child: previewCardBuilder(
                context,
                thirdItem,
                0.94,
                0.18,
              ),
            ),
          ),
        if (nextItem != null)
          Positioned(
            left: 8,
            right: 8,
            top: 14,
            bottom: 0,
            child: IgnorePointer(
              child: previewCardBuilder(
                context,
                nextItem,
                0.97,
                0.28,
              ),
            ),
          ),
        Positioned.fill(
          child: Dismissible(
            key: ValueKey(
              dismissKeyBuilder(currentItem, items.length),
            ),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) {
              onSwiped(
                currentItem,
                direction == DismissDirection.startToEnd,
              );
            },
            background: SwipeFeedbackOverlay(
              isDarkMode: isDarkMode,
              isLike: true,
            ),
            secondaryBackground: SwipeFeedbackOverlay(
              isDarkMode: isDarkMode,
              isLike: false,
            ),
            child: topCardBuilder(context, currentItem),
          ),
        ),
      ],
    );
  }
}