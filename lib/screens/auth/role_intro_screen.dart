import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'signup_screen.dart';

class RoleIntroScreen extends StatelessWidget {
  final String role;

  const RoleIntroScreen({
    super.key,
    required this.role,
  });

  bool get _isClient => role.toUpperCase() == 'CLIENT';

  String get _roleTitle => _isClient ? 'Client' : 'Agent';

  String get _title => _isClient
      ? 'Find, manage,\nand hire the\nright agent'
      : 'Discover offers,\nsend proposals,\nand grow your work';

  String get _subtitle => _isClient
      ? 'Create offers, review interested agents, and manage everything in one place.'
      : 'Browse relevant offers, connect with clients, and turn opportunities into real work.';

  String get _backgroundImage =>
      _isClient ? 'assets/images/Welcome.jpg' : 'assets/images/Offer1.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _backgroundImage,
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.10),
                  Colors.black.withOpacity(0.28),
                  Colors.black.withOpacity(0.62),
                  Colors.black.withOpacity(0.88),
                  Colors.black,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: _TopBackButton(
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _roleTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.96),
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 54,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF14A800),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      _subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.90),
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SignupScreen(role: role),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14A800),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text(
                        'Create account',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TopBackButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.10),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
            ),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}