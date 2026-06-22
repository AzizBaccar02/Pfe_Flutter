import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

import '../../../../models/recommended_offer_model.dart';
import '../../../../services/agent_reactions_realtime.dart';
import '../../../../services/interaction_service.dart';
import '../../../subscription/widgets/usage_limit_dialog.dart';
import 'ai_matches_theme.dart';

class RecommendedOfferTile extends StatelessWidget {
  final RecommendedOfferModel offer;
  final bool isDarkMode;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback? onTap;
  final bool compact;

  const RecommendedOfferTile({
    super.key,
    required this.offer,
    required this.isDarkMode,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.cardColor,
    required this.borderColor,
    this.onTap,
    this.compact = false,
  });

  IconData get _locationIcon {
    if (offer.isSameCity) return Icons.location_on_outlined;
    if (offer.isNearby) return Icons.near_me_outlined;
    return Icons.place_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final locationColor = AiMatchesTheme.locationAccent(offer, isDarkMode);
    final scoreColor = AiMatchesTheme.matchScoreAccent(offer.matchScore, isDarkMode);
    final scoreFill =
        AiMatchesTheme.matchScoreChipFill(offer.matchScore, isDarkMode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: EdgeInsets.all(compact ? 16 : 18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: compact ? 48 : 52,
                height: compact ? 48 : 52,
                decoration: BoxDecoration(
                  color: AiMatchesTheme.iconTileFill(offer, isDarkMode),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _locationIcon,
                  color: locationColor,
                  size: compact ? 22 : 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title.isEmpty ? 'Untitled offer' : offer.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: compact ? 15 : 16,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      offer.subtitle,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (offer.locationLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        offer.locationLabel,
                        style: TextStyle(
                          color: locationColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetricChip(
                          label: offer.matchScoreLabel,
                          textColor: scoreColor,
                          fillColor: scoreFill,
                        ),
                        _MetricChip(
                          label: offer.skillsMatchLabel,
                          textColor: secondaryTextColor,
                          fillColor: isDarkMode
                              ? const Color(0xFF1F2937)
                              : const Color(0xFFF3F4F6),
                          outlined: true,
                        ),
                        Text(
                          offer.budgetLabel,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: secondaryTextColor,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color fillColor;
  final bool outlined;

  const _MetricChip({
    required this.label,
    required this.textColor,
    required this.fillColor,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : fillColor,
        borderRadius: BorderRadius.circular(8),
        border: outlined
            ? Border.all(
                color: textColor.withOpacity(0.35),
              )
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

void showRecommendedOfferDetailsSheet(
  BuildContext context, {
  required RecommendedOfferModel offer,
  required bool isDarkMode,
  ValueChanged<RecommendedOfferModel>? onLiked,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AiMatchesTheme.cardBackground(isDarkMode),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return _RecommendedOfferDetailsSheet(
        offer: offer,
        isDarkMode: isDarkMode,
        onLiked: onLiked,
      );
    },
  );
}

class _RecommendedOfferDetailsSheet extends StatefulWidget {
  final RecommendedOfferModel offer;
  final bool isDarkMode;
  final ValueChanged<RecommendedOfferModel>? onLiked;

  const _RecommendedOfferDetailsSheet({
    required this.offer,
    required this.isDarkMode,
    this.onLiked,
  });

  @override
  State<_RecommendedOfferDetailsSheet> createState() =>
      _RecommendedOfferDetailsSheetState();
}

class _RecommendedOfferDetailsSheetState
    extends State<_RecommendedOfferDetailsSheet> {
  bool _isLiking = false;

  Future<void> _likeOffer() async {
    if (_isLiking) return;

    setState(() => _isLiking = true);

    try {
      await InteractionService.reactToOffer(
        offerId: widget.offer.id,
        react: true,
      );

      AgentReactionsRealtime.instance.notifyRefresh();

      if (!mounted) return;

      final title = widget.offer.title.isEmpty
          ? 'this offer'
          : '"${widget.offer.title}"';

      Navigator.pop(context);
      widget.onLiked?.call(widget.offer);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You liked $title'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF151515),
        ),
      );
    } on InteractionServiceException catch (e) {
      if (!mounted) return;

      setState(() => _isLiking = false);

      if (UsageLimitDialog.isUsageLimitMessage(e.message)) {
        await UsageLimitDialog.show(
          context,
          isAgent: true,
          message: e.message,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLiking = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your reaction. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFB91C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final isDarkMode = widget.isDarkMode;
    final primary = AiMatchesTheme.primaryText(isDarkMode);
    final secondary = AiMatchesTheme.secondaryText(isDarkMode);
    final scoreColor =
        AiMatchesTheme.matchScoreAccent(offer.matchScore, isDarkMode);
    final borderColor = AiMatchesTheme.cardBorder(isDarkMode);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: secondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    offer.title.isEmpty ? 'Offer' : offer.title,
                    style: TextStyle(
                      color: primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    offer.subtitle,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _SheetChip(
                        label: offer.matchScoreLabel,
                        color: scoreColor,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(width: 8),
                      _SheetChip(
                        label: offer.skillsMatchLabel,
                        color: secondary,
                        isDarkMode: isDarkMode,
                        outlined: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Why this match',
                    style: TextStyle(
                      color: primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...offer.aiReasons.map(
                    (reason) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: AiMatchesTheme.locationAccent(
                              offer,
                              isDarkMode,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(
                                color: secondary,
                                fontSize: 13.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Description',
                    style: TextStyle(
                      color: primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    offer.description.isEmpty
                        ? 'No description provided.'
                        : offer.description,
                    style: TextStyle(
                      color: secondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.paddingOf(context).bottom + 16,
              ),
              decoration: BoxDecoration(
                color: AiMatchesTheme.cardBackground(isDarkMode),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isLiking ? null : _likeOffer,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor:
                        AppColors.accent.withValues(alpha: 0.45),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isLiking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const HugeIcon(
                          icon: HugeIcons.strokeRoundedFavourite,
                          color: Colors.white,
                          size: 20,
                        ),
                  label: Text(
                    _isLiking ? 'Sending interest…' : 'Like this offer',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SheetChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDarkMode;
  final bool outlined;

  const _SheetChip({
    required this.label,
    required this.color,
    required this.isDarkMode,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: outlined
            ? Colors.transparent
            : AiMatchesTheme.matchScoreChipFill(
                _scoreFromLabel(label),
                isDarkMode,
              ),
        borderRadius: BorderRadius.circular(8),
        border: outlined ? Border.all(color: color.withOpacity(0.35)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static double _scoreFromLabel(String label) {
    final match = RegExp(r'(\d+)').firstMatch(label);
    if (match == null) return 50;
    return double.tryParse(match.group(1) ?? '') ?? 50;
  }
}
