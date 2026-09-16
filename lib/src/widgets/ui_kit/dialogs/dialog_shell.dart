import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// The chrome shared by every small modal prompt in the app (a name
/// input, a yes/no confirmation, ...): a fixed-width rounded card with a
/// title, arbitrary body content, and a row of actions splitting the
/// available width evenly between them.
class DialogShell extends StatelessWidget {
  const DialogShell({
    super.key,
    required this.title,
    required this.child,
    required this.actions,
    this.width = 320,
  });

  final String title;
  final Widget child;

  /// Shown as one evenly-sized slot each, in order (e.g. Cancel, then the
  /// primary/destructive action) — typically a couple of [PrimaryButton]s.
  final List<Widget> actions;

  final double width;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      insetPadding: const EdgeInsets.all(48),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spacing20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // titleLarge rather than titleMedium — AppTypography
              // repurposes titleMedium as a small, letter-spaced *section*
              // heading (e.g. a folder-group row in a table), which reads
              // too small/dense for a dialog's own title. titleLarge is
              // one of the two slots AppTypography leaves at Material's
              // stock default specifically so a dialog title still has an
              // actual "title-sized" style available.
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSizes.spacing16),
              child,
              const SizedBox(height: AppSizes.spacing16),
              Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSizes.spacing8),
                    Expanded(child: actions[i]),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
