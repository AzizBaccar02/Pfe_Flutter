// lib/screens/offers/widgets/agent_bottom_bar.dart

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:hugeicons/hugeicons.dart';

import '../client/widgets/client_home_theme.dart';

class AgentBottomBar extends StatelessWidget {
  /// Bottom padding for scrollable tab bodies so content clears this bar.
  static double scrollContentPaddingBottom(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    // SafeArea minimum (8) + bar vertical padding (12) + selected slot (~48) + gap.
    return safeBottom + 88;
  }

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
    final barColor = ClientHomeTheme.navBarBackground(isDarkMode);
    final inactiveColor = ClientHomeTheme.tertiaryText(isDarkMode);

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
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: ClientHomeTheme.cardBorder(isDarkMode),
          ),
          boxShadow: ClientHomeTheme.floatingShadow(isDarkMode),
        ),
        child: Row(
          children: List.generate(
            items.length,
            (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;
              final isChatsItem = index == 3;

              return _NavSlot(
                isDarkMode: isDarkMode,
                icon: item.icon,
                label: item.label,
                selected: isSelected,
                inactiveColor: inactiveColor,
                onTap: () => onTap(index),
                unreadCount: isChatsItem ? chatUnreadCount : 0,
                badgeBackgroundColor: barColor,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  final bool isDarkMode;
  final dynamic icon;
  final String label;
  final bool selected;
  final Color inactiveColor;
  final VoidCallback onTap;
  final int unreadCount;
  final Color? badgeBackgroundColor;

  const _NavSlot({
    required this.isDarkMode,
    required this.icon,
    required this.label,
    required this.selected,
    required this.inactiveColor,
    required this.onTap,
    this.unreadCount = 0,
    this.badgeBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final pillColor = ClientHomeTheme.navActivePill(isDarkMode);
    final badgeBg =
        badgeBackgroundColor ?? ClientHomeTheme.navBarBackground(isDarkMode);
    final iconSize = selected ? 40.0 : 34.0;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: selected ? pillColor : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: icon,
                        color: selected ? Colors.white : inactiveColor,
                        size: selected ? 17 : 16,
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: -2,
                      child: _UnreadBadge(
                        count: unreadCount,
                        backgroundColor: badgeBg,
                      ),
                    ),
                ],
              ),
              if (selected) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pillColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ],
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
    const accentGreen = AppColors.accent;

    final label = count > 99 ? '99+' : '$count';
    final isSingleDigit = label.length == 1;

    return Container(
      height: 15,
      constraints: BoxConstraints(
        minWidth: isSingleDigit ? 15 : 19,
      ),
      padding: EdgeInsets.symmetric(horizontal: isSingleDigit ? 0 : 4),
      decoration: BoxDecoration(
        color: accentGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: backgroundColor,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: -0.25,
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
