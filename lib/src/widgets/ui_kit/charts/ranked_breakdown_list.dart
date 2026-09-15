import 'package:flutter/material.dart';

import '../placeholders/empty_placeholder.dart';
import 'labeled_progress_bar.dart';

/// The top [maxRows] entries of [counts] (by count, descending) as
/// [LabeledProgressBar] rows scaled relative to the largest one — or an
/// [EmptyPlaceholder] when there's nothing to count.
class RankedBreakdownList<T> extends StatelessWidget {
  const RankedBreakdownList({
    super.key,
    required this.counts,
    required this.iconAssetOf,
    required this.fallbackIcon,
    required this.labelOf,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.maxRows = 8,
    this.barHeight = 8,
  });

  final Map<T, int> counts;
  final String? Function(T) iconAssetOf;
  final IconData fallbackIcon;
  final String Function(T) labelOf;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final int maxRows;
  final double barHeight;

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
    final shown = entries.take(maxRows).toList();
    final maxCount = shown.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        for (final entry in shown)
          LabeledProgressBar(
            iconAsset: iconAssetOf(entry.key),
            fallbackIcon: fallbackIcon,
            label: labelOf(entry.key),
            count: entry.value,
            fraction: entry.value / maxCount,
            height: barHeight,
          ),
      ],
    );
  }
}
