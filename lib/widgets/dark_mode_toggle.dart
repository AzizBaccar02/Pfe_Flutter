import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../conf/theme_provider.dart';

class DarkModeToggle extends StatelessWidget {
  final ThemeProvider themeProvider;

  const DarkModeToggle({
    super.key,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: HugeIcon(
        icon: HugeIcons.strokeRoundedDarkMode,
        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
        size: 18,
      ),
      onPressed: () {
        themeProvider.toggleTheme();
      },
    );
  }
}