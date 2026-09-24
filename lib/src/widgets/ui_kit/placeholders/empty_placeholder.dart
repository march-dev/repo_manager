import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// An icon, title and message shown in place of an empty list/section —
/// e.g. "no pinned projects yet".
class EmptyPlaceholder extends StatelessWidget {
  const EmptyPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.centered = false,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Centers the icon/title row and the message within this widget's own
  /// (shrink-wrapped) width, instead of the default left alignment — for
  /// a caller that's centering this whole widget in a larger empty area
  /// of its own (e.g. project_details.screen.dart's Git placeholder,
  /// wrapped in a `Center`), as opposed to the default, which lines this
  /// up with a left-aligned section title next to it (e.g. Dashboard's
  /// "No pinned projects yet").
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    final crossAxisAlignment =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing4),
      child: Column(
        // Shrink-wraps to its own content height rather than Column's
        // default of filling whatever height its parent offers — without
        // this, wrapping the whole widget in a Center (e.g.
        // project_details.screen.dart's Git placeholder) does nothing,
        // since a full-height child leaves Center nothing to center.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Row(
            // Same reason as the outer Column's own mainAxisSize — without
            // this, this Row claims the full width Center offers it (Row
            // defaults to MainAxisSize.max too), which then forces the
            // whole widget just as wide, leaving its content reading as
            // pinned to the left of that full-width box regardless of
            // [crossAxisAlignment] above.
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.iconLarge, color: color),
              const SizedBox(width: AppSizes.spacing10),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing4),
          Text(
            message,
            textAlign: centered ? TextAlign.center : null,
            style:
                Theme.of(context).textTheme.bodySmall!.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
