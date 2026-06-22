import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/agent_my_reaction_model.dart';

/// Full view for one row from [AgentMyReactionModel] (my-reactions API).
class AgentMyReactionDetailScreen extends StatelessWidget {
  final AgentMyReactionModel reaction;

  const AgentMyReactionDetailScreen({
    super.key,
    required this.reaction,
  });

  static String _chipLabel(AgentMyReactionModel r) {
    if (!r.react) return 'Rejected';
    if (r.isPending) return 'Pending';
    if (r.isAccepted) return 'Matched';
    return 'Declined';
  }

  static Color _accent(AgentMyReactionModel r) {
    if (!r.react) return const Color(0xFFEF4444);
    if (r.isPending) return AppColors.accent;
    if (r.isAccepted) return AppColors.accent;
    return const Color(0xFFEF4444);
  }

  static String _formatDateTime(DateTime? d) {
    if (d == null) return '—';
    final l = d.toLocal();
    final y = l.year.toString().padLeft(4, '0');
    final m = l.month.toString().padLeft(2, '0');
    final day = l.day.toString().padLeft(2, '0');
    final h = l.hour.toString().padLeft(2, '0');
    final min = l.minute.toString().padLeft(2, '0');
    return '$y-$m-$day · $h:$min';
  }

  static String _clientStatusLine(AgentMyReactionModel r) {
    if (!r.react) return '—';
    if (r.isPending) return 'Waiting for the client';
    if (r.isAccepted) return 'Client accepted your interest';
    if (r.isRejected) return 'Client declined your interest';
    return r.status;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF151515) : const Color(0xFFF5F5F5);
    final softBorder =
        isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE5E5E5);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.68)
        : Colors.black.withValues(alpha: 0.62);

    final accent = _accent(reaction);
    final title = reaction.offerTitle.isEmpty
        ? 'Offer #${reaction.offerId}'
        : reaction.offerTitle;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        leading: AppBackButton(isDarkMode: isDarkMode),
        title: Text(
          'Reaction details',
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Offer ID · ${reaction.offerId}',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _chipLabel(reaction),
                    style: TextStyle(
                      color: accent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: softBorder),
                  ),
                  child: Text(
                    reaction.react ? 'You liked' : 'You rejected',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              reaction.outcomeLabel,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            _SectionTitle(
              text: 'Client side',
              color: primaryTextColor,
            ),
            const SizedBox(height: 10),
            _InfoCard(
              cardColor: cardColor,
              borderColor: softBorder,
              child: Text(
                _clientStatusLine(reaction),
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (reaction.react &&
                reaction.proposedPriceDisplay.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle(
                text: 'Your proposed price',
                color: primaryTextColor,
              ),
              const SizedBox(height: 10),
              _InfoCard(
                cardColor: cardColor,
                borderColor: softBorder,
                child: Text(
                  reaction.proposedPriceDisplay,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            if (reaction.message.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionTitle(
                text: 'Your message',
                color: primaryTextColor,
              ),
              const SizedBox(height: 10),
              _InfoCard(
                cardColor: cardColor,
                borderColor: softBorder,
                child: Text(
                  reaction.message,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _SectionTitle(
              text: 'Reaction ID',
              color: primaryTextColor,
            ),
            const SizedBox(height: 10),
            Text(
              '${reaction.id}',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              text: 'Date',
              color: primaryTextColor,
            ),
            const SizedBox(height: 10),
            Text(
              _formatDateTime(reaction.createdAt),
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionTitle({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;
  final Widget child;

  const _InfoCard({
    required this.cardColor,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
