import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';

class SwipeFeedbackOverlay extends StatelessWidget {
  final bool isDarkMode;
  final bool isLike;

  const SwipeFeedbackOverlay({
    super.key,
    required this.isDarkMode,
    required this.isLike,
  });

  @override
  Widget build(BuildContext context) {
    final label = isLike ? 'LIKE' : 'DISLIKE';
    final alignment = isLike ? Alignment.centerLeft : Alignment.centerRight;

    final backgroundColor = isLike
        ? AppColors.accent.withOpacity(isDarkMode ? 0.22 : 0.18)
        : const Color(0xFFFF4D67).withOpacity(isDarkMode ? 0.22 : 0.18);

    final badgeColor =
        isLike ? AppColors.accent : const Color(0xFFFF4D67);

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(34),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLike)
              const HugeIcon(
                icon: HugeIcons.strokeRoundedFavourite,
                color: Colors.white,
                size: 18,
              )
            else
              const Text(
                '×',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}