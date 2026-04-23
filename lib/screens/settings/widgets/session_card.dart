import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class SessionCardData {
  final String deviceName;
  final String deviceType;
  final String location;
  final String lastActive;
  final bool isCurrent;

  const SessionCardData({
    required this.deviceName,
    required this.deviceType,
    required this.location,
    required this.lastActive,
    this.isCurrent = false,
  });
}

class SessionCard extends StatelessWidget {
  final bool isDarkMode;
  final SessionCardData session;
  final VoidCallback? onDisconnect;

  const SessionCard({
    super.key,
    required this.isDarkMode,
    required this.session,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor =
        isDarkMode ? const Color(0xFF181818) : const Color(0xFFFFFFFF);
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.58);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSettings01,
                color: primaryTextColor.withOpacity(0.78),
                size: 22,
              ),
            ),
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
                        session.deviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (session.isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  session.deviceType,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${session.location} • ${session.lastActive}',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!session.isCurrent && onDisconnect != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onDisconnect,
              child: const Text(
                'Disconnect',
                style: TextStyle(
                  color: Color(0xFFFF5A67),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}