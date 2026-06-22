import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:provider/provider.dart';

import '../../conf/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/primary_button.dart';
import '../offers/agent/agent_main_screen.dart';
import '../offers/client/client_main_screen.dart';
import 'complete_profile_prompt_screen.dart';

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
  bool isResending = false;

  Future<void> _verifyOtp(String code) async {
    if (code.trim().length != 6) {
      setState(() {
        errorMessage = 'Please enter the 6-digit verification code.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final message = await AuthService.verifyEmail(
        email: widget.email,
        code: code,
      );

      final role = (await AuthService.getStoredRole() ?? '').toUpperCase();
      final hasSeenPrompt = await AuthService.hasSeenCompleteProfilePrompt();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (!hasSeenPrompt) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfilePromptScreen(
              role: role,
            ),
          ),
          (route) => false,
        );
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => role == 'CLIENT'
              ? const ClientEntryScreen()
              : const AgentEntryScreen(),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.message;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to verify email. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      isResending = true;
      errorMessage = null;
    });

    try {
      final message = await AuthService.resendVerificationCode(
        email: widget.email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Unable to resend code. Please try again.';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isResending = false;
      });
    }
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
        leading: AppBackButton(isDarkMode: isDarkMode),
        title: Text(
          'Verify Email',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  onPressed: isResending ? null : _resendCode,
                  child: Text(
                    isResending ? 'Resending...' : 'Resend code',
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
