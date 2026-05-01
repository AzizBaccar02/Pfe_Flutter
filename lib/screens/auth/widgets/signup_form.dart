import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../conf/theme_provider.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/gender_dropdown.dart';
import '../../../widgets/primary_button.dart';
import '../email_verification_screen.dart';
import 'terms_text.dart';

class SignupForm extends StatefulWidget {
  final String role;

  const SignupForm({
    super.key,
    required this.role,
  });

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedGender;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

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
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AuthService.signUp(
        username: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        role: widget.role,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: response.user.email,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to create account. Please try again.';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    final iconColor = isDarkMode
        ? Colors.white.withOpacity(0.7)
        : Colors.black.withOpacity(0.7);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            label: 'Name *',
            hint: 'Enter your name',
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedUser,
              color: iconColor,
              size: 18,
            ),
            controller: nameController,
            validator: _validateName,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Email *',
            hint: 'Enter your email',
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedMail01,
              color: iconColor,
              size: 18,
            ),
            keyboardType: TextInputType.emailAddress,
            controller: emailController,
            validator: _validateEmail,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Password *',
            hint: 'Enter your password',
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedLock,
              color: iconColor,
              size: 18,
            ),
            obscureText: !_isPasswordVisible,
            controller: passwordController,
            validator: _validatePassword,
            isDarkMode: isDarkMode,
            suffixIcon: IconButton(
              icon: HugeIcon(
                icon: _isPasswordVisible
                    ? HugeIcons.strokeRoundedViewOffSlash
                    : HugeIcons.strokeRoundedView,
                color: iconColor,
                size: 16,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Confirm Password *',
            hint: 'Confirm your password',
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedLock,
              color: iconColor,
              size: 18,
            ),
            obscureText: !_isConfirmPasswordVisible,
            controller: confirmPasswordController,
            validator: _validateConfirmPassword,
            isDarkMode: isDarkMode,
            suffixIcon: IconButton(
              icon: HugeIcon(
                icon: _isConfirmPasswordVisible
                    ? HugeIcons.strokeRoundedViewOffSlash
                    : HugeIcons.strokeRoundedView,
                color: iconColor,
                size: 16,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          GenderDropdown(
            label: 'Gender',
            selectedGender: selectedGender,
            onChanged: (value) {
              setState(() {
                selectedGender = value;
              });
            },
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 24),
          TermsText(isDarkMode: isDarkMode),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            text: _isLoading ? 'Signing Up...' : 'Sign Up',
            onPressed: _isLoading ? () {} : _handleSignUp,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}