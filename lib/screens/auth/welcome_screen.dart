import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/dark_mode_toggle.dart';
import '../../conf/theme_provider.dart';
import 'widgets/welcome_header.dart';
import 'login_screen.dart';
import 'role_selection_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      body: Container(
        color: isDarkMode ? Colors.black : Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: DarkModeToggle(themeProvider: themeProvider),
                ),
                const Spacer(),
                WelcomeHeader(isDarkMode: isDarkMode),
                const SizedBox(height: 48),
                PrimaryButton(
                  text: 'Create an account',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RoleSelectionScreen(),
                      ),
                    );
                  },
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Log In',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  isOutlined: true,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 24),
                Text(
                  'Start your journey today',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.5),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}