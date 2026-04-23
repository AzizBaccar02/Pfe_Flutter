import 'package:flutter/material.dart';

class AuthPrompt extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onTap;
  final bool isDarkMode;

  const AuthPrompt({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          question,
          style: TextStyle(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.7)
                : Colors.black.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}