import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/user_profile_provider.dart';
import '../../../services/agent_profile_resolver.dart';
import '../../../services/profile_service.dart';

class MatchCreatedDialog extends StatefulWidget {
  final String? clientImagePath;
  final String agentImagePath;
  final String agentName;
  final String? clientName;
  final int? agentId;
  final int? reactionId;
  final String backgroundImagePath;
  final VoidCallback onContinue;
  final VoidCallback onStartChat;

  const MatchCreatedDialog({
    super.key,
    this.clientImagePath,
    required this.agentImagePath,
    required this.agentName,
    this.clientName,
    this.agentId,
    this.reactionId,
    required this.backgroundImagePath,
    required this.onContinue,
    required this.onStartChat,
  });

  @override
  State<MatchCreatedDialog> createState() => _MatchCreatedDialogState();
}

class _MatchCreatedDialogState extends State<MatchCreatedDialog> {
  String _clientPhoto = '';
  String _agentPhoto = '';
  String _clientDisplayName = 'You';
  bool _loadingClientPhoto = true;
  bool _loadingAgentPhoto = true;

  @override
  void initState() {
    super.initState();
    _agentPhoto = _resolvePhoto(widget.agentImagePath);
    _loadingAgentPhoto = _agentPhoto.isEmpty;
    _bootstrapClientProfile();
    if (_agentPhoto.isEmpty) {
      _bootstrapAgentProfile();
    } else {
      _loadingAgentPhoto = false;
    }
  }

  static String _resolvePhoto(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final value = raw.trim();
    return ProfileService.resolveMediaUrl(value) ?? value;
  }

  String? _photoFromProvider(UserProfileProvider provider) {
    final remote = provider.remoteProfileImageUrl?.trim();
    if (remote != null && remote.isNotEmpty) return remote;

    final local = provider.localProfileImagePath?.trim();
    if (local != null && local.isNotEmpty) return local;

    return null;
  }

  Future<void> _bootstrapClientProfile() async {
    final passedName = widget.clientName?.trim();
    if (passedName != null && passedName.isNotEmpty) {
      _clientDisplayName = passedName;
    }

    final passedPhoto = widget.clientImagePath?.trim();
    if (passedPhoto != null && passedPhoto.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _clientPhoto = _resolvePhoto(passedPhoto);
        _loadingClientPhoto = false;
      });
      return;
    }

    final profileProvider = context.read<UserProfileProvider>();
    final cachedPhoto = _photoFromProvider(profileProvider);
    if (cachedPhoto != null) {
      if (!mounted) return;
      setState(() {
        _clientPhoto = _resolvePhoto(cachedPhoto);
        _loadingClientPhoto = false;
      });
    }

    try {
      final profile = await ProfileService.getClientProfile();
      final remoteUrl = ProfileService.resolveMediaUrl(profile.photoUrl);
      final fullName = [
        profile.firstName.trim(),
        profile.lastName.trim(),
      ].where((part) => part.isNotEmpty).join(' ');

      if (!mounted) return;

      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        profileProvider.setRemoteProfileImageUrl(remoteUrl);
      }

      setState(() {
        if (fullName.isNotEmpty) {
          _clientDisplayName = fullName;
        }
        _clientPhoto = remoteUrl ?? _clientPhoto;
        _loadingClientPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;

      final fallback = _photoFromProvider(profileProvider);
      setState(() {
        if (fallback != null) {
          _clientPhoto = _resolvePhoto(fallback);
        }
        _loadingClientPhoto = false;
      });
    }
  }

  Future<void> _bootstrapAgentProfile() async {
    final passed = _resolvePhoto(widget.agentImagePath);
    if (passed.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _agentPhoto = passed;
        _loadingAgentPhoto = false;
      });
      return;
    }

    final agentId = widget.agentId;
    if (agentId == null || agentId <= 0) {
      if (!mounted) return;
      setState(() => _loadingAgentPhoto = false);
      return;
    }

    try {
      final profile = await AgentProfileResolver.resolve(
        agentProfileId: agentId,
        agentUserId: agentId,
        interactionId: widget.reactionId,
        fallbackName: widget.agentName,
      );
      final photo = _resolvePhoto(profile.photoUrl);

      if (!mounted) return;
      setState(() {
        _agentPhoto = photo;
        _loadingAgentPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAgentPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentPhoto = _agentPhoto;
    final displayAgentName = widget.agentName.trim().isEmpty
        ? 'this agent'
        : widget.agentName.trim();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 520,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                widget.backgroundImagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF14532D),
                        Color(0xFF0A0A0A),
                      ],
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.50),
                      Colors.black.withValues(alpha: 0.78),
                      Colors.black.withValues(alpha: 0.92),
                    ],
                    stops: const [0.0, 0.35, 0.72, 1.0],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    children: [
                      const Spacer(),
                      _MatchAvatarPair(
                        leftImagePath: _clientPhoto,
                        rightImagePath: agentPhoto,
                        leftName: _clientDisplayName,
                        rightName: displayAgentName,
                        leftLoading: _loadingClientPhoto && _clientPhoto.isEmpty,
                        rightLoading: _loadingAgentPhoto && agentPhoto.isEmpty,
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        "It's a match",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'You and $displayAgentName can start working together.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: widget.onStartChat,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Start chatting',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: widget.onContinue,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Colors.white.withValues(alpha: 0.92),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.28),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Keep swiping',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _MatchAvatarPair extends StatelessWidget {
  final String leftImagePath;
  final String rightImagePath;
  final String leftName;
  final String rightName;
  final bool leftLoading;
  final bool rightLoading;

  const _MatchAvatarPair({
    required this.leftImagePath,
    required this.rightImagePath,
    required this.leftName,
    required this.rightName,
    this.leftLoading = false,
    this.rightLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    const avatarSize = 108.0;
    const overlap = 28.0;

    return SizedBox(
      height: avatarSize + 8,
      width: avatarSize * 2 - overlap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            child: _MatchAvatar(
              imagePath: leftImagePath,
              displayName: leftName,
              size: avatarSize,
              loading: leftLoading,
            ),
          ),
          Positioned(
            right: 0,
            child: _MatchAvatar(
              imagePath: rightImagePath,
              displayName: rightName,
              size: avatarSize,
              loading: rightLoading,
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedFavourite,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchAvatar extends StatelessWidget {
  final String imagePath;
  final String displayName;
  final double size;
  final bool loading;

  const _MatchAvatar({
    required this.imagePath,
    required this.displayName,
    required this.size,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: _buildImageContent(context),
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    if (loading && imagePath.isEmpty) {
      return _loadingPlaceholder();
    }

    if (imagePath.isEmpty) {
      return _initialsFallback(context);
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _loadingPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) =>
            _initialsFallback(context),
      );
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _initialsFallback(context),
      );
    }

    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _initialsFallback(context),
      );
    }

    return _initialsFallback(context);
  }

  Widget _loadingPlaceholder() {
    return ColoredBox(
      color: const Color(0xFF1F2937),
      child: Center(
        child: SizedBox(
          width: size * 0.28,
          height: size * 0.28,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentSoft,
          ),
        ),
      ),
    );
  }

  Widget _initialsFallback(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1F2937),
      child: Center(
        child: Text(
          _initials(displayName),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: size * 0.34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
