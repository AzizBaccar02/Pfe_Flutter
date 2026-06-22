import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class OffersDrawerRow {
  final dynamic icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const OffersDrawerRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });
}

class OffersDrawerSection extends StatelessWidget {
  final String? label;
  final bool isDarkMode;
  final List<OffersDrawerRow> rows;

  const OffersDrawerSection({
    super.key,
    this.label,
    required this.isDarkMode,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final surface =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFF5F5F5);
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final labelColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.black.withValues(alpha: 0.45);
    final defaultItemColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.88)
        : Colors.black.withValues(alpha: 0.82);
    final destructiveColor =
        isDarkMode ? const Color(0xFFE57373) : const Color(0xFFC62828);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null && label!.trim().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
              child: Text(
                label!.toUpperCase(),
                style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 48,
                      endIndent: 12,
                      color: borderColor,
                    ),
                  _OffersDrawerTile(
                    row: rows[i],
                    isDarkMode: isDarkMode,
                    color: rows[i].isDestructive
                        ? destructiveColor
                        : defaultItemColor,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OffersDrawerTile extends StatelessWidget {
  final OffersDrawerRow row;
  final bool isDarkMode;
  final Color color;

  const _OffersDrawerTile({
    required this.row,
    required this.isDarkMode,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: row.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              HugeIcon(
                icon: row.icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  row.title,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kept for any legacy single-item usage.
@Deprecated('Use OffersDrawerSection with a single row instead.')
class OffersDrawerItem extends StatelessWidget {
  final dynamic icon;
  final String title;
  final bool isDarkMode;
  final Color? color;
  final VoidCallback onTap;

  const OffersDrawerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isDarkMode,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return OffersDrawerSection(
      isDarkMode: isDarkMode,
      rows: [
        OffersDrawerRow(
          icon: icon,
          title: title,
          onTap: onTap,
          isDestructive: color != null && color != Colors.white,
        ),
      ],
    );
  }
}
