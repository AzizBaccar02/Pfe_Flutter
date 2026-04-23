import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../conf/theme_provider.dart';
import 'widgets/session_card.dart';
import 'widgets/settings_section_title.dart';
import 'widgets/settings_switch_tile.dart';
import 'widgets/settings_tile.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _loginAlerts = true;
  bool _biometricUnlock = false;
  bool _rememberTrustedDevice = true;
  bool _twoStepVerification = false;

  final List<SessionCardData> _sessions = [
    const SessionCardData(
      deviceName: 'Pixel 8 Pro',
      deviceType: 'Current device',
      location: 'Tunis, Tunisia',
      lastActive: 'Active now',
      isCurrent: true,
    ),
    const SessionCardData(
      deviceName: 'Chrome on Windows',
      deviceType: 'Web session',
      location: 'Tunis, Tunisia',
      lastActive: '2 hours ago',
    ),
    const SessionCardData(
      deviceName: 'Samsung Galaxy A54',
      deviceType: 'Mobile session',
      location: 'Sousse, Tunisia',
      lastActive: 'Yesterday at 18:42',
    ),
  ];

  void _showChangePasswordSheet() {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF101010) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
        final secondaryTextColor = isDarkMode
            ? Colors.white.withOpacity(0.62)
            : Colors.black.withOpacity(0.58);
        final fieldColor =
            isDarkMode ? const Color(0xFF181818) : const Color(0xFFF5F5F5);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Change Password',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update your password to keep your account secure.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              _PasswordField(
                controller: currentController,
                hintText: 'Current password',
                fieldColor: fieldColor,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: newController,
                hintText: 'New password',
                fieldColor: fieldColor,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: confirmController,
                hintText: 'Confirm new password',
                fieldColor: fieldColor,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (currentController.text.trim().isEmpty ||
                        newController.text.trim().isEmpty ||
                        confirmController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all password fields.'),
                        ),
                      );
                      return;
                    }

                    if (newController.text != confirmController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('New passwords do not match.'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(sheetContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Your password has been updated successfully.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.white : Colors.black,
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Save Password',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _disconnectSession(SessionCardData session) {
    setState(() {
      _sessions.remove(session);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${session.deviceName} disconnected.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showActivityExportDialog() {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF141414) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Account Activity Export',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Your recent account activity export has been prepared successfully.',
            style: TextStyle(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.62)
                  : Colors.black.withOpacity(0.58),
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeactivateAccountDialog() {
    final isDarkMode = context.read<ThemeProvider>().isDarkMode;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF141414) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Deactivate Account',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Your account deactivation request has been prepared. You can connect it to the backend later without changing the UI.',
            style: TextStyle(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.62)
                  : Colors.black.withOpacity(0.58),
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF141414) : const Color(0xFFF6F6F6);
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: isDarkMode ? Colors.white : Colors.black,
            size: 20,
          ),
        ),
        centerTitle: true,
        title: Text(
          'Privacy & Security',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            SettingsSectionTitle(
              title: 'Password & Access',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  SettingsTile(
                    isDarkMode: isDarkMode,
                    title: 'Change Password',
                    subtitle: 'Update your login password',
                    icon: HugeIcons.strokeRoundedSettings01,
                    onTap: _showChangePasswordSheet,
                  ),
                  Divider(color: borderColor, height: 1),
                  SettingsSwitchTile(
                    isDarkMode: isDarkMode,
                    title: 'Two-step Verification',
                    subtitle: 'Add an extra layer of protection',
                    value: _twoStepVerification,
                    onChanged: (value) {
                      setState(() {
                        _twoStepVerification = value;
                      });
                    },
                  ),
                  Divider(color: borderColor, height: 1),
                  SettingsSwitchTile(
                    isDarkMode: isDarkMode,
                    title: 'Biometric Unlock',
                    subtitle: 'Use biometric unlock when available',
                    value: _biometricUnlock,
                    onChanged: (value) {
                      setState(() {
                        _biometricUnlock = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SettingsSectionTitle(
              title: 'Active Sessions',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            ..._sessions.map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SessionCard(
                  isDarkMode: isDarkMode,
                  session: session,
                  onDisconnect: session.isCurrent
                      ? null
                      : () => _disconnectSession(session),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SettingsSectionTitle(
              title: 'Security Preferences',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  SettingsSwitchTile(
                    isDarkMode: isDarkMode,
                    title: 'Login Alerts',
                    subtitle: 'Get notified about new sign-ins',
                    value: _loginAlerts,
                    onChanged: (value) {
                      setState(() {
                        _loginAlerts = value;
                      });
                    },
                  ),
                  Divider(color: borderColor, height: 1),
                  SettingsSwitchTile(
                    isDarkMode: isDarkMode,
                    title: 'Remember Trusted Device',
                    subtitle: 'Reduce repeated verification prompts',
                    value: _rememberTrustedDevice,
                    onChanged: (value) {
                      setState(() {
                        _rememberTrustedDevice = value;
                      });
                    },
                  ),
                  Divider(color: borderColor, height: 1),
                  SettingsTile(
                    isDarkMode: isDarkMode,
                    title: 'Download Account Activity',
                    subtitle: 'Review your recent account activity',
                    icon: HugeIcons.strokeRoundedDownload04,
                    onTap: _showActivityExportDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Danger Zone',
              style: TextStyle(
                color: Color(0xFFFF5A67),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0xFFFF5A67).withOpacity(0.20),
                ),
              ),
              child: SettingsTile(
                isDarkMode: isDarkMode,
                title: 'Deactivate Account',
                subtitle: 'Temporarily disable access to JobMatch',
                icon: HugeIcons.strokeRoundedLogout01,
                danger: true,
                onTap: _showDeactivateAccountDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Color fieldColor;
  final bool isDarkMode;

  const _PasswordField({
    required this.controller,
    required this.hintText,
    required this.fieldColor,
    required this.isDarkMode,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final hintColor = widget.isDarkMode
        ? Colors.white.withOpacity(0.42)
        : Colors.black.withOpacity(0.42);

    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      style: TextStyle(
        color: textColor,
        fontSize: 14.5,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: hintColor,
          fontSize: 14,
        ),
        filled: true,
        fillColor: widget.fieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscure = !_obscure;
            });
          },
          icon: HugeIcon(
            icon: _obscure
                ? HugeIcons.strokeRoundedView
                : HugeIcons.strokeRoundedViewOffSlash,
            color: hintColor,
            size: 16,
          ),
        ),
      ),
    );
  }
}