import 'package:flutter/material.dart';

/// A big value over a small muted label — a single stat in a summary card
/// (a total count, a formatted size, ...).
class StatText extends StatelessWidget {
  const StatText({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: valueColor ?? colorScheme.onSurface,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }
}
