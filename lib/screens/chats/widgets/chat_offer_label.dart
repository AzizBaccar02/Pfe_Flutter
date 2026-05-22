// lib/screens/chats/widgets/chat_offer_label.dart

import 'package:flutter/material.dart';

/// Briefcase + offer title, shared by chat tiles and conversation header.
class ChatOfferLabel extends StatelessWidget {
  final String offerTitle;
  final Color color;
  final double iconSize;
  final double fontSize;
  final double? maxWidth;
  final TextAlign textAlign;

  const ChatOfferLabel({
    super.key,
    required this.offerTitle,
    required this.color,
    this.iconSize = 13,
    this.fontSize = 11.5,
    this.maxWidth,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: textAlign == TextAlign.end
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Icon(
          Icons.work_outline_rounded,
          size: iconSize,
          color: color.withOpacity(0.75),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            offerTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: TextStyle(
              color: color.withOpacity(0.92),
              fontSize: fontSize,
              height: 1.15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );

    if (maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: row,
      );
    }

    return row;
  }
}
