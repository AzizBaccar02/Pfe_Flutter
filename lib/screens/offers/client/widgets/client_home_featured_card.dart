// lib/screens/offers/client/widgets/client_home_featured_card.dart

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:jobmatch_app/conf/app_colors.dart';

import '../../../../models/client_offer_model.dart';
import '../../../../widgets/offer_cover_image.dart';
import 'client_home_theme.dart';

class ClientHomeFeaturedCard extends StatelessWidget {
  final ClientOfferModel offer;
  final bool isDarkMode;
  final VoidCallback? onTap;

  const ClientHomeFeaturedCard({
    super.key,
    required this.offer,
    required this.isDarkMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = offer.images.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        height: 228,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: ClientHomeTheme.elevatedSurface(isDarkMode),
          borderRadius: BorderRadius.circular(22),
          boxShadow: ClientHomeTheme.cardShadow(isDarkMode),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              OfferCoverImage(
                imageUrl: offer.images.first,
                isDarkMode: isDarkMode,
              )
            else
              Container(
                color: ClientHomeTheme.elevatedSurface(isDarkMode),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedBriefcase01,
                  color: ClientHomeTheme.tertiaryText(isDarkMode),
                  size: 36,
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0.35, 0.65, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (offer.status == OfferStatus.open)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'OPEN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    offer.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        size: 13,
                        color: AppColors.accentSoft,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${offer.interestedAgentsCount}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'interested',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
