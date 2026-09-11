import 'package:flutter/material.dart';

/// The rounded, bordered card shared by every screen's top-of-page header:
/// a title row (with optional trailing actions) and, optionally, more
/// content below it (e.g. storage.screen.dart's size bar/summary).
class HeaderCard extends StatelessWidget {
  const HeaderCard({
    super.key,
    required this.title,
    this.actions = const [],
    this.child,
    this.margin = const EdgeInsets.all(16),
  });

  final String title;

  /// Trailing widgets in the title row, right-aligned after a [Spacer].
  final List<Widget> actions;

  /// Extra content shown below the title row, separated by a fixed gap.
  final Widget? child;

  /// Defaults to surrounding the card on all sides, for use as a standalone
  /// screen header (storage.screen.dart, explorer.screen.dart). Pass
  /// [EdgeInsets.zero] when stacking several of these and handling spacing
  /// externally instead (settings.screen.dart).
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              ...actions,
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 12),
            child!,
          ],
        ],
      ),
    );
  }
}
