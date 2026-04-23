import 'package:flutter/material.dart';

import '../../../models/interested_agent_model.dart';

class ChatMatchAvatar extends StatelessWidget {
  final InterestedAgentModel agent;
  final Color primaryTextColor;
  final bool hasUnread;
  final VoidCallback? onTap;

  const ChatMatchAvatar({
    super.key,
    required this.agent,
    required this.primaryTextColor,
    required this.hasUnread,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFFB347),
                        Color.fromARGB(255, 202, 119, 2),
                      ],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundImage: AssetImage(agent.imageUrl),
                    ),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    right: 2,
                    top: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 190, 152, 0),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              agent.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}