// lib/screens/offers/client/widgets/client_home_offer_row.dart

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

import '../../../../models/client_offer_model.dart';
import '../../../../widgets/offer_cover_image.dart';
import 'client_home_theme.dart';

class ClientHomeOfferRow extends StatelessWidget {
  final ClientOfferModel offer;
  final bool isDarkMode;
  final VoidCallback? onTap;

  const ClientHomeOfferRow({
    super.key,
    required this.offer,
    required this.isDarkMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ClientHomeTheme.primaryText(isDarkMode);
    final secondary = ClientHomeTheme.secondaryText(isDarkMode);
    final meta = [
      if (offer.category.trim().isNotEmpty) offer.category.trim(),
      if (offer.city.trim().isNotEmpty) offer.city.trim(),
    ].join(' · ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 62,
                  height: 62,
                  child: offer.images.isNotEmpty
                      ? OfferCoverImage(
                          imageUrl: offer.images.first,
                          isDarkMode: isDarkMode,
                        )
                      : _Thumb(
                          path: null,
                          isDarkMode: isDarkMode,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      '${offer.budget.toStringAsFixed(0)} DT',
                      style: TextStyle(
                        color: secondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: AppColors.accentSoft,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${offer.interestedAgentsCount}',
                    style: TextStyle(
                      color: primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? path;
  final bool isDarkMode;

  const _Thumb({
    required this.path,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = ClientHomeTheme.elevatedSurface(isDarkMode);

    if (path == null || path!.isEmpty) {
      return ColoredBox(
        color: fallback,
        child: Center(
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedBriefcase01,
            color: ClientHomeTheme.tertiaryText(isDarkMode),
            size: 22,
          ),
        ),
      );
    }

    return OfferCoverImage(
      imageUrl: path,
      isDarkMode: isDarkMode,
    );
  }
}
