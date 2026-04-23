import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:provider/provider.dart';

import '../../conf/theme_provider.dart';
import '../../widgets/primary_button.dart';
import 'verification_success_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  String otpCode = '';
  String? errorMessage;
  bool isLoading = false;

  Future<bool> _checkOtpWithBackend(String code) async {
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace this with your real backend API call
    // Example:
    // final result = await AuthService.verifyEmailOtp(
    //   email: widget.email,
    //   otp: code,
    // );
    // return result;

    return code == '123456';
  }

  Future<void> _verifyOtp(String code) async {
    if (code.length != 6) {
      setState(() {
        errorMessage = 'Please enter the 6-digit verification code.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final isValid = await _checkOtpWithBackend(code);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (isValid) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const VerificationSuccessScreen(),
        ),
      );
    } else {
      setState(() {
        errorMessage = 'Invalid verification code. Please try again.';
      });
    }
  }

  void _resendCode() {
    setState(() {
      errorMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification code resent'),
      ),
    );

    // TODO: Call resend OTP API here
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.7)
        : Colors.black.withOpacity(0.7);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        title: Text(
          'Verify Email',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We sent a verification code to',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: primaryTextColor,
                      selectionHandleColor: primaryTextColor,
                      selectionColor: primaryTextColor.withOpacity(0.25),
                    ),
                  ),
                  child: OtpTextField(
                    numberOfFields: 6,
                    showFieldAsBox: true,
                    showCursor: true,
                    fieldWidth: 40,
                    fieldHeight: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    borderRadius: BorderRadius.circular(12),
                    borderWidth: 1.4,
                    cursorColor: primaryTextColor,
                    enabledBorderColor: isDarkMode
                        ? Colors.white.withOpacity(0.20)
                        : Colors.black.withOpacity(0.20),
                    focusedBorderColor: primaryTextColor,
                    borderColor: isDarkMode
                        ? Colors.white.withOpacity(0.20)
                        : Colors.black.withOpacity(0.20),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: TextStyle(
                      color: primaryTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                    onCodeChanged: (String code) {
                      setState(() {
                        otpCode = code;
                        errorMessage = null;
                      });
                    },
                    onSubmit: (String verificationCode) {
                      _verifyOtp(verificationCode);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Enter the 6-digit code sent to your email.',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.6)
                      : Colors.black.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      text: 'Verify Email',
                      onPressed: () => _verifyOtp(otpCode),
                      isDarkMode: isDarkMode,
                    ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _resendCode,
                  child: Text(
                    'Resend code',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}