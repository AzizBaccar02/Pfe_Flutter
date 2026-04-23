import 'dart:io';

import 'package:flutter/material.dart';

import 'home_info_pill.dart';

class HomeRecentOfferCard extends StatelessWidget {
  final dynamic offer;
  final bool isDarkMode;

  const HomeRecentOfferCard({
    super.key,
    required this.offer,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFF3F3F3);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.68)
        : Colors.black.withOpacity(0.68);

    final hasImage = offer.images.isNotEmpty;
    final imagePath = hasImage ? offer.images.first : null;

    return Container(
      width: 270,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SizedBox(
                height: 177,
                width: double.infinity,
                child: imagePath!.startsWith('assets/')
                    ? Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  offer.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    HomeInfoPill(
                      text: offer.category,
                      isDarkMode: isDarkMode,
                    ),
                    HomeInfoPill(
                      text: offer.city,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      '${offer.budget.toStringAsFixed(0)} DT',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${offer.interestedAgentsCount} interested',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}