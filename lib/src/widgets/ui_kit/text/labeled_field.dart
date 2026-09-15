import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// A small muted label over an arbitrary value — one field in a details
/// panel (a path, a chosen editor, ...).
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: color,
              ),
        ),
        const SizedBox(height: AppSizes.spacing4),
        child,
      ],
    );
  }
}
