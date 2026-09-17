import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

// StorageState is provided above this screen (see _RootScaffold) rather
// than here, so DashboardScreen — a sibling, not a descendant — can read
// the same live size data for its own reclaimable-storage stat instead of
// duplicating ProjectScanner's filesystem scan/ProjectSizeRepo's size walk
// in a second store.
class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Scaffold();
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold();

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      body: Column(
        children: [
          _StorageHeader(),
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
        _RefreshButton(
          refreshing: store.isRefreshing,
          onPressed: store.refreshAll,
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

// Spins the refresh icon continuously while a size recalculation is in
// progress (whether triggered by tapping this button or by the silent
// background refresh after launch) and disables taps for the duration,
// rather than swapping the icon for a separate progress indicator.
class _RefreshButton extends StatefulWidget {
  const _RefreshButton({required this.refreshing, required this.onPressed});

  final bool refreshing;
  final VoidCallback onPressed;

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void initState() {
    super.initState();
    if (widget.refreshing) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _RefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshing == oldWidget.refreshing) return;
    if (widget.refreshing) {
      _controller.repeat();
    } else {
      // Snaps back to the upright icon rather than freezing mid-spin.
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      onPressed: widget.refreshing ? null : widget.onPressed,
      backgroundColor: Colors.transparent,
      tooltip: AppLocalizations.of(context)!.storageRefreshTooltip,
      icon: RotationTransition(
        turns: _controller,
        // CupertinoIcons.refresh is two chasing arrows, which reads oddly
        // mid-spin — a single clockwise arrow is the shape actually meant
        // to be animated this way.
        child: const Icon(Icons.refresh_rounded, size: AppSizes.iconLarge),
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
      // informational (no onMonorepoBadgeTap), a reminder that the number
      // shown isn't just one package's own footprint.
      Observer(
        builder: (context) => ProjectRow(
          project: item.project,
          iconSize: AppSizes.rowIconSize,
          gap: AppSizes.spacing16,
          leadingGap: AppSizes.spacing16,
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
