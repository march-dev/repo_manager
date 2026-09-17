import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

// ExplorerState is provided above this screen (see _RootScaffold) rather
// than here, so DashboardScreen — a sibling, not a descendant — can read
// the same live project list/favourites for its own quick-launch section
// instead of duplicating ProjectScanner's filesystem scan in a second store.
class ExplorerScreen extends StatelessWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Scaffold();
  }
}

// Row layout, shared between _ProjectTable's cells and header so the
// "Name" label and sort control line up with the icon/name column of each
// row below it — all sourced from AppSizes so this screen and
// storage.screen.dart's own row layout always agree; row height and
// scrollbar gutter are AppTable's own matching defaults, so this screen
// doesn't need to repeat them either.

// A folder-path section's display data: the full path (shown in a
// tooltip) and the common-prefix-stripped path actually printed in the
// section header.
typedef _DirSection = ({String fullPath, String displayPath, int count});

// name is the raw collection name (or uncategorizedCollectionKey's empty
// string) — kept separate from its display text so the section builder
// can tell a real collection apart from the sentinel and only offer
// rename/delete for the former.
typedef _CollectionSection = ({String name, int count});

class _Scaffold extends StatelessWidget {
  const _Scaffold();

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      body: Column(
        children: [
          _ExplorerToolbar(),
          // Wraps the table so any row's right-click menu has somewhere
          // to open into — see showProjectContextMenu.
          Expanded(
            child: ContextMenuRegion(child: _ProjectTable()),
          ),
        ],
      ),
    );
  }
}

class _ExplorerToolbar extends StatelessObserverWidget {
  const _ExplorerToolbar();

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerState>();
    final l10n = AppLocalizations.of(context)!;

    return HeaderCard(
      title: l10n.explorerTitle,
      actions: [
        SearchField(
          value: store.searchQuery,
          onChanged: store.setSearchQuery,
          hintText: l10n.explorerSearchHint,
        ),
        const SizedBox(width: AppSizes.spacing12),
        AppSegmentedButton<ExplorerGrouping>(
          selected: store.grouping,
          onChanged: store.setGrouping,
          segments: [
            ButtonSegment(
              value: ExplorerGrouping.none,
              label: Text(l10n.explorerGroupingNone),
              icon: const Icon(CupertinoIcons.square_stack),
            ),
            ButtonSegment(
              value: ExplorerGrouping.byFolder,
              label: Text(l10n.explorerGroupingByFolder),
              icon: const Icon(CupertinoIcons.folder),
            ),
            ButtonSegment(
              value: ExplorerGrouping.byCollection,
              label: Text(l10n.explorerGroupingByCollection),
              icon: const Icon(CupertinoIcons.square_stack_3d_up),
            ),
          ],
        ),
      ],
    );
  }
}

const _columns = [
  FlexColumn(),
  DividerColumn(),
  FixedColumn(AppSizes.actionColumnSize + AppSizes.spacing12 * 2),
];

List<AppTableHeaderCell> _headerBuilder(
  BuildContext context,
  ExplorerState store,
) {
  return [
    HeaderSortableButton(
      text: AppLocalizations.of(context)!.nameColumnHeader,
      ascending: store.sortAscending,
      onChanged: (_) => store.toggleNameSort(),
      padding: const EdgeInsets.only(
          left: AppSizes.rowIconSize + AppSizes.spacing16 * 2),
    ),
    PinFavouritesToggleButton(
      pinned: store.pinFavourites,
      onToggle: store.togglePinFavourites,
    ),
  ];
}

List<Widget> _rowBuilder(
  BuildContext context,
  ProjectModel project,
  bool isHovered, {
  required ExplorerState explorerState,
  required CollectionsState collectionsState,
  required ProjectActionsState actions,
}) {
  return [
    ProjectRow(
      project: project,
      iconSize: AppSizes.rowIconSize,
      gap: AppSizes.spacing16,
      leadingGap: AppSizes.spacing16,
      // Tapping the monorepo badge opens the member-package tree in its
      // own dialog, rather than the row growing an always-visible
      // expand/collapse UI.
      onMonorepoBadgeTap: () => showProjectDetailsDialog(
        context,
        project,
        collectionsState: collectionsState,
        actions: actions,
      ),
      // Replaces a plain hover tooltip with the same "Open in <IDE>" text
      // shown inline, at the end of the name section, only while the row
      // is hovered.
      trailing: isHovered ? OpenInHint(ide: actions.resolveIde(project)) : null,
    ),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing12),
      child: Center(
        child: ProjectFavouriteButton(
          project: project,
          size: AppSizes.actionColumnSize,
          onPressed: () => explorerState.toggleFavourite(project),
        ),
      ),
    ),
  ];
}

class _ProjectTable extends StatelessObserverWidget {
  const _ProjectTable();

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerState>();
    final collectionsState = context.read<CollectionsState>();
    final actions = context.read<ProjectActionsState>();

    return switch (store.grouping) {
      ExplorerGrouping.byFolder => _FolderGroupedTable(
          store: store,
          collectionsState: collectionsState,
          actions: actions,
        ),
      ExplorerGrouping.byCollection => _CollectionGroupedTable(
          store: store,
          collectionsState: collectionsState,
          actions: actions,
        ),
      ExplorerGrouping.none => _PlainProjectTable(
          store: store,
          collectionsState: collectionsState,
          actions: actions,
        ),
    };
  }
}

class _FolderGroupedTable extends StatelessObserverWidget {
  const _FolderGroupedTable({
    required this.store,
    required this.collectionsState,
    required this.actions,
  });

  final ExplorerState store;
  final CollectionsState collectionsState;
  final ProjectActionsState actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = store.groupedProjects.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final commonPrefix =
        commonDirPrefix(entries.map((entry) => entry.key).toList());

    return AppTable<ProjectModel, _DirSection>.sectioned(
      columns: _columns,
      headerBuilder: (context) => _headerBuilder(context, store),
      rowBuilder: (context, project, isHovered) => _rowBuilder(
        context,
        project,
        isHovered,
        explorerState: store,
        collectionsState: collectionsState,
        actions: actions,
      ),
      sections: [
        for (final entry in entries)
          AppTableSection(
            section: (
              fullPath: entry.key,
              displayPath: stripCommonPrefix(entry.key, commonPrefix),
              count: entry.value.length,
            ),
            items: entry.value,
          ),
      ],
      sectionBuilder: (context, section) => TintedSectionHeader(
        icon: CupertinoIcons.folder_fill,
        text: section.displayPath,
        tooltip: section.fullPath,
        count: section.count,
        height: AppTable.defaultSectionGap,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
      ),
      onRowTap: store.openProject,
      onRowDoubleTap: (project) => showProjectDetailsDialog(
        context,
        project,
        collectionsState: collectionsState,
        actions: actions,
      ),
      onRowSecondaryTapUp: (context, project, position) =>
          showProjectContextMenu(
        context,
        project,
        position,
        collectionsState: collectionsState,
        actions: actions,
      ),
      rowKey: (project) => ValueKey(project.path),
      emptyMessage: l10n.noProjectsFoundMessage,
    );
  }
}

class _CollectionGroupedTable extends StatelessObserverWidget {
  const _CollectionGroupedTable({
    required this.store,
    required this.collectionsState,
    required this.actions,
  });

  final ExplorerState store;
  final CollectionsState collectionsState;
  final ProjectActionsState actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = store.groupedByCollection.entries.toList()
      ..sort((a, b) {
        // Uncategorized always trails, regardless of alphabetical order.
        if (a.key.isEmpty != b.key.isEmpty) return a.key.isEmpty ? 1 : -1;
        return a.key.compareTo(b.key);
      });

    return AppTable<ProjectModel, _CollectionSection>.sectioned(
      columns: _columns,
      headerBuilder: (context) => _headerBuilder(context, store),
      rowBuilder: (context, project, isHovered) => _rowBuilder(
        context,
        project,
        isHovered,
        explorerState: store,
        collectionsState: collectionsState,
        actions: actions,
      ),
      sections: [
        for (final entry in entries)
          AppTableSection(
            section: (name: entry.key, count: entry.value.length),
            items: entry.value,
          ),
      ],
      sectionBuilder: (context, section) {
        final header = TintedSectionHeader(
          icon: CupertinoIcons.square_stack_3d_up_fill,
          text: section.name.isEmpty
              ? l10n.explorerUncategorizedCollection
              : section.name,
          count: section.count,
          height: AppTable.defaultSectionGap,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
        );
        if (section.name.isEmpty) return header;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapUp: (details) => showCollectionContextMenu(
            context,
            section.name,
            details.globalPosition,
            collectionsState: collectionsState,
          ),
          child: header,
        );
      },
      onRowTap: store.openProject,
      onRowDoubleTap: (project) => showProjectDetailsDialog(
        context,
        project,
        collectionsState: collectionsState,
        actions: actions,
      ),
      onRowSecondaryTapUp: (context, project, position) =>
          showProjectContextMenu(
        context,
        project,
        position,
        collectionsState: collectionsState,
        actions: actions,
      ),
      rowKey: (project) => ValueKey(project.path),
      emptyMessage: l10n.noProjectsFoundMessage,
    );
  }
}

class _PlainProjectTable extends StatelessObserverWidget {
  const _PlainProjectTable({
    required this.store,
    required this.collectionsState,
    required this.actions,
  });

  final ExplorerState store;
  final CollectionsState collectionsState;
  final ProjectActionsState actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppTable<ProjectModel, Never>(
      columns: _columns,
      headerBuilder: (context) => _headerBuilder(context, store),
      rowBuilder: (context, project, isHovered) => _rowBuilder(
        context,
        project,
        isHovered,
        explorerState: store,
        collectionsState: collectionsState,
        actions: actions,
      ),
      items: store.visibleProjects,
      onRowTap: store.openProject,
      onRowDoubleTap: (project) => showProjectDetailsDialog(
        context,
        project,
        collectionsState: collectionsState,
        actions: actions,
      ),
      onRowSecondaryTapUp: (context, project, position) =>
          showProjectContextMenu(
        context,
        project,
        position,
        collectionsState: collectionsState,
        actions: actions,
      ),
      rowKey: (project) => ValueKey(project.path),
      emptyMessage: l10n.noProjectsFoundMessage,
    );
  }
}
