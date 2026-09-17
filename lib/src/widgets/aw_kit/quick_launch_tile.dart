import 'package:flutter/material.dart';

import '../../../repo_manager.dart';

/// A small rounded card launching straight into [project] — Dashboard's own
/// tile for its Pinned Projects/Recently Opened sections. A tap opens the
/// project in its resolved IDE; a double-click or the right-click menu's
/// "View Details" opens its details dialog instead. While hovered, the
/// language/monorepo badge line swaps to a plain "Open in <ide>" hint.
class QuickLaunchTile extends StatefulWidget {
  const QuickLaunchTile({
    super.key,
    required this.project,
    required this.collectionsState,
    required this.actions,
    this.width = 240,
    this.height = 64,
    this.iconSize = 36,
  });

  final ProjectModel project;
  final CollectionsState collectionsState;
  final ProjectActionsState actions;
  final double width;
  final double height;
  final double iconSize;

  @override
  State<QuickLaunchTile> createState() => _QuickLaunchTileState();
}

class _QuickLaunchTileState extends State<QuickLaunchTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        onSecondaryTapUp: (details) => showProjectContextMenu(
          context,
          project,
          details.globalPosition,
          collectionsState: widget.collectionsState,
          actions: widget.actions,
        ),
        child: AppCard(
          padding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          // A local Material ancestor so InkWell's own ripple paints here,
          // clipped to AppCard's rounded corners — see TableCard's own use
          // of this same pattern.
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => widget.actions.openInEditor(project),
              onDoubleTap: () => showProjectDetailsDialog(
                context,
                project,
                collectionsState: widget.collectionsState,
                actions: widget.actions,
              ),
              onHover: (hovering) => setState(() => _hovering = hovering),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing12,
                  vertical: AppSizes.spacing8,
                ),
                child: ProjectRow(
                  project: project,
                  iconSize: widget.iconSize,
                  gap: AppSizes.spacing10,
                  titleStyle: Theme.of(context).textTheme.titleSmall,
                  subtitle: _hovering
                      ? Text(
                          AppLocalizations.of(context)!.openInIdeLabel(
                            widget.actions.resolveIde(project).label,
                          ),
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    fontSize: 11,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        )
                      : ProjectLanguageBadge(
                          language: project.language,
                          framework: project.framework,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
