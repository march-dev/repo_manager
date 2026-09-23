import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../models/monorepo_tool.enum.dart';
import '../ui_kit/badges/pill_badge.dart';

/// A small pill next to a project's language badge, naming a workspace
/// tool. Two different things reuse this same pill: a monorepo *root*
/// (Explorer/Storage, and project_details.screen.dart's own dialog
/// header), naming the tool it manages and how many member packages it
/// has (see [count]); and a monorepo *member*, in project_details' own
/// tree (a project row's [ProjectModel.workspaceTool], or a folder row's
/// [WorkspaceEntry.sharedWorkspaceTool]), naming the tool that manages
/// the workspace it belongs to, with [count] always null since a member
/// doesn't itself have a package count to report. [onTap], when given,
/// makes the badge itself the entry point into that tree (e.g. a dialog
/// listing the member packages) rather than the row growing its own
/// always-visible expand/collapse UI.
///
/// For a root, [count] is null while that tree is still being fetched in
/// the background (see [ProjectModel.subPackagesLoaded]) — building it is
/// real filesystem work, deliberately deferred so the project list itself
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
