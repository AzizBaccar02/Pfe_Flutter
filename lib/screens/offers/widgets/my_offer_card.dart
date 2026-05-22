import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../conf/app_colors.dart';
import '../../../models/client_offer_model.dart';
import '../../../services/profile_service.dart';

class MyOfferCard extends StatelessWidget {
  final ClientOfferModel offer;
  final bool isDarkMode;
  final bool isBusy;
  final VoidCallback onTap;
  final ValueChanged<OfferStatus> onStatusChanged;
  final VoidCallback onDelete;

  const MyOfferCard({
    super.key,
    required this.offer,
    required this.isDarkMode,
    required this.isBusy,
    required this.onTap,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDarkMode ? const Color(0xFF161616) : Colors.white;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final primary = isDarkMode ? Colors.white : Colors.black;
    final secondary = isDarkMode
        ? Colors.white.withValues(alpha: 0.62)
        : Colors.black.withValues(alpha: 0.58);

    final hasImage = offer.images.isNotEmpty;
    final imageUrl = hasImage
        ? ProfileService.resolveMediaUrl(offer.images.first) ??
            offer.images.first
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: cardColor,
        elevation: 0,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: isBusy ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OfferImageHeader(
                  imageUrl: imageUrl,
                  hasImage: hasImage,
                  offer: offer,
                  isDarkMode: isDarkMode,
                  isBusy: isBusy,
                  onStatusChanged: onStatusChanged,
                  onDelete: onDelete,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        offer.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (offer.category.trim().isNotEmpty)
                            _MetaChip(
                              icon: HugeIcons.strokeRoundedTag01,
                              label: offer.category,
                              isDarkMode: isDarkMode,
                            ),
                          if (offer.city.trim().isNotEmpty)
                            _MetaChip(
                              icon: HugeIcons.strokeRoundedLocation01,
                              label: offer.city,
                              isDarkMode: isDarkMode,
                            ),
                          _MetaChip(
                            icon: HugeIcons.strokeRoundedCalendar03,
                            label: _formatDate(offer.createdAt),
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedFavourite,
                                  color: AppColors.accent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${offer.interestedAgentsCount} interested',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'View details',
                            style: TextStyle(
                              color: secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowRight01,
                            color: secondary,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = date.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}

class _OfferImageHeader extends StatelessWidget {
  final String? imageUrl;
  final bool hasImage;
  final ClientOfferModel offer;
  final bool isDarkMode;
  final bool isBusy;
  final ValueChanged<OfferStatus> onStatusChanged;
  final VoidCallback onDelete;

  const _OfferImageHeader({
    required this.imageUrl,
    required this.hasImage,
    required this.offer,
    required this.isDarkMode,
    required this.isBusy,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder =
        isDarkMode ? const Color(0xFF222222) : const Color(0xFFE8E8E8);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: hasImage ? 200 : 120,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage && imageUrl != null)
              _OfferImage(url: imageUrl!, placeholder: placeholder)
            else
              Container(
                color: placeholder,
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedImage01,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.25),
                  size: 36,
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: hasImage ? 0.05 : 0.2),
                      Colors.black.withValues(alpha: hasImage ? 0.72 : 0.45),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  _StatusBadge(status: offer.status),
                  const Spacer(),
                  _OfferActionsMenu(
                    offer: offer,
                    isDarkMode: isDarkMode,
                    isBusy: isBusy,
                    onStatusChanged: onStatusChanged,
                    onDelete: onDelete,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${offer.budget.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      'TND',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferImage extends StatelessWidget {
  final String url;
  final Color placeholder;

  const _OfferImage({
    required this.url,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(color: placeholder),
      );
    }

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(color: placeholder),
      );
    }

    return Image.file(
      File(url),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(color: placeholder),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OfferStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      OfferStatus.open => (AppColors.accent, 'Open'),
      OfferStatus.closed => (const Color(0xFFF59E0B), 'Closed'),
      OfferStatus.archived => (const Color(0xFF94A3B8), 'Archived'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool isDarkMode;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDarkMode
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final fg = isDarkMode
        ? Colors.white.withValues(alpha: 0.75)
        : Colors.black.withValues(alpha: 0.65);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: fg, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferActionsMenu extends StatelessWidget {
  final ClientOfferModel offer;
  final bool isDarkMode;
  final bool isBusy;
  final ValueChanged<OfferStatus> onStatusChanged;
  final VoidCallback onDelete;

  const _OfferActionsMenu({
    required this.offer,
    required this.isDarkMode,
    required this.isBusy,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_OfferMenuAction>(
      enabled: !isBusy,
      color: isDarkMode ? const Color(0xFF202020) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (action) {
        switch (action) {
          case _OfferMenuAction.open:
            onStatusChanged(OfferStatus.open);
          case _OfferMenuAction.closed:
            onStatusChanged(OfferStatus.closed);
          case _OfferMenuAction.archived:
            onStatusChanged(OfferStatus.archived);
          case _OfferMenuAction.delete:
            onDelete();
        }
      },
      itemBuilder: (context) => [
        if (offer.status != OfferStatus.open)
          const PopupMenuItem(
            value: _OfferMenuAction.open,
            child: Text('Mark as open'),
          ),
        if (offer.status != OfferStatus.closed)
          const PopupMenuItem(
            value: _OfferMenuAction.closed,
            child: Text('Mark as closed'),
          ),
        if (offer.status != OfferStatus.archived)
          const PopupMenuItem(
            value: _OfferMenuAction.archived,
            child: Text('Archive'),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _OfferMenuAction.delete,
          child: Text(
            'Delete',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

enum _OfferMenuAction { open, closed, archived, delete }
