// lib/screens/offers/client/client_agent_interest_screen.dart

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../data/mock_client_data.dart';
import '../../../models/agent_profile_model.dart';
import '../../../models/client_offer_model.dart';
import '../../../models/interested_agent_model.dart';
import '../../../models/offer_interaction_model.dart';
import '../../../services/agent_profile_resolver.dart';
import '../../../services/interaction_service.dart';
import '../../../services/offer_reaction_service.dart';
import '../../../widgets/agent_profile_avatar.dart';
import 'agent_public_profile_screen.dart';

class ClientAgentInterestScreen extends StatefulWidget {
  final int offerId;
  final int agentId;
  final String? agentName;
  final String? agentEmail;
  final String? offerTitle;
  final int? interactionId;
  final String? interestMessage;
  final double? proposedPrice;
  final String? avatarUrl;

  const ClientAgentInterestScreen({
    super.key,
    required this.offerId,
    required this.agentId,
    this.agentName,
    this.agentEmail,
    this.offerTitle,
    this.interactionId,
    this.interestMessage,
    this.proposedPrice,
    this.avatarUrl,
  });

  @override
  State<ClientAgentInterestScreen> createState() =>
      _ClientAgentInterestScreenState();
}

class _ClientAgentInterestScreenState extends State<ClientAgentInterestScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;

  OfferInteractionModel? _interaction;
  AgentProfileModel? _agentProfile;
  InterestedAgentModel? _agent;
  ClientOfferModel? _offer;
  String? _offerTitle;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      _offer = _loadOfferFromMock();
      _offerTitle = _offer?.title ?? widget.offerTitle;

      OfferInteractionModel? interaction;

      if (widget.interactionId != null && widget.interactionId! > 0) {
        interaction = OfferInteractionModel(
          id: widget.interactionId!,
          offerId: widget.offerId,
          offerTitle: widget.offerTitle ?? '',
          agentId: widget.agentId,
          agentName: widget.agentName,
          agentEmail: widget.agentEmail,
          message: widget.interestMessage ?? '',
          proposedPrice: widget.proposedPrice,
          status: 'PENDING',
          react: true,
        );
      }

      final pending = await InteractionService.getPendingForOffer(widget.offerId);
      for (final item in pending) {
        if (_matchesAgent(item, widget.agentId)) {
          interaction = item;
          break;
        }
      }

      _interaction = interaction;
      _offerTitle = interaction?.offerTitle ?? _offerTitle ?? widget.offerTitle;

      final resolvedName = _resolveAgentName(interaction);
      final interactionId = interaction?.id ?? widget.interactionId;

      _agentProfile = await AgentProfileResolver.resolve(
        agentProfileId: widget.agentId,
        agentUserId: interaction?.agentUserId,
        interactionId: interactionId,
        fallbackName: resolvedName,
        fallbackEmail: widget.agentEmail ?? interaction?.agentEmail,
        fallbackPhotoUrl: widget.avatarUrl ?? interaction?.agentPhotoUrl,
      );

      final displayName = _agentProfile!.displayName != 'Agent'
          ? _agentProfile!.displayName
          : resolvedName;

      _photoUrl = _agentProfile!.photoUrl.trim().isNotEmpty
          ? _agentProfile!.photoUrl
          : widget.avatarUrl ?? interaction?.agentPhotoUrl;

      final cityLabel = _agentProfile!.city.trim().isNotEmpty
          ? _agentProfile!.city
          : '—';

      _agent = OfferReactionService.findInterestedAgent(
            offerId: widget.offerId,
            agentId: widget.agentId,
          ) ??
          InterestedAgentModel(
            id: widget.agentId,
            name: displayName,
            jobTitle: 'Interested agent',
            city: cityLabel,
            rating: 4.5,
            completedJobs: 0,
            imageUrl: 'assets/images/agent1.jpg',
            offerId: widget.offerId,
            offerTitle: _offerTitle ?? '',
          );
    } catch (e) {
      if (e is InteractionServiceException) {
        _loadError = e.message;
      } else {
        _loadError = e.toString();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  ClientOfferModel? _loadOfferFromMock() {
    try {
      return MockClientData.offers.firstWhere(
        (offer) => offer.id == widget.offerId,
      );
    } catch (_) {
      return null;
    }
  }

  String _resolveAgentName(OfferInteractionModel? interaction) {
    final candidates = [
      widget.agentName,
      interaction?.agentName,
      _nameFromEmail(widget.agentEmail),
      _nameFromEmail(interaction?.agentEmail),
    ];

    for (final candidate in candidates) {
      if (candidate == null) continue;
      final trimmed = candidate.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.toLowerCase() == 'agent') continue;
      return trimmed;
    }

    return 'Agent';
  }

  bool _matchesAgent(OfferInteractionModel item, int agentId) {
    return item.agentId == agentId ||
        item.agentUserId == agentId;
  }

  String? _nameFromEmail(String? email) {
    if (email == null || !email.contains('@')) return null;

    final local = email.split('@').first.trim();
    if (local.isEmpty) return null;

    return local
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  Future<void> _respond({required bool accepted}) async {
    if (_isSubmitting) return;

    final agent = _agent;
    if (agent == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      var interactionId = _interaction?.id ?? widget.interactionId ?? 0;

      if (interactionId <= 0) {
        final pending = await InteractionService.getPendingForOffer(
          widget.offerId,
        );
        final matches =
            pending.where((item) => _matchesAgent(item, widget.agentId)).toList();
        interactionId = matches.isNotEmpty ? matches.first.id : 0;
      }

      if (interactionId <= 0) {
        throw const InteractionServiceException(
          'Could not find a pending interest for this agent.',
        );
      }

      final interaction = OfferInteractionModel(
        id: interactionId,
        offerId: widget.offerId,
        offerTitle: _offerTitle ?? agent.offerTitle,
        agentId: widget.agentId,
        agentName: agent.name,
        agentEmail: widget.agentEmail,
        message: widget.interestMessage ?? _interaction?.message ?? '',
        proposedPrice: widget.proposedPrice ?? _interaction?.proposedPrice,
        status: 'PENDING',
        react: true,
      );

      if (accepted) {
        await OfferReactionService.clientAcceptAgent(interaction: interaction);
      } else {
        await OfferReactionService.clientRejectAgent(interaction: interaction);
      }

      await OfferReactionService.refreshNotificationBadge();

      if (!mounted) return;

      Navigator.pop(context, accepted ? agent : null);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _openAgentProfile(InterestedAgentModel agent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgentPublicProfileScreen(
          agentId: widget.agentId,
          agentUserId: _interaction?.agentUserId,
          interactionId: _interaction?.id ?? widget.interactionId,
          fallbackName: agent.name,
          fallbackEmail: widget.agentEmail ?? _interaction?.agentEmail,
          fallbackPhotoUrl: _photoUrl,
          initialProfile: _agentProfile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    const accentGreen = Color(0xFF22C55E);

    final backgroundColor =
        isDarkMode ? Colors.black : const Color(0xFFF3F4F6);
    final cardColor = isDarkMode ? const Color(0xFF141414) : Colors.white;
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDarkMode
        ? const Color(0xFF9CA3AF)
        : Colors.black.withOpacity(0.58);

    final agent = _agent;
    final offer = _offer;
    final message = widget.interestMessage?.trim().isNotEmpty == true
        ? widget.interestMessage!.trim()
        : _interaction?.message.trim();

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
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: accentGreen),
            )
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  ),
                )
              : agent == null
                  ? Center(
                      child: Text(
                        'Unable to load agent details.',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      children: [
                        Text(
                          'Review this agent',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'They liked your offer. Accept to start working together or decline if it is not a fit.',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SectionCard(
                          cardColor: cardColor,
                          title: 'Interested agent',
                          primaryTextColor: primaryTextColor,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _openAgentProfile(agent),
                                child: AgentProfileAvatar(
                                  photoUrl: _photoUrl,
                                  displayName: agent.name,
                                  radius: 30,
                                  initialsColor: primaryTextColor,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () => _openAgentProfile(agent),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                agent.name,
                                                style: TextStyle(
                                                  color: accentGreen,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor: accentGreen
                                                      .withOpacity(0.45),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              color: accentGreen,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (widget.agentEmail != null &&
                                        widget.agentEmail!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.agentEmail!,
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      '${agent.city} · ${agent.rating.toStringAsFixed(1)} ★ · ${agent.completedJobs} jobs',
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          cardColor: cardColor,
                          title: 'Your offer',
                          primaryTextColor: primaryTextColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _offerTitle ?? offer?.title ?? 'Offer',
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (offer != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  offer.description,
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                              if (message != null && message.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Message',
                                  style: TextStyle(
                                    color: primaryTextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              if (widget.proposedPrice != null ||
                                  _interaction?.proposedPrice != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Proposed price: ${(widget.proposedPrice ?? _interaction?.proposedPrice)?.toStringAsFixed(0)} DT',
                                  style: TextStyle(
                                    color: accentGreen,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed:
                                _isSubmitting ? null : () => _respond(accepted: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Accept agent',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _respond(accepted: false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryTextColor,
                              side: BorderSide(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.14)
                                    : Colors.black.withOpacity(0.12),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Decline',
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
  }
}

class _SectionCard extends StatelessWidget {
  final Color cardColor;
  final String title;
  final Color primaryTextColor;
  final Widget child;

  const _SectionCard({
    required this.cardColor,
    required this.title,
    required this.primaryTextColor,
    required this.child,
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
        children: [
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedUser,
                color: primaryTextColor.withOpacity(0.72),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
