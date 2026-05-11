// lib/screens/offers/widgets/agent_bottom_bar.dart

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class AgentBottomBar extends StatelessWidget {
  final int selectedIndex;
  final bool isDarkMode;
  final int chatUnreadCount;
  final ValueChanged<int> onTap;

  const AgentBottomBar({
    super.key,
    required this.selectedIndex,
    required this.isDarkMode,
    required this.onTap,
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

    final items = [
      _BarItem(
        label: 'Home',
        icon: HugeIcons.strokeRoundedHome01,
      ),
      _BarItem(
        label: 'Offers',
        icon: HugeIcons.strokeRoundedBriefcase01,
      ),
      _BarItem(
        label: 'Reactions',
        icon: HugeIcons.strokeRoundedFavourite,
      ),
      _BarItem(
        label: 'Chats',
        icon: HugeIcons.strokeRoundedMessage02,
      ),
    ];

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
          children: List.generate(
            items.length,
            (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;
              final isChatsItem = index == 3;
              final unreadCount = isChatsItem ? chatUnreadCount : 0;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          HugeIcon(
                            icon: item.icon,
                            color: isSelected ? activeColor : inactiveColor,
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
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? activeColor : inactiveColor,
                          fontSize: 10.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
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

class _BarItem {
  final String label;
  final dynamic icon;

  const _BarItem({
    required this.label,
    required this.icon,
  });
}