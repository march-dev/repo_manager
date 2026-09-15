import 'package:flutter/material.dart';

import '../../../repo_manager.dart';

/// A project row's hover-only "Open In <ide>" hint — shown in place of (or
/// alongside) a row's own language/monorepo badges while the pointer is
/// over it, so the row doesn't need a separate tooltip to say which editor
/// a plain tap or double-click will actually open.
class OpenInHint extends StatelessWidget {
  const OpenInHint({super.key, required this.ide});

  final Ide ide;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.openInLabel,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: color,
                  ),
            ),
            const SizedBox(width: AppSizes.spacing4),
            Image(
              image: AssetImage(ide.iconAsset),
              width: AppSizes.iconXSmall,
              height: AppSizes.iconXSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing2),
        Text(
          ide.label,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }
}
