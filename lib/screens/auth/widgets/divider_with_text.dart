import 'package:flutter/material.dart';

class DividerWithText extends StatelessWidget {
  final String text;
  final bool isDarkMode;

  const DividerWithText({
    super.key,
    required this.text,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.3)
                : Colors.black.withOpacity(0.3),
            thickness: 0.5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: TextStyle(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.3)
                : Colors.black.withOpacity(0.3),
            thickness: 0.5,
          ),
        ),
      ],
    );
  }
}