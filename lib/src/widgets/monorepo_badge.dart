import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../models/monorepo_tool.enum.dart';

/// A small pill next to a monorepo root's language badge, naming its
/// workspace tool and how many member packages it manages — shown in both
/// Explorer and Storage. [onTap], when given, makes the badge itself the
/// entry point into that tree (e.g. a dialog listing the member packages)
/// rather than the row growing its own always-visible expand/collapse UI.
///
/// [count] is null while that tree is still being fetched in the
/// background (see ProjectModel.subPackagesLoaded) — building it is real
/// filesystem work, deliberately deferred so the project list itself
/// shows up immediately, so the badge just names the tool until the real
/// count is known instead of blocking on it.
class MonorepoBadge extends StatelessWidget {
  const MonorepoBadge({
    super.key,
    required this.tool,
    required this.count,
    this.onTap,
  });

  final MonorepoTool tool;
  final int? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = this.count;

    final label = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Text(
        count == null
            ? tool.label
            : AppLocalizations.of(context)!.monorepoBadgeCount(
                tool.label,
                count,
              ),
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
      ),
    );

    // The pill's own background now lives on this Material (rather than a
    // separately-decorated Container) so its ink response paints here too
    // — on top of the background, under the label, clipped to the same
    // rounded shape. A Container decoration on the InkWell's child would
    // otherwise sit *above* the ink splash (which paints on the nearest
    // ancestor Material, further down in the tree than one might expect)
    // and hide it — visible, if at all, only through the decoration's own
    // rounded corners' rectangular cutout, i.e. exactly at the pill's
    // corners rather than across its face.
    final borderRadius = BorderRadius.circular(4);
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? label : InkWell(onTap: onTap, child: label),
    );
  }
}
