import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/foundation.dart';

import '../../../conf/theme_provider.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/gender_dropdown.dart';
import '../../../widgets/phone_text_field.dart';
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
  final TextEditingController phoneController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedGender;
  String fullPhoneNumber = '';

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      nameController.text = 'Test Client';
      emailController.text = 'clienttest@gmail.com';
      passwordController.text = 'Test123';
      confirmPasswordController.text = 'Test123';
      phoneController.text = '12345678';
      fullPhoneNumber = '+21612345678';
      selectedGender = 'Male';
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
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

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (fullPhoneNumber.isEmpty) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  Future<void> _handleSignUp() async {
  FocusScope.of(context).unfocus();

  if (!_formKey.currentState!.validate()) return;

  Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EmailVerificationScreen(
          email: emailController.text.trim(),
        ),
      ),
  );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            labelText: 'Name *',
            hintText: 'Enter your name',
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedUser,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.7),
              size: 18,
            ),
            controller: nameController,
            validator: _validateName,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            labelText: 'Email *',
            hintText: 'Enter your email',
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedMail01,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.7),
              size: 18,
            ),
            keyboardType: TextInputType.emailAddress,
            controller: emailController,
            validator: _validateEmail,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            labelText: 'Password *',
            hintText: 'Enter your password',
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedLock,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.7),
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
                color: isDarkMode
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.7),
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
            labelText: 'Confirm Password *',
            hintText: 'Confirm your password',
            prefixIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedLock,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.7),
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
                color: isDarkMode
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.7),
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
          PhoneTextField(
            labelText: 'Your mobile number *',
            controller: phoneController,
            isDarkMode: isDarkMode,
            onChangedFullPhone: (value) {
              fullPhoneNumber = value;
            },
            validator: _validatePhone,
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
          const SizedBox(height: 24),
          PrimaryButton(
            text: _isLoading ? 'Signing Up...' : 'Sign Up',
            onPressed: _isLoading ? () {} : _handleSignUp,
            isOutlined: false,
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
    phoneController.dispose();
    super.dispose();
  }
}