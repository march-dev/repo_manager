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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

const _treeIndent = 20.0;
const _treeExpandSize = 20.0;
// Matches AppTable's own default row height, so this tree's rows read as
// the same kind of table as Explorer/Storage rather than a different,
// more cramped list.
const _rowHeight = 56.0;
const _rowPadding = 16.0;
const _rowIconSize = 40.0;
// A folder entry has no ProjectIcon of its own to draw its badge for it,
// so this matches ProjectIcon's own glyph/badge proportions by hand.
const _rowIconGlyphSize = 22.0;

// Mirrors ProjectIcon's own badge background, for the folder-entry glyph
// (which isn't a ProjectIcon at all, so doesn't get one automatically).
Widget _iconBadge(BuildContext context, Widget child) {
  return Container(
    width: _rowIconSize,
    height: _rowIconSize,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
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
      ProjectRepo().loadSubPackages(_project).then((updated) {
        if (mounted) setState(() => _project = updated);
      });
    } else {
      // Already showing a tree (fresh or from cache) — quietly rescan in
      // the background so a package added/removed on disk since the
      // cache was written shows up without the visible loading state,
      // same "show the cached one now, update silently" pattern project
      // sizes already use.
      ProjectRepo().loadSubPackages(_project, forceRefresh: true).then((
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
              // ProjectIcon itself now draws its own badge background and
              // shrinks its folder-glyph fallback onto it.
              icon: ProjectIcon(
                iconPath: project.iconPath,
                size: _rowIconSize,
              ),
              title: project.name,
              subtitle: ProjectLanguageBadge(
                language: project.language,
                framework: project.framework,
              ),
              ide: ProjectRepo().resolveIde(project),
              expandable: hasChildren,
              expanded: expanded,
              onToggle: hasChildren ? () => _toggle(entry.path) : null,
              onTap: () {
                Navigator.of(context).pop();
                ProjectRepo().openInEditor(project);
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
              // A plain folder glyph here would be indistinguishable from
              // ProjectIcon's own fallback (shown when a real project has
              // no discovered icon) — this reads as "a grouping of
              // packages" instead, which a container directory actually
              // is, and doesn't need an expanded/collapsed variant since
              // the chevron already shows that state.
              icon: _iconBadge(
                context,
                const Icon(
                  CupertinoIcons.square_stack_3d_up,
                  size: _rowIconGlyphSize,
                ),
              ),
              title: entry.name,
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
    final colorScheme = Theme.of(context).colorScheme;
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
        // ProjectContextMenuRegion wraps everything below so any row's
        // right-click menu (project or folder) has somewhere to open into
        // — see showProjectContextMenu/showFolderContextMenu.
        child: ProjectContextMenuRegion(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    ProjectIcon(iconPath: project.iconPath, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
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
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark, size: 18),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              if (isMonorepo) ...[
                TableHeaderRow(
                  padding: const EdgeInsets.only(left: _rowPadding),
                  children: [
                    Expanded(
                      child: HeaderSortableButton(
                        text: 'Name',
                        ascending: _sortAscending,
                        onChanged: (_) => _toggleSort(),
                      ),
                    ),
                  ],
                ),
                Divider(height: 1, color: colorScheme.outlineVariant),
                Expanded(
                  child: project.subPackagesLoaded
                      ? Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: ListView(
                            controller: _scrollController,
                            children: rows,
                          ),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ] else
                Expanded(
                  child: _DetailsPanel(
                    project: project,
                    ide: ProjectRepo().resolveIde(project),
                  ),
                ),
            ],
          ),
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.all(_rowPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: 'Path', child: SelectableText(project.path)),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Open With',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image(image: AssetImage(ide.iconAsset), width: 16, height: 16),
                const SizedBox(width: 6),
                Text(ide.label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.child});

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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _SubPackageRow extends StatefulWidget {
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
  State<_SubPackageRow> createState() => _SubPackageRowState();
}

class _SubPackageRowState extends State<_SubPackageRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.onSurface;

    return ColoredBox(
      color: widget.zebra
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
          : Colors.transparent,
      child: GestureDetector(
        onSecondaryTapUp: (details) =>
            widget.onSecondaryTapUp(context, details.globalPosition),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (hovering) => setState(() => _hovering = hovering),
            child: SizedBox(
              height: _rowHeight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _rowPadding + widget.depth * _treeIndent,
                  0,
                  _rowPadding,
                  0,
                ),
                child: Row(
                  children: [
                    // Every row reserves this slot (chevron or blank)
                    // regardless of whether it's expandable, so icons still
                    // line up within their own depth level.
                    SizedBox(
                      width: _treeExpandSize,
                      height: _treeExpandSize,
                      // A plain GestureDetector rather than an InkWell —
                      // this chevron sits right next to (and, for a
                      // folder, right under) a much bigger ink splash from
                      // the row's own InkWell, so its own tiny ripple just
                      // reads as visual noise rather than useful feedback.
                      // The nested detector still claims the tap before it
                      // reaches the row's own onTap.
                      child: widget.expandable
                          ? GestureDetector(
                              // Opaque so the whole reserved box is
                              // tappable, not just the icon glyph's own
                              // painted pixels.
                              behavior: HitTestBehavior.opaque,
                              onTap: widget.onToggle,
                              child: Icon(
                                widget.expanded
                                    ? CupertinoIcons.chevron_down
                                    : CupertinoIcons.chevron_right,
                                size: 14,
                                color: color.withValues(alpha: 0.7),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    // A fixed-size slot rather than the icon's own natural
                    // size — a folder's smaller glyph would otherwise
                    // shift the name/badge column left compared to a
                    // project row's larger one, breaking the alignment
                    // between them.
                    SizedBox(
                      width: _rowIconSize,
                      height: _rowIconSize,
                      child: Center(child: widget.icon),
                    ),
                    // Matches explorer.screen.dart/storage.screen.dart's own
                    // gap here (_rowPadding/_iconGap, both 16) instead of a
                    // separately-guessed value.
                    const SizedBox(width: _rowPadding),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: color),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            widget.subtitle!,
                          ],
                        ],
                      ),
                    ),
                    // Same hover-only "Open In" hint as Explorer's own rows.
                    if (_hovering && widget.ide != null) ...[
                      const SizedBox(width: _rowPadding),
                      _OpenInHint(ide: widget.ide!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenInHint extends StatelessWidget {
  const _OpenInHint({required this.ide});

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
              'Open In',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Image(image: AssetImage(ide.iconAsset), width: 14, height: 14),
          ],
        ),
        const SizedBox(height: 2),
        Text(ide.label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}
