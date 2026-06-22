import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/client_offer_model.dart';
import '../../../models/interested_agent_model.dart';
import '../../../services/client_interaction_realtime.dart';
import '../../../services/tab_auto_refresh.dart';
import '../../../services/client_interaction_state_service.dart';
import '../../../services/client_match_persistence.dart';
import '../../../services/interaction_service.dart';
import '../../../services/offer_service.dart';
import '../../../services/agent_profile_resolver.dart';
import '../../../services/profile_service.dart';
import '../../../utils/agent_identity_privacy.dart';
import '../widgets/match_created_dialog.dart';

class OfferDetailScreen extends StatefulWidget {
  final ClientOfferModel offer;
  final VoidCallback? onOfferUpdated;

  const OfferDetailScreen({
    super.key,
    required this.offer,
    this.onOfferUpdated,
  });

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  late ClientOfferModel _offer;

  bool _isLoadingAgents = true;
  bool _isMutating = false;
  String? _agentsError;

  List<InterestedAgentModel> _agents = [];

  late final TabAutoRefresh _autoRefresh;

  @override
  void initState() {
    super.initState();
    _offer = widget.offer;
    _autoRefresh = TabAutoRefresh(
      onRefresh: ({showLoader = true}) => _loadInterestedAgents(showLoader: showLoader),
      isTabActive: () => true,
      pollInterval: const Duration(seconds: 12),
      refreshWhenInactive: true,
    );
    _autoRefresh.attach();
    _loadInterestedAgents();
  }

  @override
  void dispose() {
    _autoRefresh.dispose();
    super.dispose();
  }

  Future<void> _loadInterestedAgents({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoadingAgents = true;
        _agentsError = null;
      });
    }

    try {
      final agents = await InteractionService.filterUnresolvedInterestedAgents(
        await InteractionService.fetchInterestedAgents(
          offerId: _offer.id,
        ),
      );

      if (!mounted) return;

      setState(() {
        _agents = agents;
        _agentsError = null;
      });
    } on InteractionServiceException catch (e) {
      if (!mounted) return;
      setState(() => _agentsError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _agentsError = 'Unable to load interested agents.';
      });
    } finally {
      if (mounted && showLoader) {
        setState(() => _isLoadingAgents = false);
      }
    }
  }

  Future<void> _respondToAgent(
    InterestedAgentModel agent, {
    required bool accept,
  }) async {
    if (_isMutating || agent.reactionId <= 0) return;

    setState(() => _isMutating = true);

    try {
      await InteractionService.respondToReaction(
        reactionId: agent.reactionId,
        accept: accept,
      );

      if (accept) {
        await ClientInteractionStateService.recordAccepted(
          offerId: agent.offerId,
          agentId: agent.id,
          reactionId: agent.reactionId,
        );
      } else {
        await ClientMatchPersistence.markRejected(
          offerId: agent.offerId,
          agentId: agent.id,
        );
      }
      ClientInteractionRealtime.instance.notifyRefresh();

      if (!mounted) return;

      setState(() {
        _agents = _agents.map((item) {
          if (item.reactionId != agent.reactionId) return item;
          return item.copyWith(
            status: accept ? 'ACCEPTED' : 'REJECTED',
          );
        }).toList();
      });

      if (accept) {
        await _showMatchDialog(agent);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You declined ${agent.name}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF151515),
          ),
        );
      }

      widget.onOfferUpdated?.call();
    } on InteractionServiceException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Unable to update reaction. Please try again.');
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _showMatchDialog(InterestedAgentModel agent) async {
    var agentPhoto = '';
    var agentName = agent.name.trim();

    try {
      final profile = await AgentProfileResolver.resolve(
        agentProfileId: agent.id,
        agentUserId: agent.id,
        interactionId: agent.reactionId > 0 ? agent.reactionId : null,
        fallbackName: agent.name,
      );
      agentPhoto =
          ProfileService.resolveMediaUrl(profile.photoUrl)?.trim() ?? '';
      if (profile.displayName.trim().isNotEmpty) {
        agentName = profile.displayName.trim();
      }
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return MatchCreatedDialog(
          agentImagePath: agentPhoto,
          backgroundImagePath: 'assets/images/match_bg.gif',
          agentName: agentName,
          agentId: agent.id,
          reactionId: agent.reactionId,
          onContinue: () => Navigator.of(dialogContext).pop(),
          onStartChat: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  Future<void> _updateOfferStatus(OfferStatus status) async {
    if (_isMutating) return;

    setState(() => _isMutating = true);

    try {
      final updated = await OfferService.updateOfferStatus(
        offerId: _offer.id,
        status: status,
      );

      if (!mounted) return;

      setState(() => _offer = updated);
      widget.onOfferUpdated?.call();
      _showSnackBar('Offer updated');
    } on OfferException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF151515),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : const Color(0xFFF6F7F9);
    final primary = isDarkMode ? Colors.white : Colors.black;
    final secondary = isDarkMode
        ? Colors.white.withValues(alpha: 0.62)
        : Colors.black.withValues(alpha: 0.58);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AppBackButton(isDarkMode: isDarkMode),
        title: Text(
          'Offer details',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            enabled: !_isMutating,
            color: isDarkMode ? const Color(0xFF202020) : Colors.white,
            onSelected: (value) {
              switch (value) {
                case 'open':
                  _updateOfferStatus(OfferStatus.open);
                case 'closed':
                  _updateOfferStatus(OfferStatus.closed);
                case 'archived':
                  _updateOfferStatus(OfferStatus.archived);
              }
            },
            itemBuilder: (context) => [
              if (_offer.status != OfferStatus.open)
                const PopupMenuItem(value: 'open', child: Text('Mark as open')),
              if (_offer.status != OfferStatus.closed)
                const PopupMenuItem(
                  value: 'closed',
                  child: Text('Mark as closed'),
                ),
              if (_offer.status != OfferStatus.archived)
                const PopupMenuItem(
                  value: 'archived',
                  child: Text('Archive'),
                ),
            ],
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedMoreHorizontal,
              color: primary,
              size: 22,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => _loadInterestedAgents(showLoader: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _OfferSummaryCard(
              offer: _offer,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Interested agents',
                    style: TextStyle(
                      color: primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_agents.length}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Agents who reacted positively to this offer.',
              style: TextStyle(color: secondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (_isLoadingAgents)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else if (_agentsError != null)
              _AgentsError(
                message: _agentsError!,
                isDarkMode: isDarkMode,
                onRetry: _loadInterestedAgents,
              )
            else if (_agents.isEmpty)
              _AgentsEmpty(isDarkMode: isDarkMode)
            else
              ..._agents.map(
                (agent) => _InterestedAgentTile(
                  agent: agent,
                  isDarkMode: isDarkMode,
                  isBusy: _isMutating,
                  onAccept: () => _respondToAgent(agent, accept: true),
                  onReject: () => _respondToAgent(agent, accept: false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OfferSummaryCard extends StatelessWidget {
  final ClientOfferModel offer;
  final bool isDarkMode;

  const _OfferSummaryCard({
    required this.offer,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF161616) : Colors.white;
    final primary = isDarkMode ? Colors.white : Colors.black;
    final secondary = isDarkMode
        ? Colors.white.withValues(alpha: 0.62)
        : Colors.black.withValues(alpha: 0.58);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            offer.title,
            style: TextStyle(
              color: primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            offer.description,
            style: TextStyle(color: secondary, height: 1.45, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(
                label: '${offer.budget.toStringAsFixed(0)} TND',
                isDarkMode: isDarkMode,
              ),
              if (offer.category.isNotEmpty)
                _Pill(label: offer.category, isDarkMode: isDarkMode),
              if (offer.city.isNotEmpty)
                _Pill(label: offer.city, isDarkMode: isDarkMode),
              _Pill(
                label: _statusLabel(offer.status),
                isDarkMode: isDarkMode,
                accent: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _statusLabel(OfferStatus status) {
    return switch (status) {
      OfferStatus.open => 'Open',
      OfferStatus.closed => 'Closed',
      OfferStatus.archived => 'Archived',
    };
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool isDarkMode;
  final bool accent;

  const _Pill({
    required this.label,
    required this.isDarkMode,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.accent.withValues(alpha: 0.12)
            : (isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent
              ? AppColors.accent
              : (isDarkMode
                  ? Colors.white.withValues(alpha: 0.75)
                  : Colors.black.withValues(alpha: 0.65)),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InterestedAgentTile extends StatelessWidget {
  final InterestedAgentModel agent;
  final bool isDarkMode;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _InterestedAgentTile({
    required this.agent,
    required this.isDarkMode,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? const Color(0xFF161616) : Colors.white;
    final primary = isDarkMode ? Colors.white : Colors.black;
    final secondary = isDarkMode
        ? Colors.white.withValues(alpha: 0.62)
        : Colors.black.withValues(alpha: 0.58);

    final isPending = agent.isPendingInterest;
    final imageUrl = isPending
        ? ''
        : (ProfileService.resolveMediaUrl(agent.imageUrl) ??
            agent.imageUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AgentAvatar(imageUrl: imageUrl, isDarkMode: isDarkMode),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPending
                          ? AgentIdentityPrivacy.publicLabel(agent.name)
                          : agent.name,
                      style: TextStyle(
                        color: primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (agent.jobTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        agent.jobTitle,
                        style: TextStyle(color: secondary, fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (agent.city.isNotEmpty)
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedLocation01,
                            color: secondary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            agent.city,
                            style: TextStyle(color: secondary, fontSize: 12),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              _ReactionStatusBadge(status: agent.status),
            ],
          ),
          if (agent.message.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              agent.message,
              style: TextStyle(
                color: secondary,
                fontSize: 13,
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: isBusy ? null : onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
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

class _AgentAvatar extends StatelessWidget {
  final String imageUrl;
  final bool isDarkMode;

  const _AgentAvatar({
    required this.imageUrl,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (imageUrl.startsWith('http')) {
      child = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else if (imageUrl.startsWith('assets/')) {
      child = Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else if (imageUrl.isNotEmpty) {
      child = Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else {
      child = _fallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(width: 56, height: 56, child: child),
    );
  }

  Widget _fallback() {
    final placeholder = isDarkMode
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFE8E8E8);

    return ColoredBox(
      color: placeholder,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedUser,
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.4),
          size: 24,
        ),
      ),
    );
  }
}

class _ReactionStatusBadge extends StatelessWidget {
  final String status;

  const _ReactionStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();

    final (color, label) = switch (normalized) {
      'ACCEPTED' => (AppColors.accent, 'Accepted'),
      'REJECTED' => (Colors.redAccent, 'Declined'),
      _ => (const Color(0xFFF59E0B), 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AgentsEmpty extends StatelessWidget {
  final bool isDarkMode;

  const _AgentsEmpty({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final primary = isDarkMode ? Colors.white : Colors.black;
    final secondary = isDarkMode
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.55);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF161616) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedUserGroup,
              color: AppColors.accent,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No interested agents yet',
            style: TextStyle(
              color: primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'When agents like this offer, they will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: secondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _AgentsError extends StatelessWidget {
  final String message;
  final bool isDarkMode;
  final VoidCallback onRetry;

  const _AgentsError({
    required this.message,
    required this.isDarkMode,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
