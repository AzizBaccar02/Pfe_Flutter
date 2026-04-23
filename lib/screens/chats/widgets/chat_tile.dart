import 'package:flutter/material.dart';

import '../../../models/interested_agent_model.dart';

class ChatTile extends StatelessWidget {
  final InterestedAgentModel agent;
  final String previewText;
  final String trailingText;
  final String offerTitle;
  final int unreadCount;
  final Color dividerColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final VoidCallback? onTap;

  const ChatTile({
    super.key,
    required this.agent,
    required this.previewText,
    required this.trailingText,
    required this.offerTitle,
    required this.unreadCount,
    required this.dividerColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentYellow = Color(0xFFFFC107);

    final neutralAccentText = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.82)
        : Colors.black.withOpacity(0.82);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: dividerColor),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 29,
              backgroundImage: AssetImage(agent.imageUrl),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          agent.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        trailingText,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    previewText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentYellow.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: accentYellow.withOpacity(0.22),
                            ),
                          ),
                          child: Text(
                            offerTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: neutralAccentText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (unreadCount > 0)
                        Container(
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: accentYellow.withOpacity(0.16),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentYellow.withOpacity(0.24),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: TextStyle(
                              color: neutralAccentText,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
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