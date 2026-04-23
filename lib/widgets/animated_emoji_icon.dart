import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedIcon extends StatelessWidget {
  final String emoji;
  final double delay;
  
  const AnimatedIcon({
    super.key,
    required this.emoji,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: (500 + delay * 1000).toInt()),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -5 * sin(value * pi)), // sin() is from dart:math
          child: Opacity(
            opacity: value,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
        );
      },
    );
  }
}