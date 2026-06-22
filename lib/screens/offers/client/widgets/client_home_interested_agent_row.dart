// lib/screens/offers/client/widgets/client_home_interested_agent_row.dart

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../models/interested_agent_model.dart';
import '../../../../utils/agent_identity_privacy.dart';
import '../../../../widgets/agent_profile_avatar.dart';
import 'client_home_theme.dart';

class ClientHomeInterestedAgentRow extends StatelessWidget {
  final InterestedAgentModel agent;
  final bool isDarkMode;
  final bool showAsMatched;
  final VoidCallback? onTap;

  const ClientHomeInterestedAgentRow({
    super.key,
    required this.agent,
    required this.isDarkMode,
    this.showAsMatched = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = ClientHomeTheme.primaryText(isDarkMode);
    final secondary = ClientHomeTheme.secondaryText(isDarkMode);
    final pending = !showAsMatched && agent.isPendingInterest;

    final agentLabel = pending
        ? AgentIdentityPrivacy.publicLabel(agent.name)
        : agent.name;

    final offerLine = agent.offerTitle.trim().isNotEmpty
        ? agent.offerTitle.trim()
        : 'Your offer';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ClientHomeTheme.cardBackground(isDarkMode),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientHomeTheme.cardBorder(isDarkMode)),
          ),
          child: Row(
            children: [
              AgentProfileAvatar(
                photoUrl: pending ? null : agent.imageUrl,
                displayName: agentLabel,
                radius: 26,
                backgroundColor: isDarkMode
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFE5E7EB),
                initialsColor: isDarkMode ? Colors.white : const Color(0xFF374151),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agentLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offerLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (agent.city.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        agent.city.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showAsMatched || agent.isPendingForDeck) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: showAsMatched
                            ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        showAsMatched ? 'Matched' : 'Pending',
                        style: TextStyle(
                          color: showAsMatched
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFF59E0B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    color: secondary,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
