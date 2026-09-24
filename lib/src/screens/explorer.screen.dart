import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

// ExplorerState is provided above this screen (see _RootScaffold) rather
// than here, so DashboardScreen — a sibling, not a descendant — can read
// the same live project list/favourites for its own quick-launch section
// instead of duplicating ProjectScanner's filesystem scan in a second store.
class ExplorerScreen extends StatelessWidget {
  // _RootScaffold keeps every screen mounted at once (an IndexedStack, not
  // a Navigator swap — see its own doc), so a plain `autofocus: true`
  // here would compete with every other IndexedStack sibling for focus
  // the moment the app launches, regardless of which tab is actually
  // visible. [selected] — whether this is the currently-visible tab, from
  // _RootScaffold's own _selectedIndex — lets _Scaffold claim/release
  // focus only when it's actually true, so F5 refreshes this screen only
  // while looking at it.
  const ExplorerScreen({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _Scaffold(selected: selected);
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

class _Scaffold extends StatefulWidget {
  const _Scaffold({required this.selected});

  final bool selected;

  @override
  State<_Scaffold> createState() => _ScaffoldState();
}

class _ScaffoldState extends State<_Scaffold> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.selected) _focusNode.requestFocus();
  }

  @override
  void didUpdateWidget(_Scaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _focusNode.requestFocus();
    } else if (!widget.selected && oldWidget.selected) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.f5): () =>
            context.read<ExplorerState>().refreshAll(),
      },
      // CallbackShortcuts only intercepts key events reaching a focused
      // descendant — this Focus's own requestFocus()/unfocus() calls
      // above are what keep that descendant correct as the tab is
      // switched to/away from, rather than a one-shot autofocus.
      child: Focus(
        focusNode: _focusNode,
        child: const AppScaffold(
          body: Column(
            children: [
              _ExplorerToolbar(),
              // Wraps the table so any row's right-click menu has
              // somewhere to open into — see showProjectContextMenu.
              Expanded(
                child: ContextMenuRegion(child: _ProjectTable()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Below this available width, the title/search/grouping toggle/refresh
// button no longer comfortably fit on one line together — an estimate
// for this screen's own current content, not a shared design token.
// Bumped by ~50 (spacing12 + the refresh button's own ~36px width) from
// this row's pre-refresh-button value to keep making room for it.
const _headerBreakpoint = 640.0;

// A second, slightly wider breakpoint just for the grouping toggle's own
// labels — the one-row layout has room for search plus an icon-only
// toggle (and the refresh button) from _headerBreakpoint alone, but not
// enough for full labels on each of its 3 segments until a bit wider
// still.
const _groupingLabelBreakpoint = 850.0;

class _ExplorerToolbar extends StatelessObserverWidget {
  const _ExplorerToolbar();

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerState>();
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      // LayoutBuilder defers calling this builder to layout time rather
      // than invoking it inline during _ExplorerToolbar's own build() —
      // so store.grouping/store.searchQuery, read only in here, fall
      // outside StatelessObserverWidget's tracked scope. Without this
      // nested Observer, toggling grouping (or typing a search query)
      // updates the store fine but never rebuilds this closure; only a
      // hot reload's forced reassemble() happens to show the change.
      builder: (context, constraints) => Observer(
        builder: (context) {
          final oneRow = constraints.maxWidth >= _headerBreakpoint;
          final showGroupingLabels =
              constraints.maxWidth >= _groupingLabelBreakpoint;

          // Full labels once there's room for them (see
          // _groupingLabelBreakpoint); icon-only otherwise, with the label
          // moved to a hover tooltip instead.
          final groupingButton = AppSegmentedButton<ExplorerGrouping>(
            selected: store.grouping,
            onChanged: store.setGrouping,
            segments: [
              ButtonSegment(
                value: ExplorerGrouping.none,
                icon: const Icon(CupertinoIcons.square_stack),
                label:
                    showGroupingLabels ? Text(l10n.explorerGroupingNone) : null,
                tooltip: showGroupingLabels ? null : l10n.explorerGroupingNone,
              ),
              ButtonSegment(
                value: ExplorerGrouping.byFolder,
                icon: const Icon(CupertinoIcons.folder),
                label: showGroupingLabels
                    ? Text(l10n.explorerGroupingByFolder)
                    : null,
                tooltip:
                    showGroupingLabels ? null : l10n.explorerGroupingByFolder,
              ),
              ButtonSegment(
                value: ExplorerGrouping.byCollection,
                icon: const Icon(CupertinoIcons.square_stack_3d_up),
                label: showGroupingLabels
                    ? Text(l10n.explorerGroupingByCollection)
                    : null,
                tooltip: showGroupingLabels
                    ? null
                    : l10n.explorerGroupingByCollection,
              ),
            ],
          );

          return HeaderCard(
            title: l10n.explorerTitle,
            actions: [
              // Enough room for the title row to hold everything — search
              // sits inline, at its own compact width, right before the
              // grouping toggle.
              if (oneRow) ...[
                SearchField(
                  value: store.searchQuery,
                  onChanged: store.setSearchQuery,
                  hintText: l10n.explorerSearchHint,
                ),
                const SizedBox(width: AppSizes.spacing12),
              ],
              groupingButton,
              const SizedBox(width: AppSizes.spacing12),
              RefreshIconButton(
                refreshing: store.isRefreshing,
                onPressed: store.refreshAll,
                tooltip: l10n.explorerRefreshTooltip,
              ),
            ],
            // Not enough room — search drops to its own full-width row
            // below the title instead of competing with the grouping
            // toggle for space in the title row itself.
            child: oneRow
                ? null
                : SearchField(
                    value: store.searchQuery,
                    onChanged: store.setSearchQuery,
                    hintText: l10n.explorerSearchHint,
                    width: double.infinity,
                  ),
          );
        },
      ),
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
      onRowDoubleTap: (project) => showProjectDetailsPage(
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
      onRowDoubleTap: (project) => showProjectDetailsPage(
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
      onRowDoubleTap: (project) => showProjectDetailsPage(
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
