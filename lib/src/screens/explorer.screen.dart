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

// Row layout constants, shared between _ProjectTable's cells and header so
// the "Name" label and sort control line up with the icon/name column of
// each row below it. Matches storage.screen.dart's own icon size/gap so
// both screens' rows look identical; row height and scrollbar gutter are
// AppTable's own matching defaults, so this screen doesn't need to repeat
// them.
const _rowPadding = 16.0;
const _rowIconSize = 40.0;
const _favouriteIconSize = 20.0;
// Matches storage.screen.dart's _columnGap, used the same way: padding
// around the trailing icon-button column.
const _columnGap = 12.0;

// A folder-path section's display data: the full path (shown in a
// tooltip) and the common-prefix-stripped path actually printed in the
// section header.
typedef _DirSection = ({String fullPath, String displayPath});

class _Scaffold extends StatelessWidget {
  const _Scaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ExplorerToolbar(),
            Expanded(child: _ProjectTable()),
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

const _columns = [
  FlexColumn(),
  DividerColumn(),
  FixedColumn(_FavouriteButton.size + _columnGap * 2),
];

class _ProjectTable extends StatelessObserverWidget {
  const _ProjectTable();

  List<AppTableHeaderCell> _headerBuilder(
    BuildContext context,
    ExplorerStore store,
  ) {
    return [
      HeaderSortableButton(
        text: 'Name',
        ascending: store.sortAscending,
        onChanged: (_) => store.toggleNameSort(),
        padding: const EdgeInsets.only(left: _rowIconSize + _rowPadding * 2),
      ),
      _PinToggleButton(store: store),
    ];
  }

  List<Widget> _rowBuilder(
    BuildContext context,
    ProjectModel project,
    bool isHovered,
  ) {
    return [
      Row(
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
                      Text(project.name, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      ProjectLanguageBadge(
                        language: project.language,
                        framework: project.framework,
                      ),
                    ],
                  ),
                ),
                // Replaces a plain hover tooltip with the same "Open in
                // <IDE>" text shown inline, at the end of the name
                // section, only while the row is hovered.
                if (isHovered) ...[
                  const SizedBox(width: _rowPadding),
                  _OpenInHint(ide: ProjectRepo().resolveIde(project)),
                  const SizedBox(width: _rowPadding),
                ],
              ],
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: _columnGap),
        child: Center(child: _FavouriteButton(project: project)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();

    if (store.grouping == ExplorerGrouping.byFolder) {
      final entries = store.groupedProjects.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final commonPrefix =
          commonDirPrefix(entries.map((entry) => entry.key).toList());

      return AppTable<ProjectModel, _DirSection>.sectioned(
        columns: _columns,
        headerBuilder: (context) => _headerBuilder(context, store),
        rowBuilder: _rowBuilder,
        sections: [
          for (final entry in entries)
            AppTableSection(
              section: (
                fullPath: entry.key,
                displayPath: stripCommonPrefix(entry.key, commonPrefix),
              ),
              items: entry.value,
            ),
        ],
        sectionBuilder: (context, section) => _DirSectionHeader(
          fullPath: section.fullPath,
          displayPath: section.displayPath,
        ),
        onRowTap: store.openProject,
        onRowSecondaryTapUp: _showProjectContextMenu,
        rowKey: (project) => ValueKey(project.path),
        emptyMessage: 'No projects found. Add a directory in Settings.',
      );
    }

    return AppTable<ProjectModel, Never>(
      columns: _columns,
      headerBuilder: (context) => _headerBuilder(context, store),
      rowBuilder: _rowBuilder,
      items: store.visibleProjects,
      onRowTap: store.openProject,
      onRowSecondaryTapUp: _showProjectContextMenu,
      rowKey: (project) => ValueKey(project.path),
      emptyMessage: 'No projects found. Add a directory in Settings.',
    );
  }
}

Future<void> _showProjectContextMenu(
  BuildContext context,
  ProjectModel project,
  Offset globalPosition,
) async {
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

class _PinToggleButton extends AppTableHeaderCell {
  const _PinToggleButton({required this.store});

  final ExplorerStore store;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // An InkWell rather than an IconButton, matching HeaderSortableButton
    // next to it instead of looking like a stray action button — the icon
    // is sized to sit next to that header's own 11px label/12px sort arrow
    // instead of a full IconButton's much larger default tap target.
    return ClipRect(
      child: Tooltip(
        message:
            store.pinFavourites ? 'Favourites pinned to top' : 'No pinning',
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
      height: AppTable.defaultSectionGap,
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
    // the tap target this column's width (see the header's FixedColumn
    // using this same `size`) assumes it fills.
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
