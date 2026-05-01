import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../conf/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/social_button.dart';
import '../offers/client/client_main_screen.dart';
import 'complete_profile_prompt_screen.dart';
import 'email_verification_screen.dart';
import 'forgot_password_email_screen.dart';
import 'widgets/auth_prompt.dart';
import 'widgets/divider_with_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      await AuthService.saveLoginSession(response);
      final hasSeenPrompt = await AuthService.hasSeenCompleteProfilePrompt();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (!hasSeenPrompt) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfilePromptScreen(
              role: response.role,
            ),
          ),
          (route) => false,
        );
        return;
      }

      final role = response.role.toUpperCase();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'CLIENT'
              ? const ClientEntryScreen()
              : const AgentEntryPlaceholderScreen(),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      final message = e.message;

      if (message.toLowerCase().contains('verify your email first')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
              email: emailController.text.trim().toLowerCase(),
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = message;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to login. Please try again.';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.70)
        : Colors.black.withOpacity(0.70);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: primaryTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Log In',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back! Please login to your account',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: emailController,
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  isDarkMode: isDarkMode,
                  validator: _validateEmail,
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedMail01,
                    size: 18,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: passwordController,
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  obscureText: !_isPasswordVisible,
                  isDarkMode: isDarkMode,
                  validator: _validatePassword,
                  prefixIcon: HugeIcon(
                    icon: HugeIcons.strokeRoundedLock,
                    size: 18,
                    color: secondaryTextColor,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    icon: HugeIcon(
                      icon: _isPasswordVisible
                          ? HugeIcons.strokeRoundedViewOffSlash
                          : HugeIcons.strokeRoundedView,
                      size: 16,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordEmailScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  text: _isLoading ? 'Logging in...' : 'Log In',
                  onPressed: _isLoading ? () {} : _handleLogin,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 28),
                DividerWithText(
                  text: 'or',
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 20),
                SocialButton(
                  label: 'Log in with Gmail',
                  icon: const Icon(
                    Icons.mail_outline_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  backgroundColor: const Color(0xFFFF4B3E),
                  onTap: () {},
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 14),
                SocialButton(
                  label: 'Log in with Facebook',
                  icon: const Icon(
                    Icons.facebook_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  backgroundColor: const Color(0xFF1877F2),
                  onTap: () {},
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 28),
                AuthPrompt(
                  question: "Don't have an account?",
                  action: 'Create one',
                  onTap: () => Navigator.pop(context),
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}