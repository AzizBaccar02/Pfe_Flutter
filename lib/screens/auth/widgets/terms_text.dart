import 'package:flutter/material.dart';

class TermsText extends StatelessWidget {
  final bool isDarkMode;

  const TermsText({
    super.key,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 12,
          color: isDarkMode 
              ? Colors.white.withOpacity(0.7)
              : Colors.black.withOpacity(0.7),
        ),
        children: [
          const TextSpan(text: 'By signing up, you agree to the '),
          TextSpan(
            text: 'Terms of service',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy policy',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}