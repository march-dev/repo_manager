import 'package:flutter/material.dart';

import '../icons/asset_or_fallback_icon.dart';

/// One row of a [RankedBreakdownList]: an icon, a label, a proportional
/// progress bar, and the raw count it represents.
class LabeledProgressBar extends StatelessWidget {
  const LabeledProgressBar({
    super.key,
    required this.iconAsset,
    required this.fallbackIcon,
    required this.label,
    required this.count,
    required this.fraction,
    this.height = 8,
    this.labelWidth = 130,
    this.countWidth = 28,
  });

  final String? iconAsset;
  final IconData fallbackIcon;
  final String label;
  final int count;

  /// This row's proportion of the largest row currently shown, in `[0, 1]`.
  final double fraction;
  final double height;
  final double labelWidth;
  final double countWidth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Row(
            children: [
              AssetOrFallbackIcon(
                iconAsset: iconAsset,
                fallbackIcon: fallbackIcon,
                size: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: height,
              backgroundColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
        ),
        SizedBox(
          width: countWidth,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ),
      ],
    );
  }
}
