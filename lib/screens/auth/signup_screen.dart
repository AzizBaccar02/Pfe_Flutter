import 'package:flutter/material.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:provider/provider.dart';

import '../../conf/theme_provider.dart';
import 'login_screen.dart';
import 'widgets/auth_prompt.dart';
import 'widgets/signup_form.dart';

class SignupScreen extends StatelessWidget {
  final String role;

  const SignupScreen({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
        leading: AppBackButton(isDarkMode: isDarkMode),
        title: Text(
          'Sign Up',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign up with your email or phone number',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              SignupForm(role: role),

              const SizedBox(height: 24),
              AuthPrompt(
                question: 'Already have an account?',
                action: 'Sign in',
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}