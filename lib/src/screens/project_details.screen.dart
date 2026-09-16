import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../repo_manager.dart';

/// Shows a project's details in a dialog — its icon/name/language, and,
/// for a monorepo, its member-package tree. Separate from Explorer's main
/// list so browsing/opening a member package doesn't require the list
/// itself to carry expand/collapse state (and the visual weight that
/// comes with it) for every row, monorepo or not.
Future<void> showProjectDetailsDialog(
  BuildContext context,
  ProjectModel project,
) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      // The dialog's own Material surface is the card — matching
      // TableCard's radius rather than Material's much rounder default
      // dialog shape, and clipped so scrolled rows don't visibly poke past
      // those corners. ProjectDetailsDialog's content fills it plainly
      // (no nested background/border of its own), instead of a second
      // card floating inside this one.
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      ),
      // A small fixed margin all around rather than a fixed pixel size —
      // SizedBox.expand just claims whatever that leaves, so this reacts
      // to the window being resized the same way any other layout would
      // (plain constraint-based relayout), no MediaQuery/rebuild wiring
      // needed.
      insetPadding: const EdgeInsets.all(48),
      child: SizedBox.expand(
        child: ProjectDetailsDialog(project: project),
      ),
    ),
  );
}

class ProjectDetailsDialog extends StatefulWidget {
  const ProjectDetailsDialog({super.key, required this.project});

  final ProjectModel project;

  @override
  State<ProjectDetailsDialog> createState() => _ProjectDetailsDialogState();
}

class _ProjectDetailsDialogState extends State<ProjectDetailsDialog> {
  // Local to this dialog rather than ExplorerStore — the tree is rebuilt
  // fresh every time it's opened anyway, so there's nothing worth
  // persisting past its own lifetime.
  final _expanded = <String>{};
  bool _sortAscending = true;

  // The row that opened this dialog may have been tapped before the
  // background load (see ExplorerStore/StorageStore._loadSubPackagesInBackground)
  // finished for this specific project — fetch it directly in that case
  // rather than showing an empty tree.
  late ProjectModel _project = widget.project;

  @override
  void initState() {
    super.initState();
    if (!_project.subPackagesLoaded) {
      // Nothing to show yet at all (cached or otherwise) — load(),
      // which reads the Hive-cached tree if there is one, and only
      // actually rescans the filesystem if there isn't.
      projectScannerStore.loadSubPackages(_project).then((updated) {
        if (mounted) setState(() => _project = updated);
      });
    } else {
      // Already showing a tree (fresh or from cache) — quietly rescan in
      // the background so a package added/removed on disk since the
      // cache was written shows up without the visible loading state,
      // same "show the cached one now, update silently" pattern project
      // sizes already use.
      projectScannerStore.loadSubPackages(_project, forceRefresh: true).then((
        updated,
      ) {
        if (mounted) setState(() => _project = updated);
      });
    }
  }

  void _toggle(String path) {
    setState(() {
      if (!_expanded.remove(path)) _expanded.add(path);
    });
  }

  void _toggleSort() => setState(() => _sortAscending = !_sortAscending);

  // Folders first, then projects — each group alphabetized by [_sortAscending]
  // independently, so reversing the sort only flips the order *within* each
  // group rather than interleaving folders and projects, matching how
  // Finder/VS Code/most file browsers keep containers grouped ahead of
  // leaves regardless of sort direction.
  List<WorkspaceEntry> _sorted(List<WorkspaceEntry> entries) {
    int compareNames(WorkspaceEntry a, WorkspaceEntry b) {
      final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return _sortAscending ? comparison : -comparison;
    }

    final folders = entries.whereType<WorkspaceFolderEntry>().toList()
      ..sort(compareNames);
    final projects = entries.whereType<WorkspaceProjectEntry>().toList()
      ..sort(compareNames);

    return [...folders, ...projects];
  }

  // A running index across the *whole* flattened tree (not reset per
  // level), so alternating row shading reads the same way AppTable's own
  // zebra striping does — continuous down the visible list, regardless of
  // how deep any particular row is nested.
  var _zebraIndex = 0;

  List<Widget> _buildRows(List<WorkspaceEntry> entries, int depth) {
    final rows = <Widget>[];
    for (final entry in _sorted(entries)) {
      final expanded = _expanded.contains(entry.path);
      final zebra = _zebraIndex.isOdd;
      _zebraIndex++;

      switch (entry) {
        case WorkspaceProjectEntry(:final project):
          final hasChildren = project.subPackages.isNotEmpty;
          rows.add(
            _SubPackageRow(
              zebra: zebra,
              depth: depth,
              icon: ProjectIcon(
                  iconPath: project.iconPath, size: AppSizes.rowIconSize),
              title: project.name,
              subtitle: ProjectLanguageBadge(
                language: project.language,
                framework: project.framework,
              ),
              ide: ideLauncherStore.resolveIde(project),
              expandable: hasChildren,
              expanded: expanded,
              onToggle: hasChildren ? () => _toggle(entry.path) : null,
              onTap: () {
                Navigator.of(context).pop();
                ideLauncherStore.openInEditor(project);
              },
              onSecondaryTapUp: (context, position) =>
                  showProjectContextMenu(context, project, position),
            ),
          );
          if (hasChildren && expanded) {
            rows.addAll(_buildRows(project.subPackages, depth + 1));
          }
        case WorkspaceFolderEntry(:final children):
          rows.add(
            _SubPackageRow(
              zebra: zebra,
              depth: depth,
              // FolderIcon's "stack of packages" glyph reads as "a grouping
              // of packages" rather than a real project that simply has no
              // discovered icon — and doesn't need an expanded/collapsed
              // variant since the chevron already shows that state.
              icon: const FolderIcon(size: AppSizes.rowIconSize),
              title: entry.name,
              // Same slot a project row fills with its ProjectLanguageBadge
              // — a folder has no language of its own, so this reports how
              // many real projects it groups (recursively) instead, same
              // as Explorer's own folder/collection section headers do.
              subtitle: Text(
                AppLocalizations.of(context)!.workspaceFolderProjectCount(
                  children.projectCount,
                ),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
              expandable: true,
              expanded: expanded,
              onToggle: () => _toggle(entry.path),
              // Folders aren't openable in an IDE — no language to resolve
              // one from — tapping the row just does what the chevron does.
              onTap: () => _toggle(entry.path),
              onSecondaryTapUp: (context, position) =>
                  showFolderContextMenu(context, entry.path, position),
            ),
          );
          if (expanded) rows.addAll(_buildRows(children, depth + 1));
      }
    }
    return rows;
  }

  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    final isMonorepo = project.monorepoTool != null;
    _zebraIndex = 0;
    final rows =
        isMonorepo ? _buildRows(project.subPackages, 0) : const <Widget>[];

    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      // CallbackShortcuts only intercepts key events reaching a focused
      // descendant — without this, Escape wouldn't do anything unless
      // some other focusable widget already held focus.
      child: Focus(
        autofocus: true,
        // No card decoration of its own here — the Dialog that hosts this
        // widget (see showProjectDetailsDialog) is already the card;
        // wrapping this content in another bordered/backgrounded box (e.g.
        // TableCard) would just nest a second, redundant one inside it.
        //
        // ContextMenuRegion wraps everything below so any row's
        // right-click menu (project or folder) has somewhere to open into
        // — see showProjectContextMenu/showFolderContextMenu.
        child: ContextMenuRegion(
          child: Column(
            children: [
              _DialogHeader(project: project, isMonorepo: isMonorepo),
              const HairlineDivider(),
              if (isMonorepo)
                Expanded(
                  child: _MonorepoTree(
                    sortAscending: _sortAscending,
                    onToggleSort: _toggleSort,
                    subPackagesLoaded: project.subPackagesLoaded,
                    scrollController: _scrollController,
                    rows: rows,
                  ),
                )
              else
                Expanded(
                  child: _DetailsPanel(
                    project: project,
                    ide: ideLauncherStore.resolveIde(project),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.project, required this.isMonorepo});

  final ProjectModel project;
  final bool isMonorepo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spacing16,
        AppSizes.spacing12,
        AppSizes.spacing8,
        AppSizes.spacing12,
      ),
      child: Row(
        children: [
          ProjectIcon(iconPath: project.iconPath, size: AppSizes.iconHuge),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: _DialogTitleAndBadge(
              project: project,
              isMonorepo: isMonorepo,
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.xmark, size: AppSizes.iconMedium),
            tooltip: AppLocalizations.of(context)!.closeTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _DialogTitleAndBadge extends StatelessWidget {
  const _DialogTitleAndBadge({
    required this.project,
    required this.isMonorepo,
  });

  final ProjectModel project;
  final bool isMonorepo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          project.name,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.spacing2),
        if (isMonorepo)
          MonorepoBadge(
            tool: project.monorepoTool!,
            count: project.subPackagesLoaded
                ? project.subPackages.projectCount
                : null,
          )
        else
          ProjectLanguageBadge(
            language: project.language,
            framework: project.framework,
          ),
      ],
    );
  }
}

// The sort header + scrollable member-package tree shown for a monorepo
// project — a loading spinner in place of the tree until its subpackages
// (cached or freshly scanned) are known.
class _MonorepoTree extends StatelessWidget {
  const _MonorepoTree({
    required this.sortAscending,
    required this.onToggleSort,
    required this.subPackagesLoaded,
    required this.scrollController,
    required this.rows,
  });

  final bool sortAscending;
  final VoidCallback onToggleSort;
  final bool subPackagesLoaded;
  final ScrollController scrollController;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableHeaderRow(
          padding: const EdgeInsets.only(left: AppSizes.spacing16),
          children: [
            Expanded(
              child: HeaderSortableButton(
                text: AppLocalizations.of(context)!.nameColumnHeader,
                ascending: sortAscending,
                onChanged: (_) => onToggleSort(),
              ),
            ),
          ],
        ),
        const HairlineDivider(),
        Expanded(
          child: subPackagesLoaded
              ? Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  child: ListView(
                    controller: scrollController,
                    children: rows,
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

// Shown in place of the member-package tree for a plain, non-monorepo
// project — there's nothing to browse, so this is the whole of its
// "details" instead of an empty table.
class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.project, required this.ide});

  final ProjectModel project;
  final Ide ide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledField(
            label: l10n.pathLabel,
            child: SelectableText(project.path),
          ),
          const SizedBox(height: AppSizes.spacing12),
          LabeledField(
            label: l10n.openWithLabel,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image(
                    image: AssetImage(ide.iconAsset),
                    width: AppSizes.iconSmall,
                    height: AppSizes.iconSmall),
                const SizedBox(width: AppSizes.spacing6),
                Text(ide.label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubPackageRow extends StatelessWidget {
  const _SubPackageRow({
    required this.zebra,
    required this.depth,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ide,
    required this.expandable,
    required this.expanded,
    this.onToggle,
    required this.onTap,
    required this.onSecondaryTapUp,
  });

  final bool zebra;
  final int depth;
  final Widget icon;
  final String title;
  final Widget? subtitle;

  // Only set for project rows — a folder has no language to resolve an
  // IDE from, so it never gets the hover "Open In" hint.
  final Ide? ide;

  final bool expandable;
  final bool expanded;
  final VoidCallback? onToggle;
  final VoidCallback onTap;

  // Right-click menu — showProjectContextMenu for a project row,
  // showFolderContextMenu for a folder.
  final void Function(BuildContext context, Offset globalPosition)
      onSecondaryTapUp;

  @override
  Widget build(BuildContext context) {
    return HoverableRow(
      height: AppSizes.rowHeight,
      zebra: zebra,
      onTap: onTap,
      onSecondaryTapUp: onSecondaryTapUp,
      builder: (context, isHovered) => _TreeRowContent(
        depth: depth,
        icon: icon,
        title: title,
        subtitle: subtitle,
        ide: ide,
        expandable: expandable,
        expanded: expanded,
        onToggle: onToggle,
        isHovered: isHovered,
      ),
    );
  }
}

class _TreeRowContent extends StatelessWidget {
  const _TreeRowContent({
    required this.depth,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ide,
    required this.expandable,
    required this.expanded,
    required this.onToggle,
    required this.isHovered,
  });

  final int depth;
  final Widget icon;
  final String title;
  final Widget? subtitle;
  final Ide? ide;
  final bool expandable;
  final bool expanded;
  final VoidCallback? onToggle;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.spacing16 + depth * AppSizes.spacing20,
        0,
        AppSizes.spacing16,
        0,
      ),
      child: Row(
        children: [
          _ExpandChevronSlot(
            expandable: expandable,
            expanded: expanded,
            onToggle: onToggle,
            color: color,
          ),
          const SizedBox(width: AppSizes.spacing6),
          // A fixed-size slot rather than the icon's own natural size — a
          // folder's smaller glyph would otherwise shift the name/badge
          // column left compared to a project row's larger one, breaking
          // the alignment between them.
          SizedBox(
            width: AppSizes.rowIconSize,
            height: AppSizes.rowIconSize,
            child: Center(child: icon),
          ),
          // Same AppSizes.spacing16 gap explorer.screen.dart/
          // storage.screen.dart's own rows use here.
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child: _RowTitleAndSubtitle(
              title: title,
              subtitle: subtitle,
              color: color,
            ),
          ),
          // Same hover-only "Open In" hint as Explorer's own rows.
          if (isHovered && ide != null) ...[
            const SizedBox(width: AppSizes.spacing16),
            OpenInHint(ide: ide!),
          ],
        ],
      ),
    );
  }
}

// Every row reserves this slot (chevron or blank) regardless of whether
// it's expandable, so icons still line up within their own depth level.
class _ExpandChevronSlot extends StatelessWidget {
  const _ExpandChevronSlot({
    required this.expandable,
    required this.expanded,
    required this.onToggle,
    required this.color,
  });

  final bool expandable;
  final bool expanded;
  final VoidCallback? onToggle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.spacing20,
      height: AppSizes.spacing20,
      // A plain GestureDetector rather than an InkWell — this chevron sits
      // right next to (and, for a folder, right under) a much bigger ink
      // splash from the row's own InkWell, so its own tiny ripple just
      // reads as visual noise rather than useful feedback. The nested
      // detector still claims the tap before it reaches the row's own
      // onTap.
      child: expandable
          ? GestureDetector(
              // Opaque so the whole reserved box is tappable, not just the
              // icon glyph's own painted pixels.
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: Icon(
                expanded
                    ? CupertinoIcons.chevron_down
                    : CupertinoIcons.chevron_right,
                size: AppSizes.iconXSmall,
                color: color.withValues(alpha: 0.7),
              ),
            )
          : null,
    );
  }
}

class _RowTitleAndSubtitle extends StatelessWidget {
  const _RowTitleAndSubtitle({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final Widget? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: color,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSizes.spacing2),
          subtitle!,
        ],
      ],
    );
  }
}
