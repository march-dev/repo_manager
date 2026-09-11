import 'package:flutter/material.dart';

/// The shared chrome for a TableCard's column-header row: fixed height,
/// tinted background, and stretched cross-axis alignment (so a
/// `VerticalDivider` between columns spans the full row). Callers supply
/// their own columns/spacers/dividers as [children] — the two screens using
/// this differ enough in column count and divider placement that forcing a
/// single generic column API isn't worth it; only this outer shell repeats.
class TableHeaderRow extends StatelessWidget {
  const TableHeaderRow({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 32,
      padding: padding,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
