// lib/screens/offers/client/agent_public_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/agent_profile_model.dart';
import '../../../services/agent_profile_resolver.dart';
import '../../../utils/agent_identity_privacy.dart';
import '../../../widgets/agent_profile_avatar.dart';

class AgentPublicProfileScreen extends StatefulWidget {
  final int agentId;
  final int? agentUserId;
  final int? interactionId;
  final String? fallbackName;
  final String? fallbackEmail;
  final String? fallbackPhotoUrl;
  final AgentProfileModel? initialProfile;
  final bool identityRevealed;

  const AgentPublicProfileScreen({
    super.key,
    required this.agentId,
    this.agentUserId,
    this.interactionId,
    this.fallbackName,
    this.fallbackEmail,
    this.fallbackPhotoUrl,
    this.initialProfile,
    this.identityRevealed = true,
  });

  @override
  State<AgentPublicProfileScreen> createState() =>
      _AgentPublicProfileScreenState();
}

class _AgentPublicProfileScreenState extends State<AgentPublicProfileScreen> {
  bool _isLoading = true;
  AgentProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _profile = widget.initialProfile ??
          await AgentProfileResolver.resolve(
            agentProfileId: widget.agentId,
            agentUserId: widget.agentUserId,
            interactionId: widget.interactionId,
            fallbackName: widget.fallbackName,
            fallbackEmail: widget.fallbackEmail,
            fallbackPhotoUrl: widget.fallbackPhotoUrl,
          );
    } catch (_) {
      _profile = widget.initialProfile;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String get _fullName {
    final fromProfile = _profile?.displayName;
    if (fromProfile != null && fromProfile.trim().isNotEmpty) {
      return fromProfile;
    }
    return widget.fallbackName?.trim().isNotEmpty == true
        ? widget.fallbackName!.trim()
        : 'Agent';
  }

  String get _displayName {
    if (widget.identityRevealed) return _fullName;
    return AgentIdentityPrivacy.publicLabel(_fullName);
  }

  String? get _photoUrl {
    if (!widget.identityRevealed) return null;

    final fromProfile = _profile?.photoUrl;
    if (fromProfile != null && fromProfile.trim().isNotEmpty) {
      return fromProfile;
    }
    return widget.fallbackPhotoUrl;
  }

  String? get _email {
    if (!widget.identityRevealed) return null;
    return widget.fallbackEmail?.trim().isNotEmpty == true
        ? widget.fallbackEmail!.trim()
        : null;
  }

  String _contactValue(String? value) {
    if (widget.identityRevealed) {
      return value?.trim().isNotEmpty == true ? value!.trim() : '—';
    }
    return AgentIdentityPrivacy.hiddenContactValue;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    const accentGreen = AppColors.accent;

    final backgroundColor =
        isDarkMode ? const Color(0xFF0D0D0D) : const Color(0xFFF3F4F6);
    final cardColor = isDarkMode ? const Color(0xFF141414) : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDarkMode ? const Color(0xFF9CA3AF) : Colors.black54;

    final profile = _profile;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(isDarkMode: isDarkMode),
        title: Text(
          'Agent profile',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentGreen))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                if (!widget.identityRevealed) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accentGreen.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      AgentIdentityPrivacy.profileGateHint,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Center(
                  child: AgentProfileAvatar(
                    photoUrl: _photoUrl,
                    displayName: _fullName,
                    radius: 52,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (_email != null) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      _email!,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _InfoCard(
                  cardColor: cardColor,
                  primaryTextColor: primaryTextColor,
                  children: [
                    _InfoRow(
                      icon: HugeIcons.strokeRoundedLocation01,
                      label: 'City',
                      value: profile?.city.isNotEmpty == true
                          ? profile!.city
                          : '—',
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _InfoRow(
                      icon: HugeIcons.strokeRoundedStar,
                      label: 'Hourly rate',
                      value: profile != null && profile.hourlyRate > 0
                          ? '${profile.hourlyRate.toStringAsFixed(0)} DT/h'
                          : '—',
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _InfoRow(
                      icon: HugeIcons.strokeRoundedCall02,
                      label: 'Phone',
                      value: _contactValue(profile?.phone),
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      muted: !widget.identityRevealed,
                    ),
                  ],
                ),
                if (profile?.bio.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _InfoCard(
                    cardColor: cardColor,
                    primaryTextColor: primaryTextColor,
                    children: [
                      Text(
                        'About',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile!.bio,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ],
                if (profile?.skills.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _InfoCard(
                    cardColor: cardColor,
                    primaryTextColor: primaryTextColor,
                    children: [
                      Text(
                        'Skills',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile!.skills,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color cardColor;
  final Color primaryTextColor;
  final List<Widget> children;

  const _InfoCard({
    required this.cardColor,
    required this.primaryTextColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  final String value;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final bool muted;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          HugeIcon(icon: icon, color: secondaryTextColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: muted ? secondaryTextColor : primaryTextColor,
                    fontSize: 14,
                    fontWeight: muted ? FontWeight.w600 : FontWeight.w700,
                    fontStyle: muted ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
