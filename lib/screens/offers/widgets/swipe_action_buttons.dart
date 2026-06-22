import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';

class SwipeActionButtons extends StatelessWidget {
  final VoidCallback onDislike;
  final VoidCallback onLike;
  final bool isDarkMode;

  const SwipeActionButtons({
    super.key,
    required this.onDislike,
    required this.onLike,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SwipeCircleIconButton(
          onTap: onDislike,
          isDarkMode: isDarkMode,
          backgroundColor: const Color(0xFFFF4D67),
          elevation: 10,
          child: const Text(
            '×',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 24),
        _SwipeCircleIconButton(
          onTap: onLike,
          isDarkMode: isDarkMode,
          backgroundColor: AppColors.accent,
          elevation: 10,
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedFavourite,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }
}

class _SwipeCircleIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDarkMode;
  final Widget child;
  final Color? backgroundColor;
  final double elevation;

  const _SwipeCircleIconButton({
    required this.onTap,
    required this.isDarkMode,
    required this.child,
    this.backgroundColor,
    this.elevation = 8,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor =
        backgroundColor ?? (isDarkMode ? const Color(0xFF161616) : Colors.white);

    return Material(
      color: buttonColor,
      shape: const CircleBorder(),
      elevation: elevation,
      shadowColor: Colors.black.withOpacity(0.14),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Center(child: child),
        ),
      ),
    );
  }
}