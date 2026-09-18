import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

// StorageState is provided above this screen (see _RootScaffold) rather
// than here, so DashboardScreen — a sibling, not a descendant — can read
// the same live size data for its own reclaimable-storage stat instead of
// duplicating ProjectScanner's filesystem scan/ProjectSizeRepo's size walk
// in a second store.
class StorageScreen extends StatelessWidget {
  // _RootScaffold keeps every screen mounted at once (an IndexedStack, not
  // a Navigator swap — see its own doc), so a plain `autofocus: true`
  // here would compete with every other IndexedStack sibling for focus
  // the moment the app launches, regardless of which tab is actually
  // visible. [selected] — whether this is the currently-visible tab, from
  // _RootScaffold's own _selectedIndex — lets _Scaffold claim/release
  // focus only when it's actually true, so F5 refreshes this screen only
  // while looking at it.
  const StorageScreen({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _Scaffold(selected: selected);
  }
}

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
            context.read<StorageState>().refreshAll(),
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
              _StorageHeader(),
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

class _StorageHeader extends StatelessObserverWidget {
  const _StorageHeader();

  @override
  Widget build(BuildContext context) {
    final store = context.read<StorageState>();
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final total = store.totalBytes;
    final core = store.coreBytes;
    final cache = store.cacheBytes;

    return HeaderCard(
      title: l10n.storageTitle,
      actions: [
        Text(
          l10n.storageTotalLabel(formatBytes(total)),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(width: AppSizes.spacing8),
        RefreshIconButton(
          refreshing: store.isRefreshing,
          onPressed: store.refreshAll,
          tooltip: l10n.storageRefreshTooltip,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizeBar(
            leftValue: core,
            rightValue: cache,
            totalValue: total,
            leftColor: ProjectSizeType.core.color,
            rightColor: ProjectSizeType.cache.color,
            height: 14,
          ),
          const SizedBox(height: AppSizes.spacing12),
          Row(
            children: [
              SizeSummary(
                label: l10n.storageCoreLabel,
                bytes: core,
                color: ProjectSizeType.core.color,
              ),
              const SizedBox(width: AppSizes.spacing16),
              SizeSummary(
                label: l10n.storageCacheLabel,
                bytes: cache,
                color: ProjectSizeType.cache.color,
              ),
              const Spacer(),
              if (cache > 0)
                PrimaryButton(
                  loading: store.cleaningAll,
                  // Sizes mid-recompute means the cache/core split shown
                  // right now may already be stale, and cleaning would race
                  // the refresh's own filesystem walk — block it until that
                  // settles.
                  disabled: store.isRefreshing,
                  onPressed: store.cleanupAll,
                  backgroundColor: ProjectSizeType.cache.color,
                  foregroundColor: Colors.black,
                  icon: const Icon(CupertinoIcons.trash,
                      size: AppSizes.iconMedium),
                  label: Text(l10n.storageCleanAllButton),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

const _columns = [
  FlexColumn(flex: 3),
  DividerColumn(),
  FlexColumn(flex: 2),
  DividerColumn(),
  FixedColumn(AppSizes.actionColumnSize + AppSizes.spacing12 * 2),
];

class _ProjectTable extends StatelessObserverWidget {
  const _ProjectTable();

  List<AppTableHeaderCell> _headerBuilder(
    BuildContext context,
    StorageState store,
  ) {
    return [
      HeaderSortableButton(
        text: AppLocalizations.of(context)!.nameColumnHeader,
        ascending:
            store.sortBy == ProjectSortBy.name ? store.sortAscending : null,
        onChanged: (_) => store.setSortBy(ProjectSortBy.name),
        padding: const EdgeInsets.only(
            left: AppSizes.rowIconSize + AppSizes.spacing16 * 2),
      ),
      HeaderSortableButton(
        text: AppLocalizations.of(context)!.sizeColumnHeader,
        ascending:
            store.sortBy == ProjectSortBy.size ? store.sortAscending : null,
        onChanged: (_) => store.setSortBy(ProjectSortBy.size),
        alignment: Alignment.center,
      ),
      const HeaderEmpty(),
    ];
  }

  List<Widget> _rowBuilder(
    BuildContext context,
    ProjectItemState item,
    StorageState store,
  ) {
    return [
      // item.project is @observable (StorageState fills in a monorepo's
      // member-package tree in the background once it's known — see
      // ProjectItemState.updateProject) — and sortedItems only depends on
      // it while sorted by name, not by size (its comparator never reads
      // .project in that branch). rowBuilder also runs inside AppTable's
      // own lazily-built row widget, outside the Observer scope that
      // wraps _ProjectTable.build(). Without its own Observer here, a
      // background-loaded package count could sit stale indefinitely
      // while sorted by size.
      //
      // Storage doesn't expand a monorepo's member packages the way
      // Explorer does — its size figure and bar cover the whole workspace
      // as one folder — so the default monorepo badge here is purely
      // informational (no onMonorepoBadgeTap) and skips the package
      // count too (showMonorepoPackageCount: false) — just naming the
      // tool, since there's nothing on this row a count would let you
      // act on, and it's one less thing competing for space alongside
      // the size bar/language badge on this line.
      Observer(
        builder: (context) => ProjectRow(
          project: item.project,
          iconSize: AppSizes.rowIconSize,
          gap: AppSizes.spacing16,
          leadingGap: AppSizes.spacing16,
          showMonorepoPackageCount: false,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ProjectSizeBar(
            item: item,
            maxTotalBytes: store.maxProjectTotalBytes,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing12),
        child: Center(
          // rowBuilder runs inside AppTable's own lazily-built row widget,
          // outside the Observer scope that wraps _ProjectTable.build() —
          // without its own Observer here, item.cleaning/store.isRefreshing/
          // store.cleaningAll wouldn't trigger a rebuild on their own, only
          // whenever something else (e.g. a hover) happened to rebuild this
          // row, which read as a laggy delay before the button disabled.
          child: Observer(
            builder: (context) => CircleIconButton.loading(
              // Fills this reserved action-column-wide slot.
              size: AppSizes.actionColumnSize,
              onPressed: (store.cleaningAll || store.isRefreshing)
                  ? null
                  : item.cleanup,
              loading: item.cleaning,
              backgroundColor: ProjectSizeType.cache.color,
              color: Colors.black,
              tooltip:
                  AppLocalizations.of(context)!.storageCleanupProjectTooltip,
              icon: const Icon(CupertinoIcons.trash, size: AppSizes.iconLarge),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<StorageState>();
    final collectionsState = context.read<CollectionsState>();
    final actions = context.read<ProjectActionsState>();

    return AppTable<ProjectItemState, Never>(
      columns: _columns,
      headerBuilder: (context) => _headerBuilder(context, store),
      rowBuilder: (context, item, isHovered) =>
          _rowBuilder(context, item, store),
      items: store.sortedItems,
      onRowSecondaryTapUp: (context, item, position) => showProjectContextMenu(
        context,
        item.project,
        position,
        collectionsState: collectionsState,
        actions: actions,
      ),
      rowKey: (item) => ValueKey(item.project.path),
      emptyMessage: AppLocalizations.of(context)!.noProjectsFoundMessage,
    );
  }
}
