import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../conf/theme_provider.dart';
import '../../widgets/primary_button.dart';
import 'email_verification_screen.dart';

class SignupSuccessScreen extends StatelessWidget {
  final String email;

  const SignupSuccessScreen({
    super.key,
    required this.email,
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 24),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/signup_success.png',
                      height: 260,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 36),
                    Text(
                      "Congratulations, your account has been created. Let's get you started!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              PrimaryButton(
                text: 'Continue',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmailVerificationScreen(email: email),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}