import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

class ExplorerScreen extends StatelessWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<ExplorerStore>(
      create: (_) => ExplorerStore(),
      child: const _Scaffold(),
    );
  }
}

// Row layout constants, shared between _ProjectRow and _ProjectsTableHeader
// so the header's "Name" label and sort control line up with the icon/name
// column of each row below it. Matches storage.screen.dart's own icon
// size/gap (_projectIconSize/_iconGap) so both screens' rows look identical.
const _rowPadding = 16.0;
const _rowIconSize = 40.0;
const _favouriteIconSize = 20.0;
// Matches storage.screen.dart's _columnGap, used the same way: padding
// around the trailing icon-button column.
const _columnGap = 12.0;
// Matches storage.screen.dart's _ProjectListTile row height.
const _rowHeight = 56.0;
// Reserved so TableCard's always-visible scrollbar has its own lane instead
// of floating as an overlay on top of the favourite column.
const _scrollbarGutter = 12.0;
const _dirSectionHeaderHeight = 36.0;

class _Scaffold extends StatelessWidget {
  const _Scaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _ExplorerToolbar(),
            Expanded(
              child: TableCard(
                header: const _ProjectsTableHeader(),
                bodyBuilder: (context, scrollController) =>
                    _ExplorerBody(scrollController: scrollController),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplorerToolbar extends StatelessObserverWidget {
  const _ExplorerToolbar();

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();

    return HeaderCard(
      title: 'Projects Explorer',
      actions: [
        SegmentedButton<ExplorerGrouping>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: ExplorerGrouping.none,
              label: Text('None'),
              icon: Icon(CupertinoIcons.square_stack),
            ),
            ButtonSegment(
              value: ExplorerGrouping.byFolder,
              label: Text('By Folder'),
              icon: Icon(CupertinoIcons.folder),
            ),
          ],
          selected: {store.grouping},
          onSelectionChanged: (selection) => store.setGrouping(selection.first),
        ),
      ],
    );
  }
}

// Shows a sortable "Name" column header, matching storage.screen.dart's
// table header. TableCard draws the divider below it.
class _ProjectsTableHeader extends StatelessObserverWidget {
  const _ProjectsTableHeader();

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();
    final colorScheme = Theme.of(context).colorScheme;

    return TableHeaderRow(
      children: [
        Expanded(
          child: SortableColumnHeader(
            label: 'Name',
            active: true,
            ascending: store.sortAscending,
            onTap: store.toggleNameSort,
            padding:
                const EdgeInsets.only(left: _rowIconSize + _rowPadding * 2),
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant,
        ),
        // Matches storage.screen.dart's actions-column formula exactly
        // (_actionsColumnWidth + _columnGap * 2) — the row wraps
        // _FavouriteButton in the same Padding(_columnGap) + SizedBox pattern
        // storage.screen.dart uses for _ProjectCleanupButton. The pin toggle
        // sits centered in that same reserved width, directly above the
        // favourite column it controls.
        SizedBox(
          width: _FavouriteButton.size + _columnGap * 2,
          // An InkWell rather than an IconButton, matching the "Name" header
          // next to it (see SortableColumnHeader) instead of looking like a
          // stray action button — the icon is sized to sit next to that
          // header's own 11px label/12px sort arrow instead of a full
          // IconButton's much larger default tap target.
          child: ClipRect(
            child: Tooltip(
              message: store.pinFavourites
                  ? 'Favourites pinned to top'
                  : 'No pinning',
              child: InkWell(
                onTap: store.togglePinFavourites,
                child: Center(
                  child: Icon(
                    store.pinFavourites
                        ? CupertinoIcons.pin_fill
                        : CupertinoIcons.pin_slash,
                    size: 12,
                    color: store.pinFavourites
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant,
        ),
        const SizedBox(width: _scrollbarGutter),
      ],
    );
  }
}

class _ExplorerBody extends StatelessObserverWidget {
  const _ExplorerBody({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();
    final colorScheme = Theme.of(context).colorScheme;

    if (store.projects.isEmpty) {
      return _EmptyProjectList(
        scrollController: scrollController,
        message: 'No projects found. Add a directory in Settings.',
        colorScheme: colorScheme,
      );
    }

    if (store.grouping == ExplorerGrouping.byFolder) {
      return _ProjectGroupedView(
        scrollController: scrollController,
        grouped: store.groupedProjects,
      );
    }

    return _ProjectListView(
      scrollController: scrollController,
      projects: store.visibleProjects,
    );
  }
}

// A Scrollbar with `thumbVisibility: true` asserts that its controller has
// an attached ScrollPosition, so the empty state needs to be a real
// Scrollable (not a bare Center) — sized to the viewport so the message
// still reads as vertically centered.
class _EmptyProjectList extends StatelessWidget {
  const _EmptyProjectList({
    required this.scrollController,
    required this.message,
    required this.colorScheme,
  });

  final ScrollController scrollController;
  final String message;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        controller: scrollController,
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectListView extends StatelessWidget {
  const _ProjectListView({
    required this.scrollController,
    required this.projects,
  });

  final ScrollController scrollController;
  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4)
          .copyWith(right: _scrollbarGutter),
      itemCount: projects.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: colorScheme.outlineVariant),
      itemBuilder: (context, index) =>
          _ProjectRow(project: projects[index], index: index),
    );
  }
}

// Everything lives in one continuous, scrollable table — same TableCard,
// same persistent "Name" header up top (see _Scaffold) — rather than a
// stack of separately-bordered cards. Each folder just gets a lightweight
// inline section header between its rows and the next folder's.
class _ProjectGroupedView extends StatelessWidget {
  const _ProjectGroupedView({
    required this.scrollController,
    required this.grouped,
  });

  final ScrollController scrollController;
  final Map<String, List<ProjectModel>> grouped;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final commonPrefix =
        commonDirPrefix(entries.map((entry) => entry.key).toList());

    final children = <Widget>[];
    var rowIndex = 0;
    for (var g = 0; g < entries.length; g++) {
      final entry = entries[g];
      // A visible gap between sections (not just a hairline) so it's
      // unmistakable where one folder ends and the next begins — sized to
      // match the section header itself, so the empty gap and the header
      // read as the same kind of "breathing room".
      if (g > 0) {
        children.add(const SizedBox(height: _dirSectionHeaderHeight));
      }
      children.add(
        _DirSectionHeader(
          fullPath: entry.key,
          displayPath: stripCommonPrefix(entry.key, commonPrefix),
        ),
      );
      for (var i = 0; i < entry.value.length; i++) {
        if (i > 0) {
          children.add(Divider(height: 1, color: colorScheme.outlineVariant));
        }
        children.add(_ProjectRow(project: entry.value[i], index: rowIndex++));
      }
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4)
          .copyWith(right: _scrollbarGutter),
      children: children,
    );
  }
}

class _DirSectionHeader extends StatelessWidget {
  const _DirSectionHeader({required this.fullPath, required this.displayPath});

  final String fullPath;
  final String displayPath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: _dirSectionHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: _rowPadding),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Tooltip(
        message: fullPath,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.folder_fill,
              size: 16,
              color: colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                displayPath,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.3,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectRow extends StatefulWidget {
  const _ProjectRow({required this.project, required this.index});

  final ProjectModel project;
  final int index;

  @override
  State<_ProjectRow> createState() => _ProjectRowState();
}

class _ProjectRowState extends State<_ProjectRow> {
  bool _hovering = false;

  Future<void> _showContextMenu(Offset globalPosition) async {
    final project = widget.project;
    final store = context.read<ExplorerStore>();
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      Offset.zero & overlay.size,
    );

    // Flutter and React Native share the same ios/android(/...) platform
    // subfolder convention — see PlatformTarget for which frameworks this
    // currently covers.
    final platformTargets = await store.platformTargetsFor(project);

    if (!context.mounted) return;

    final selected = await showMenu<VoidCallback>(
      context: context,
      position: position,
      items: [
        for (final ide in project.language.supportedIdes)
          PopupMenuItem(
            value: () => store.openProjectInIde(project, ide),
            child: _IdeMenuEntry(ide: ide, label: 'Open in ${ide.label}'),
          ),
        if (platformTargets.isNotEmpty) ...[
          const PopupMenuDivider(),
          for (final target in platformTargets)
            PopupMenuItem(
              value: () => store.openPlatformTarget(project, target),
              child: _IdeMenuEntry(
                ide: target.ide,
                label: 'Open ${target.label} project',
              ),
            ),
        ],
      ],
    );

    selected?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final project = widget.project;

    return GestureDetector(
      onSecondaryTapUp: (details) => _showContextMenu(details.globalPosition),
      child: ColoredBox(
        color: widget.index.isOdd
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
            : Colors.transparent,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.read<ExplorerStore>().openProject(project),
            onHover: (hovering) => setState(() => _hovering = hovering),
            child: SizedBox(
              height: _rowHeight,
              child: Row(
                children: [
                  const SizedBox(width: _rowPadding),
                  ProjectIcon(iconPath: project.iconPath, size: _rowIconSize),
                  const SizedBox(width: _rowPadding),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              ProjectLanguageBadge(
                                language: project.language,
                                framework: project.framework,
                              ),
                            ],
                          ),
                        ),
                        // Replaces a plain hover tooltip with the same "Open
                        // in <IDE>" text shown inline, at the end of the
                        // name section, only while the row is hovered.
                        if (_hovering) ...[
                          const SizedBox(width: _rowPadding),
                          _OpenInHint(ide: ProjectRepo().resolveIde(project)),
                          const SizedBox(width: _rowPadding),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 1),
                  // Matches storage.screen.dart's actions column: the row
                  // wraps the button in the same Padding(_columnGap) +
                  // SizedBox pattern used for _ProjectCleanupButton, so the
                  // reserved column width lines up with the header exactly.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _columnGap),
                    child: SizedBox(
                      width: _FavouriteButton.size,
                      child: Center(child: _FavouriteButton(project: project)),
                    ),
                  ),
                  const SizedBox(width: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdeMenuEntry extends StatelessWidget {
  const _IdeMenuEntry({required this.ide, required this.label});

  final Ide ide;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image(image: AssetImage(ide.iconAsset), width: 16, height: 16),
        const SizedBox(width: 8),
        Text(label),
      ],
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

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.project});

  // Matches storage.screen.dart's _actionsColumnWidth.
  static const size = 40.0;

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    // CircleIconButton hardcodes zero padding now, so without an explicit
    // size here the button would shrink to its icon's own bounds instead of
    // the tap target this column's width (see the header's SizedBox using
    // this same `size`) assumes it fills.
    return SizedBox(
      width: size,
      height: size,
      child: CircleIconButton(
        backgroundColor: Colors.transparent,
        color: project.favourite ? Colors.amber : null,
        tooltip:
            project.favourite ? 'Remove from favourites' : 'Add to favourites',
        onPressed: () => context.read<ExplorerStore>().toggleFavourite(project),
        icon: Icon(
          project.favourite ? CupertinoIcons.star_fill : CupertinoIcons.star,
          size: _favouriteIconSize,
        ),
      ),
    );
  }
}
