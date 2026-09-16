import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../badges/pill_badge.dart';

/// A tinted, top/bottom-bordered bar labelling a group of rows below it —
/// e.g. a folder path grouping a table's rows. [tooltip] (typically the
/// same text in full, when [text] is itself an abbreviated form of it) is
/// shown on hover; omit it when [text] needs no further explanation.
/// [count], when given, is shown as a small trailing pill — how many rows
/// this section groups.
class TintedSectionHeader extends StatelessWidget {
  const TintedSectionHeader({
    super.key,
    required this.icon,
    required this.text,
    this.tooltip,
    this.count,
    this.height = 36,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
  });

  final IconData icon;
  final String text;
  final String? tooltip;
  final int? count;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSmall, color: colorScheme.onSurface),
        const SizedBox(width: AppSizes.spacing8),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: colorScheme.onSurface,
                ),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: AppSizes.spacing8),
          PillBadge(
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ),
        ],
      ],
    );

    return Container(
      height: height,
      padding: padding,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child:
          tooltip == null ? content : Tooltip(message: tooltip, child: content),
    );
  }
}
