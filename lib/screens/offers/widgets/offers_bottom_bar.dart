import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'offers_bottom_item.dart';

class OffersBottomBar extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final VoidCallback onHomeTap;
  final VoidCallback onOffersTap;
  final VoidCallback onAddTap;
  final VoidCallback onInterestedTap;
  final VoidCallback onChatsTap;
  final bool showChatsDot;

  const OffersBottomBar({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.onHomeTap,
    required this.onOffersTap,
    required this.onAddTap,
    required this.onInterestedTap,
    required this.onChatsTap,
    this.showChatsDot = false,
  });

  @override
  Widget build(BuildContext context) {
    const accentYellow = Color(0xFFFFC107);
    const accentYellowSoft = Color(0xFFFFE082);
    const accentYellowDeep = Color(0xFF5D4200);

    final surfaceColor =
        isDarkMode ? const Color(0xFF101010) : const Color(0xFFF8F8F8);

    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(
            color: isDarkMode
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.18 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: OffersBottomItem(
                icon: HugeIcons.strokeRoundedHome03,
                label: 'Home',
                selected: selectedIndex == 0,
                isDarkMode: isDarkMode,
                onTap: onHomeTap,
              ),
            ),
            Expanded(
              child: OffersBottomItem(
                icon: HugeIcons.strokeRoundedWork,
                label: 'Offers',
                selected: selectedIndex == 1,
                isDarkMode: isDarkMode,
                onTap: onOffersTap,
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: onAddTap,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        accentYellowSoft,
                        accentYellow,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentYellow.withOpacity(0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        color: accentYellowDeep,
                        size: 18,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Add',
                        style: TextStyle(
                          color: accentYellowDeep,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: OffersBottomItem(
                icon: HugeIcons.strokeRoundedFavourite,
                label: 'Interested',
                selected: selectedIndex == 3,
                isDarkMode: isDarkMode,
                onTap: onInterestedTap,
              ),
            ),
            Expanded(
              child: OffersBottomItem(
                icon: HugeIcons.strokeRoundedMessage01,
                label: 'Chats',
                selected: selectedIndex == 4,
                isDarkMode: isDarkMode,
                onTap: onChatsTap,
                showIndicatorDot: showChatsDot,
              ),
            ),
          ],
        ),
      ),
    );
  }
}