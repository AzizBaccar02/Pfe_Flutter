// lib/screens/chats/chat_peer_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:jobmatch_app/conf/app_colors.dart';
import 'package:jobmatch_app/widgets/app_back_button.dart';
import 'package:provider/provider.dart';

import '../../conf/theme_provider.dart';
import '../../models/chat_conversation_summary_model.dart';
import '../../services/chat_conversation_display_name_service.dart';
import '../../services/profile_service.dart';
import 'widgets/edit_conversation_name_dialog.dart';

/// Full-screen contact & offer details (long-press name in chat), WhatsApp-style.
class ChatPeerProfileScreen extends StatefulWidget {
  final ChatConversationSummaryModel chat;
  final int viewerUserId;

  const ChatPeerProfileScreen({
    super.key,
    required this.chat,
    required this.viewerUserId,
  });

  @override
  State<ChatPeerProfileScreen> createState() => _ChatPeerProfileScreenState();
}

class _ChatPeerProfileScreenState extends State<ChatPeerProfileScreen> {
  static String? _formatBudgetLine(ChatOfferSummary? offer) {
    if (offer == null) return null;
    if (offer.budget <= 0) return null;
    final b = offer.budget;
    final text = b == b.roundToDouble() ? b.toInt().toString() : b.toString();
    return '$text TND';
  }

  static String? _formatLocation(ChatOfferSummary? offer) {
    if (offer == null) return null;
    final city = offer.city.trim();
    if (city.isNotEmpty) return city;
    final addr = offer.address.trim();
    if (addr.isNotEmpty) return addr;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _prime();
  }

  Future<void> _prime() async {
    await ChatConversationDisplayNameService.instance.ensureLoaded();
    if (mounted) setState(() {});
  }

  String get _serverName => widget.chat.displayName;

  String get _resolvedTitle => ChatConversationDisplayNameService.instance
      .resolve(widget.chat.id, _serverName);

  List<MapEntry<String, String>> _detailRows() {
    final offer = widget.chat.offer;
    final user = widget.chat.otherUser;
    final detailRows = <MapEntry<String, String>>[];

    final offerTitle = offer?.title.trim() ?? '';
    if (offerTitle.isNotEmpty) {
      detailRows.add(MapEntry('Offer', offerTitle));
    }
    final category = offer?.category.trim() ?? '';
    if (category.isNotEmpty) {
      detailRows.add(MapEntry('Category', category));
    }
    final budgetStr = _formatBudgetLine(offer);
    if (budgetStr != null) {
      detailRows.add(MapEntry('Budget', budgetStr));
    }
    final location = _formatLocation(offer);
    if (location != null) {
      detailRows.add(MapEntry('Location', location));
    }
    final phone =
        widget.chat.resolvePeerPhone(viewerUserId: widget.viewerUserId).trim();
    detailRows.add(
      MapEntry('Phone', phone.isNotEmpty ? phone : '\u2014'),
    );
    final email = user?.email.trim() ?? '';
    if (email.isNotEmpty) {
      detailRows.add(MapEntry('Email', email));
    }
    final role = (user?.role ?? '').trim().toUpperCase();
    if (role.isNotEmpty) {
      detailRows.add(MapEntry('Role', role));
    }
    final username = user?.username.trim() ?? '';
    if (username.isNotEmpty) {
      detailRows.add(MapEntry('Username', username));
    }
    final desc = offer?.description.trim() ?? '';
    if (desc.isNotEmpty) {
      detailRows.add(MapEntry('Description', desc));
    }
    return detailRows;
  }

  Future<void> _editConversationNameDialog() async {
    if (!mounted) return;

    final isDarkMode = context.read<ThemeProvider>().isDarkMode;
    final initial = ChatConversationDisplayNameService.instance
            .overrideOnly(widget.chat.id) ??
        '';

    final result = await showDialog<String?>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: isDarkMode
          ? Colors.black.withValues(alpha: 0.88)
          : Colors.black.withValues(alpha: 0.5),
      builder: (_) => EditConversationNameDialog(
        serverName: _serverName,
        initialText: initial,
        isDarkMode: isDarkMode,
      ),
    );

    if (!mounted || result == null) return;

    await ChatConversationDisplayNameService.instance.setOverride(
      widget.chat.id,
      result.isEmpty ? null : result,
      _serverName,
    );

    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    const accentGreen = AppColors.accent;

    final backgroundColor =
        isDarkMode ? const Color(0xFF000000) : const Color(0xFFF3F4F6);
    final insetBg =
        isDarkMode ? const Color(0xFF000000) : const Color(0xFFF3F4F6);
    final primaryTextColor =
        isDarkMode ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor = isDarkMode
        ? Colors.white.withOpacity(0.62)
        : Colors.black.withOpacity(0.56);
    final presenceRingColor =
        isDarkMode ? const Color(0xFF000000) : Colors.white;

    final detailRows = _detailRows();
    final resolved = ProfileService.resolveMediaUrl(
      widget.chat.resolvePeerPhotoUrl(viewerUserId: widget.viewerUserId).trim(),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF000000) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: primaryTextColor,
        leading: AppBackButton(isDarkMode: isDarkMode),
        title: Text(
          'Contact info',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDarkMode
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _LargePeerAvatar(
                  resolvedUrl: resolved,
                  initials: widget.chat.displayInitials,
                  isDarkMode: isDarkMode,
                  radius: 52,
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: presenceRingColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: widget.chat
                                .peerOnlineForViewer(widget.viewerUserId)
                            ? accentGreen
                            : secondaryTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  _resolvedTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryTextColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: _editConversationNameDialog,
                visualDensity: VisualDensity.compact,
                tooltip: 'Change conversation name',
                icon: Icon(
                  Icons.edit_outlined,
                  color: accentGreen,
                  size: 22,
                ),
              ),
            ],
          ),
          if (ChatConversationDisplayNameService.instance
                  .overrideOnly(widget.chat.id) !=
              null) ...[
            const SizedBox(height: 6),
            Text(
              'Using a custom name for this chat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (detailRows.isNotEmpty) ...[
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: insetBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < detailRows.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.06),
                      ),
                    _ProfileDetailRow(
                      label: detailRows[i].key,
                      value: detailRows[i].value,
                      valueMuted: detailRows[i].key == 'Phone' &&
                          detailRows[i].value == '\u2014',
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LargePeerAvatar extends StatelessWidget {
  final String? resolvedUrl;
  final String initials;
  final bool isDarkMode;
  final double radius;

  const _LargePeerAvatar({
    required this.resolvedUrl,
    required this.initials,
    required this.isDarkMode,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;
    final bg = isDarkMode ? Colors.black : const Color(0xFFE5E7EB);
    final fg = isDarkMode ? Colors.white : const Color(0xFF111827);
    final fontSize = (radius * 0.45).clamp(18.0, 40.0);

    Widget initialsLabel() {
      return Text(
        initials,
        style: TextStyle(
          color: fg,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    if (resolvedUrl != null && resolvedUrl!.isNotEmpty) {
      return ClipOval(
        child: Container(
          width: diameter,
          height: diameter,
          color: bg,
          child: Image.network(
            resolvedUrl!,
            width: diameter,
            height: diameter,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Center(child: initialsLabel()),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: initialsLabel(),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueMuted;
  final Color primaryTextColor;
  final Color secondaryTextColor;

  const _ProfileDetailRow({
    required this.label,
    required this.value,
    this.valueMuted = false,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = valueMuted ? secondaryTextColor : primaryTextColor;
    final weight = valueMuted ? FontWeight.w600 : FontWeight.w700;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: weight,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
