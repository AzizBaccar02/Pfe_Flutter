import 'package:flutter/material.dart';

import '../../../widgets/social_button.dart';

class SocialSignup extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback? onGoogleTap;
  final VoidCallback? onFacebookTap;

  const SocialSignup({
    super.key,
    required this.isDarkMode,
    this.onGoogleTap,
    this.onFacebookTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialButton(
          label: 'Sign up with Gmail',
          icon: const Icon(
            Icons.mail_outline_rounded,
            size: 18,
            color: Colors.white,
          ),
          backgroundColor: const Color(0xFFFF4B3E),
          onTap: onGoogleTap ?? () {},
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 14),
        SocialButton(
          label: 'Sign up with Facebook',
          icon: const Icon(
            Icons.facebook_rounded,
            size: 18,
            color: Colors.white,
          ),
          backgroundColor: const Color(0xFF1877F2),
          onTap: onFacebookTap ?? () {},
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }
}