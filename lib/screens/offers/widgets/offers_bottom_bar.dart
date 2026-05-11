// lib/screens/offers/widgets/offers_bottom_bar.dart

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class OffersBottomBar extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final int chatUnreadCount;
  final VoidCallback onHomeTap;
  final VoidCallback onOffersTap;
  final VoidCallback onAddTap;
  final VoidCallback onInterestedTap;
  final VoidCallback onChatsTap;

  const OffersBottomBar({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.onHomeTap,
    required this.onOffersTap,
    required this.onAddTap,
    required this.onInterestedTap,
    required this.onChatsTap,
    this.chatUnreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isDarkMode ? const Color(0xFF0E0E0E) : Colors.white;

    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    final activeColor = isDarkMode ? Colors.white : Colors.black;

    final inactiveColor = isDarkMode
        ? Colors.white.withOpacity(0.38)
        : Colors.black.withOpacity(0.38);

    return SafeArea(
      top: false,
      child: Container(
        height: 58,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(color: borderColor),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _BottomItem(
                icon: HugeIcons.strokeRoundedHome01,
                label: 'Home',
                selected: selectedIndex == 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: onHomeTap,
              ),
            ),
            Expanded(
              child: _BottomItem(
                icon: HugeIcons.strokeRoundedBriefcase01,
                label: 'Offers',
                selected: selectedIndex == 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: onOffersTap,
              ),
            ),
            Expanded(
              child: _BottomItem(
                icon: HugeIcons.strokeRoundedAdd01,
                label: 'Add',
                selected: selectedIndex == 2,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: onAddTap,
              ),
            ),
            Expanded(
              child: _BottomItem(
                icon: HugeIcons.strokeRoundedFavourite,
                label: 'Interested',
                selected: selectedIndex == 3,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: onInterestedTap,
              ),
            ),
            Expanded(
              child: _BottomItem(
                icon: HugeIcons.strokeRoundedMessage02,
                label: 'Chats',
                selected: selectedIndex == 4,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: onChatsTap,
                unreadCount: chatUnreadCount,
                badgeBackgroundColor: backgroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;
  final int unreadCount;
  final Color? badgeBackgroundColor;

  const _BottomItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    this.unreadCount = 0,
    this.badgeBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    final backgroundColor =
        badgeBackgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              HugeIcon(
                icon: icon,
                color: color,
                size: 16,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -13,
                  top: -10,
                  child: _UnreadBadge(
                    count: unreadCount,
                    backgroundColor: backgroundColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  final Color backgroundColor;

  const _UnreadBadge({
    required this.count,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF22C55E);

    return Container(
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: accentGreen,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: backgroundColor,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}