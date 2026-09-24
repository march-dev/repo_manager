import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../badges/color_dot.dart';
import '../placeholders/empty_placeholder.dart';

/// A GitHub-repo-language-bar-style breakdown of [counts]: one thin,
/// rounded, stacked bar with a segment per entry sized by its share of the
/// total, and a legend underneath (a coloured dot, its label, and its
/// percentage) — rather than [RankedBreakdownList]'s icon+label+progress-bar
/// rows, which read more like a settings list than "this project is made
/// of these languages/frameworks, in these proportions".
class CompositionBar<T> extends StatelessWidget {
  const CompositionBar({
    super.key,
    required this.counts,
    required this.colorOf,
    required this.labelOf,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.maxLegendEntries = 8,
    this.barHeight = 10,
  });

  final Map<T, int> counts;
  final Color Function(T) colorOf;
  final String Function(T) labelOf;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final int maxLegendEntries;
  final double barHeight;

  static const _minSegmentWidth = 10.0;
  static const _segmentGap = 1.0;

  // Same background frame [SizeBar] draws around its own two segments —
  // a visible border/backdrop behind the gaps between this bar's segments
  // too, rather than just showing whatever's behind the card through them.
  static const _framePadding = AppSizes.spacing2;

  @override
  Widget build(BuildContext context) {
    if (counts.isEmpty) {
      return EmptyPlaceholder(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = entries.take(maxLegendEntries).toList();
    final total = shown.fold<int>(0, (sum, entry) => sum + entry.value);
    final colorScheme = Theme.of(context).colorScheme;
    final outerHeight = barHeight + _framePadding * 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: outerHeight,
          padding: const EdgeInsets.all(_framePadding),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(outerHeight / 2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widths = _segmentWidths(
                counts: [for (final entry in shown) entry.value],
                barWidth: constraints.maxWidth,
                minWidth: _minSegmentWidth,
                gap: _segmentGap,
              );

              return Row(
                children: [
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i > 0) const SizedBox(width: _segmentGap),
                    SizedBox(
                      width: widths[i],
                      height: barHeight,
                      // Rounded the same way the outer frame rounds the
                      // bar's own two ends — every segment reads as its
                      // own small pill rather than a sharp-cornered block,
                      // and a segment pinned to _minSegmentWidth (exactly
                      // as wide as the bar is tall) rounds all the way
                      // into a circle.
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorOf(shown[i].key),
                          borderRadius: BorderRadius.circular(barHeight / 2),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSizes.spacing12),
        Wrap(
          spacing: AppSizes.spacing12,
          runSpacing: AppSizes.spacing6,
          children: [
            for (final entry in shown)
              _LegendEntry(
                color: colorOf(entry.key),
                label: labelOf(entry.key),
                fraction: entry.value / total,
              ),
          ],
        ),
      ],
    );
  }
}

/// Resolves each segment's pixel width so every one of [counts] gets at
/// least [minWidth], with [gap] left between adjacent segments — rather
/// than a plain proportional (flex) split, which lets a small enough share
/// shrink below any legible width once enough other segments crowd it out.
///
/// Segments that would fall below [minWidth] are pinned to it; what's left
/// of [barWidth] is then split, in proportion to their own counts, among
/// the rest — repeated (pinning can only ever free up width for the
/// segments still unpinned, never take more away) until nothing further
/// drops below the minimum.
List<double> _segmentWidths({
  required List<int> counts,
  required double barWidth,
  required double minWidth,
  required double gap,
}) {
  final n = counts.length;
  final widths = List<double>.filled(n, 0);
  if (n == 0) return widths;

  final fixed = List<bool>.filled(n, false);
  var remainingWidth = (barWidth - gap * (n - 1)).clamp(0, double.infinity);
  var remainingTotal = counts.fold<int>(0, (sum, count) => sum + count);

  var changed = true;
  while (changed) {
    changed = false;
    for (var i = 0; i < n; i++) {
      if (fixed[i]) continue;
      final share = remainingTotal > 0
          ? remainingWidth * counts[i] / remainingTotal
          : 0.0;
      if (share < minWidth && remainingWidth > 0) {
        widths[i] = minWidth;
        fixed[i] = true;
        remainingWidth -= minWidth;
        remainingTotal -= counts[i];
        changed = true;
      }
    }
  }
  for (var i = 0; i < n; i++) {
    if (!fixed[i]) {
      widths[i] =
          remainingTotal > 0 ? remainingWidth * counts[i] / remainingTotal : 0;
    }
  }
  return widths;
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.color,
    required this.label,
    required this.fraction,
  });

  final Color color;
  final String label;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ColorDot(color: color),
        const SizedBox(width: AppSizes.spacing6),
        Text(
          '$label ${(fraction * 100).toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
        ),
      ],
    );
  }
}
