import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../utils/agent_identity_privacy.dart';
import '../../../widgets/offer_cover_image.dart';
import 'elegant_swipe_action_button.dart';

class SwipeOfferCardData {
  final int id;
  final int clientUserId;
  final String title;
  final String category;
  final String city;
  final String budget;
  final String clientFullName;
  final String description;
  final List<String> imageUrls;
  final List<String> skills;
  final List<String> highlights;
  final String? locationLabel;
  final String? matchScoreLabel;

  const SwipeOfferCardData({
    required this.id,
    required this.clientUserId,
    required this.title,
    required this.category,
    required this.city,
    required this.budget,
    this.clientFullName = '',
    required this.description,
    required this.imageUrls,
    required this.skills,
    required this.highlights,
    this.locationLabel,
    this.matchScoreLabel,
  });

  /// Masked label for agents before match, e.g. "Client : MB".
  String get clientDisplayLabel => AgentIdentityPrivacy.clientPublicLabel(
        clientFullName.isEmpty ? null : clientFullName,
      );
}

class OfferSwipeCard extends StatefulWidget {
  final SwipeOfferCardData offer;
  final bool isDarkMode;
  final VoidCallback onLikeTap;
  final VoidCallback onDislikeTap;
  final VoidCallback onDetailsTap;
  final double dragDx;

  /// Use false for the card behind the main card.
  final bool showActions;
  final bool showDetailsButton;

  const OfferSwipeCard({
    super.key,
    required this.offer,
    required this.isDarkMode,
    required this.onLikeTap,
    required this.onDislikeTap,
    required this.onDetailsTap,
    required this.dragDx,
    this.showActions = true,
    this.showDetailsButton = true,
  });

  @override
  State<OfferSwipeCard> createState() => _OfferSwipeCardState();
}

class _OfferSwipeCardState extends State<OfferSwipeCard> {
  int _currentImageIndex = 0;

  void _showPreviousImage() {
    if (widget.offer.imageUrls.isEmpty) return;

    setState(() {
      _currentImageIndex = _currentImageIndex == 0
          ? widget.offer.imageUrls.length - 1
          : _currentImageIndex - 1;
    });
  }

  void _showNextImage() {
    if (widget.offer.imageUrls.isEmpty) return;

    setState(() {
      _currentImageIndex =
          _currentImageIndex == widget.offer.imageUrls.length - 1
              ? 0
              : _currentImageIndex + 1;
    });
  }

  void _handleImageTap(TapUpDetails details, BoxConstraints constraints) {
    final tapX = details.localPosition.dx;
    final width = constraints.maxWidth;

    if (tapX < width / 2) {
      _showPreviousImage();
    } else {
      _showNextImage();
    }
  }

  Color _feedbackColor() {
    if (widget.dragDx > 0) return AppColors.accent;
    if (widget.dragDx < 0) return const Color(0xFFDC2626);
    return Colors.transparent;
  }

  double _feedbackOpacity() {
    return (widget.dragDx.abs() / 120).clamp(0.0, 1.0) * 0.14;
  }

  String _feedbackText() {
    if (widget.dragDx > 25) return 'INTEREST';
    if (widget.dragDx < -25) return 'SKIP';
    return '';
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1C1E), Color(0xFF0D0D0F)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedBriefcase01,
                color: Colors.white.withValues(alpha: 0.35),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Offer image',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return OfferCoverImage(
      imageUrl: path,
      fit: BoxFit.cover,
      isDarkMode: widget.isDarkMode,
    );
  }

  Widget _glassPanel({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _categoryChip() {
    final label = widget.offer.category.trim().isNotEmpty
        ? widget.offer.category
        : 'Job offer';

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedBriefcase01,
                color: Colors.white.withValues(alpha: 0.85),
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = widget.offer.imageUrls.isNotEmpty
        ? widget.offer.imageUrls[_currentImageIndex]
        : '';

    final shadowColor = widget.isDarkMode
        ? Colors.black.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.12);

    final location =
        widget.offer.locationLabel ?? widget.offer.city;

    return SizedBox.expand(
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(child: _buildImage(currentImage)),

                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.55),
                              ],
                              stops: const [0.0, 0.22, 0.55, 1.0],
                            ),
                          ),
                        ),
                      ),

                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: _feedbackColor().withValues(
                              alpha: _feedbackOpacity(),
                            ),
                          ),
                        ),
                      ),

                      if (widget.offer.imageUrls.length > 1)
                        Positioned(
                          top: 14,
                          left: 14,
                          right: 14,
                          child: IgnorePointer(
                            child: Row(
                              children: List.generate(
                                widget.offer.imageUrls.length,
                                (index) {
                                  final isActive =
                                      index == _currentImageIndex;

                                  return Expanded(
                                    child: Container(
                                      height: 3,
                                      margin: EdgeInsets.only(
                                        right: index ==
                                                widget.offer.imageUrls.length -
                                                    1
                                            ? 0
                                            : 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.28),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                      Positioned(
                        top: widget.offer.imageUrls.length > 1 ? 28 : 14,
                        left: 14,
                        child: _categoryChip(),
                      ),

                      if (_feedbackText().isNotEmpty)
                        Positioned(
                          top: 72,
                          left: widget.dragDx >= 0 ? 18 : null,
                          right: widget.dragDx < 0 ? 18 : null,
                          child: IgnorePointer(
                            child: Transform.rotate(
                              angle: widget.dragDx >= 0 ? -0.08 : 0.08,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: widget.dragDx >= 0
                                        ? AppColors.accent
                                        : const Color(0xFFEF4444),
                                    width: 2,
                                  ),
                                  color:
                                      Colors.black.withValues(alpha: 0.2),
                                ),
                                child: Text(
                                  _feedbackText(),
                                  style: TextStyle(
                                    color: widget.dragDx >= 0
                                        ? AppColors.accent
                                        : const Color(0xFFEF4444),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapUp: (details) =>
                              _handleImageTap(details, constraints),
                        ),
                      ),

                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: _glassPanel(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.offer.matchScoreLabel !=
                                            null &&
                                        widget.offer.matchScoreLabel!
                                            .isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent
                                              .withValues(alpha: 0.18),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.accent
                                                .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Text(
                                          widget.offer.matchScoreLabel!,
                                          style: const TextStyle(
                                            color: AppColors.accent,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    if (widget.offer.matchScoreLabel !=
                                            null &&
                                        widget.offer.matchScoreLabel!
                                            .isNotEmpty)
                                      const SizedBox(height: 10),
                                    Text(
                                      widget.offer.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    if (widget.offer.budget.trim().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          widget.offer.budget,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.78,
                                            ),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        HugeIcon(
                                          icon: HugeIcons
                                              .strokeRoundedLocation01,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          size: 13,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.75,
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.showDetailsButton) ...[
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: widget.onDetailsTap,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.22,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 19,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (widget.showActions) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElegantSwipeActionButton(
                  onTap: widget.onDislikeTap,
                  icon: HugeIcons.strokeRoundedCancel01,
                  iconColor: const Color(0xFFEF4444),
                  borderColor:
                      const Color(0xFFEF4444).withValues(alpha: 0.35),
                  backgroundColor: widget.isDarkMode
                      ? const Color(0xFF1A1A1A)
                      : Colors.white,
                  shadowColor: shadowColor,
                ),
                const SizedBox(width: 28),
                ElegantSwipeActionButton(
                  onTap: widget.onLikeTap,
                  icon: HugeIcons.strokeRoundedFavourite,
                  iconColor: AppColors.accent,
                  borderColor:
                      AppColors.accent.withValues(alpha: 0.45),
                  backgroundColor: widget.isDarkMode
                      ? const Color(0xFF1A1A1A)
                      : Colors.white,
                  shadowColor: shadowColor,
                  filled: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
