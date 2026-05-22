import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class SwipeOfferCardData {
  final int id;
  final int clientUserId;
  final String title;
  final String category;
  final String city;
  final String budget;
  final String clientName;
  final String description;
  final List<String> imageUrls;
  final List<String> skills;
  final List<String> highlights;

  const SwipeOfferCardData({
    required this.id,
    required this.clientUserId,
    required this.title,
    required this.category,
    required this.city,
    required this.budget,
    required this.clientName,
    required this.description,
    required this.imageUrls,
    required this.skills,
    required this.highlights,
  });
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
    if (widget.dragDx > 0) return const Color(0xFF16A34A);
    if (widget.dragDx < 0) return const Color(0xFFDC2626);
    return Colors.transparent;
  }

  double _feedbackOpacity() {
    final value = (widget.dragDx.abs() / 120).clamp(0.0, 1.0);
    return value * 0.16;
  }

  String _feedbackText() {
    if (widget.dragDx > 25) return 'LIKE';
    if (widget.dragDx < -25) return 'NOPE';
    return '';
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF111111),
            ],
          ),
        ),
      );
    }

    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A1A),
                  Color(0xFF111111),
                ],
              ),
            ),
          );
        },
      );
    }

    return Image.asset(
      path,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A1A),
                Color(0xFF111111),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = widget.offer.imageUrls.isNotEmpty
        ? widget.offer.imageUrls[_currentImageIndex]
        : '';

    final actionBackground =
        widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;

    final shadowColor = widget.isDarkMode
        ? Colors.black.withOpacity(0.35)
        : Colors.black.withOpacity(0.10);

    return SizedBox.expand(
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      /// Image only.
                      /// The tap detector is added later in the stack.
                      Positioned.fill(
                        child: _buildImage(currentImage),
                      ),

                      /// Swipe feedback color overlay
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: _feedbackColor()
                                .withOpacity(_feedbackOpacity()),
                          ),
                        ),
                      ),

                      /// Light full image overlay
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.06),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.08),
                                ],
                                stops: const [0.0, 0.18, 0.62, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                      /// Bottom shadow, around 30% of the card
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: constraints.maxHeight * 0.30,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.00),
                                  Colors.black.withOpacity(0.25),
                                  Colors.black.withOpacity(0.55),
                                  Colors.black.withOpacity(0.82),
                                ],
                                stops: const [0.0, 0.28, 0.70, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),

                      /// Image indicators
                      if (widget.offer.imageUrls.isNotEmpty)
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: IgnorePointer(
                            child: Row(
                              children: List.generate(
                                widget.offer.imageUrls.length,
                                (index) {
                                  final isActive =
                                      index == _currentImageIndex;

                                  return Expanded(
                                    child: Container(
                                      height: 4,
                                      margin: EdgeInsets.only(
                                        right: index ==
                                                widget.offer.imageUrls.length -
                                                    1
                                            ? 0
                                            : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.28),
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

                      /// Swipe label
                      Positioned(
                        top: 42,
                        left: widget.dragDx >= 0 ? 14 : null,
                        right: widget.dragDx < 0 ? 14 : null,
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 120),
                            opacity: _feedbackText().isEmpty ? 0 : 1,
                            child: Transform.rotate(
                              angle: widget.dragDx >= 0 ? -0.10 : 0.10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: widget.dragDx >= 0
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFFEF4444),
                                    width: 1.8,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.black.withOpacity(0.12),
                                ),
                                child: Text(
                                  _feedbackText(),
                                  style: TextStyle(
                                    color: widget.dragDx >= 0
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFFEF4444),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      /// Main tap area for changing images.
                      /// Left side = previous image.
                      /// Right side = next image.
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapUp: (details) =>
                              _handleImageTap(details, constraints),
                        ),
                      ),

                      /// Bottom text without required skills
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: IgnorePointer(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.offer.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        height: 1.12,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black87,
                                            blurRadius: 10,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      widget.offer.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.92),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black87,
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        HugeIcon(
                                          icon: HugeIcons
                                              .strokeRoundedLocation01,
                                          color:
                                              Colors.white.withOpacity(0.85),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            widget.offer.city,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.85),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              shadows: const [
                                                Shadow(
                                                  color: Colors.black87,
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            /// Details button
                            if (widget.showDetailsButton) ...[
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: widget.onDetailsTap,
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.88),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.16),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      size: 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          /// Buttons below the card, not inside the image
          if (widget.showActions) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleActionButton(
                  onTap: widget.onDislikeTap,
                  backgroundColor: actionBackground,
                  iconColor: const Color(0xFFEF4444),
                  icon: HugeIcons.strokeRoundedCancel01,
                  shadowColor: shadowColor,
                ),
                const SizedBox(width: 22),
                _CircleActionButton(
                  onTap: widget.onLikeTap,
                  backgroundColor: actionBackground,
                  iconColor: const Color(0xFF10B981),
                  icon: HugeIcons.strokeRoundedFavourite,
                  shadowColor: shadowColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final Color shadowColor;
  final dynamic icon;

  const _CircleActionButton({
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: HugeIcon(
            icon: icon,
            color: iconColor,
            size: 22,
          ),
        ),
      ),
    );
  }
}