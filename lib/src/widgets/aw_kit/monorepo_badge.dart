import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../models/monorepo_tool.enum.dart';
import '../ui_kit/badges/pill_badge.dart';

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

    return PillBadge(
      onTap: onTap,
      child: Text(
        count == null
            ? tool.label
            : AppLocalizations.of(context)!.monorepoBadgeCount(
                tool.label,
                count!,
              ),
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
      ),
    );
  }
}
