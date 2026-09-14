import 'package:flutter/material.dart';

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

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        count == null
            ? tool.label
            : '${tool.label} · $count ${count == 1 ? 'package' : 'packages'}',
        style: TextStyle(
          fontSize: 10,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );

    if (onTap == null) return badge;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: InkWell(onTap: onTap, child: badge),
    );
  }
}
