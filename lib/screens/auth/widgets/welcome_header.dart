import 'package:flutter/material.dart';

class WelcomeHeader extends StatelessWidget {
  final bool isDarkMode;

  const WelcomeHeader({
    super.key,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '👔',
            style: TextStyle(fontSize: 64),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'LOOKING FOR\nA JOB?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
            height: 1.2,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Find your perfect job match',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode 
                ? Colors.white.withOpacity(0.7)
                : Colors.black.withOpacity(0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}