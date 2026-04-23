import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../data/mock_client_data.dart';
import '../../../models/client_offer_model.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  String selectedFilter = 'All';

  List<ClientOfferModel> get filteredOffers {
    if (selectedFilter == 'All') return MockClientData.offers;

    if (selectedFilter == 'Open') {
      return MockClientData.offers
          .where((offer) => offer.status == OfferStatus.open)
          .toList();
    }

    if (selectedFilter == 'Closed') {
      return MockClientData.offers
          .where((offer) => offer.status == OfferStatus.closed)
          .toList();
    }

    if (selectedFilter == 'Archived') {
      return MockClientData.offers
          .where((offer) => offer.status == OfferStatus.archived)
          .toList();
    }

    return MockClientData.offers;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFF3F3F3);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.68)
        : Colors.black.withOpacity(0.68);

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipButton(
                  label: 'All',
                  selected: selectedFilter == 'All',
                  isDarkMode: isDarkMode,
                  onTap: () => setState(() => selectedFilter = 'All'),
                ),
                _FilterChipButton(
                  label: 'Open',
                  selected: selectedFilter == 'Open',
                  isDarkMode: isDarkMode,
                  onTap: () => setState(() => selectedFilter = 'Open'),
                ),
                _FilterChipButton(
                  label: 'Closed',
                  selected: selectedFilter == 'Closed',
                  isDarkMode: isDarkMode,
                  onTap: () => setState(() => selectedFilter = 'Closed'),
                ),
                _FilterChipButton(
                  label: 'Archived',
                  selected: selectedFilter == 'Archived',
                  isDarkMode: isDarkMode,
                  onTap: () => setState(() => selectedFilter = 'Archived'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredOffers.isEmpty
                ? Center(
                    child: Text(
                      'No offers found',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    itemCount: filteredOffers.length,
                    itemBuilder: (context, index) {
                      final offer = filteredOffers[index];
                      return _OfferListCard(
                        offer: offer,
                        isDarkMode: isDarkMode,
                        cardColor: cardColor,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _OfferListCard extends StatelessWidget {
  final ClientOfferModel offer;
  final bool isDarkMode;
  final Color cardColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const _OfferListCard({
    required this.offer,
    required this.isDarkMode,
    required this.cardColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = offer.images.isNotEmpty;
    final imagePath = hasImage ? offer.images.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
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
                height: 190,
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
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 17,
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
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      text: offer.category,
                      isDarkMode: isDarkMode,
                    ),
                    _InfoPill(
                      text: offer.city,
                      isDarkMode: isDarkMode,
                    ),
                    _InfoPill(
                      text: '${offer.budget.toStringAsFixed(0)} DT',
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StatusBadge(
                      status: offer.status,
                      isDarkMode: isDarkMode,
                    ),
                    const Spacer(),
                    Text(
                      '${offer.interestedAgentsCount} interested',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 13,
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

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isDarkMode ? Colors.white : Colors.black;
    final selectedText = isDarkMode ? Colors.black : Colors.white;
    final unselectedBg =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFF0F0F0);
    final unselectedText = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? selectedText : unselectedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  final bool isDarkMode;

  const _InfoPill({
    required this.text,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OfferStatus status;
  final bool isDarkMode;

  const _StatusBadge({
    required this.status,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case OfferStatus.open:
        color = Colors.greenAccent;
        text = 'Open';
        break;
      case OfferStatus.closed:
        color = Colors.orangeAccent;
        text = 'Closed';
        break;
      case OfferStatus.archived:
        color = Colors.blueGrey;
        text = 'Archived';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}