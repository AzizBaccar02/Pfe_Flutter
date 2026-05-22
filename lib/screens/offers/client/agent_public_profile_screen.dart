// lib/screens/offers/client/agent_public_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/agent_profile_model.dart';
import '../../../services/agent_profile_resolver.dart';
import '../../../widgets/agent_profile_avatar.dart';

class AgentPublicProfileScreen extends StatefulWidget {
  final int agentId;
  final int? agentUserId;
  final int? interactionId;
  final String? fallbackName;
  final String? fallbackEmail;
  final String? fallbackPhotoUrl;
  final AgentProfileModel? initialProfile;

  const AgentPublicProfileScreen({
    super.key,
    required this.agentId,
    this.agentUserId,
    this.interactionId,
    this.fallbackName,
    this.fallbackEmail,
    this.fallbackPhotoUrl,
    this.initialProfile,
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

  String get _displayName {
    final fromProfile = _profile?.displayName;
    if (fromProfile != null && fromProfile.trim().isNotEmpty) {
      return fromProfile;
    }
    return widget.fallbackName?.trim().isNotEmpty == true
        ? widget.fallbackName!.trim()
        : 'Agent';
  }

  String? get _photoUrl {
    final fromProfile = _profile?.photoUrl;
    if (fromProfile != null && fromProfile.trim().isNotEmpty) {
      return fromProfile;
    }
    return widget.fallbackPhotoUrl;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    const accentGreen = Color(0xFF22C55E);

    final backgroundColor = isDarkMode ? Colors.black : const Color(0xFFF3F4F6);
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: accentGreen,
            size: 18,
          ),
        ),
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
                Center(
                  child: AgentProfileAvatar(
                    photoUrl: _photoUrl,
                    displayName: _displayName,
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
                if (widget.fallbackEmail?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      widget.fallbackEmail!,
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
                      value: profile?.phone.isNotEmpty == true
                          ? profile!.phone
                          : '—',
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
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

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.primaryTextColor,
    required this.secondaryTextColor,
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
                    color: primaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
