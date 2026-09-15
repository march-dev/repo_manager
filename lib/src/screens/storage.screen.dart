import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

const _iconGap = 16.0;
const _columnGap = 12.0;
const _actionsColumnWidth = 40.0;
const _projectIconSize = 40.0;

// StorageStore is provided above this screen (see _RootScaffold) rather
// than here, so DashboardScreen — a sibling, not a descendant — can read
// the same live size data for its own reclaimable-storage stat instead of
// duplicating ProjectRepo's filesystem scan/size walk in a second store.
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
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _StorageHeader(),
            // Wraps the table so any row's right-click menu has somewhere
            // to open into — see showProjectContextMenu.
            Expanded(
              child: ProjectContextMenuRegion(child: _ProjectTable()),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageHeader extends StatelessObserverWidget {
  const _StorageHeader();

  @override
  Widget build(BuildContext context) {
    final store = context.read<StorageStore>();
    final colorScheme = Theme.of(context).colorScheme;
    final total = store.totalBytes;
    final core = store.coreBytes;
    final cache = store.cacheBytes;

    return HeaderCard(
      title: 'Projects Storage',
      actions: [
        Text(
          'Total: ${formatBytes(total)}',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        _RefreshButton(
          refreshing: store.isRefreshing,
          onPressed: store.refreshAll,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizeBar(
            coreBytes: core,
            cacheBytes: cache,
            totalBytes: total,
            height: 14,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizeSummary(
                label: 'Core',
                bytes: core,
                color: ProjectSizeType.core.color,
              ),
              const SizedBox(width: 16),
              SizeSummary(
                label: 'Cache',
                bytes: cache,
                color: ProjectSizeType.cache.color,
              ),
              const Spacer(),
              if (cache > 0)
                _CleanAllButton(
                  cleaning: store.cleaningAll,
                  // Sizes mid-recompute means the cache/core split shown
                  // right now may already be stale, and cleaning would race
                  // the refresh's own filesystem walk — block it until that
                  // settles.
                  disabled: store.isRefreshing,
                  onPressed: store.cleanupAll,
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
    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
        ),
      ),
      child: IconButton(
        onPressed: widget.refreshing ? null : widget.onPressed,
        tooltip: 'Refresh projects',
        visualDensity: VisualDensity.compact,
        icon: RotationTransition(
          turns: _controller,
          // CupertinoIcons.refresh is two chasing arrows, which reads oddly
          // mid-spin — a single clockwise arrow is the shape actually meant
          // to be animated this way.
          child: const Icon(Icons.refresh_rounded, size: 20),
        ),
      ),
    );
  }
}

class _CleanAllButton extends StatelessWidget {
  const _CleanAllButton({
    required this.cleaning,
    required this.onPressed,
    this.disabled = false,
  });

  final bool cleaning;
  final VoidCallback onPressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: (cleaning || disabled) ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: ProjectSizeType.cache.color,
        foregroundColor: Colors.black,
        disabledBackgroundColor:
            ProjectSizeType.cache.color.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.black.withValues(alpha: 0.6),
      ),
      icon: cleaning
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(CupertinoIcons.trash, size: 18),
      label: const Text('Clean All'),
    );
  }
}

const _columns = [
  FlexColumn(flex: 3),
  DividerColumn(),
  FlexColumn(flex: 2),
  DividerColumn(),
  FixedColumn(_actionsColumnWidth + _columnGap * 2),
];

class _ProjectTable extends StatelessObserverWidget {
  const _ProjectTable();

  List<AppTableHeaderCell> _headerBuilder(
    BuildContext context,
    StorageStore store,
  ) {
    return [
      HeaderSortableButton(
        text: 'Name',
        ascending:
            store.sortBy == ProjectSortBy.name ? store.sortAscending : null,
        onChanged: (_) => store.setSortBy(ProjectSortBy.name),
        padding: const EdgeInsets.only(left: _projectIconSize + _iconGap * 2),
      ),
      HeaderSortableButton(
        text: 'Size',
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
    ProjectItemStore item,
    StorageStore store,
  ) {
    return [
      Row(
        children: [
          const SizedBox(width: _iconGap),
          ProjectIcon(iconPath: item.project.iconPath),
          const SizedBox(width: _iconGap),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.project.name, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProjectLanguageBadge(
                      language: item.project.language,
                      framework: item.project.framework,
                    ),
                    // Wrapped in its own Observer — this row is built by
                    // AppTable's lazy ListView.builder, outside the Observer
                    // scope that wraps _ProjectTable.build() itself, so
                    // item.project (updated once its monorepo tree finishes
                    // loading in the background) wouldn't otherwise trigger
                    // a rebuild here on its own.
                    Observer(
                      builder: (context) {
                        final monorepoTool = item.project.monorepoTool;
                        if (monorepoTool == null) {
                          return const SizedBox.shrink();
                        }

                        // Storage doesn't expand a monorepo's member
                        // packages the way Explorer does — its size figure
                        // and bar cover the whole workspace as one folder —
                        // so this badge is purely informational here: a
                        // reminder that the number shown isn't just one
                        // package's own footprint.
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: MonorepoBadge(
                            tool: monorepoTool,
                            count: item.project.subPackagesLoaded
                                ? item.project.subPackages.projectCount
                                : null,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: _columnGap),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ProjectSizeBar(
            item: item,
            maxTotalBytes: store.maxProjectTotalBytes,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: _columnGap),
        child: Center(
          // rowBuilder runs inside AppTable's own lazily-built row widget,
          // outside the Observer scope that wraps _ProjectTable.build() —
          // without its own Observer here, item.cleaning/store.isRefreshing/
          // store.cleaningAll wouldn't trigger a rebuild on their own, only
          // whenever something else (e.g. a hover) happened to rebuild this
          // row, which read as a laggy delay before the button disabled.
          child: Observer(
            builder: (context) => _ProjectCleanupButton(
              onPressed: item.cleanup,
              cleaning: item.cleaning,
              disabled: store.cleaningAll || store.isRefreshing,
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<StorageStore>();

    return AppTable<ProjectItemStore, Never>(
      columns: _columns,
      headerBuilder: (context) => _headerBuilder(context, store),
      rowBuilder: (context, item, isHovered) =>
          _rowBuilder(context, item, store),
      items: store.sortedItems,
      onRowSecondaryTapUp: (context, item, position) =>
          showProjectContextMenu(context, item.project, position),
      rowKey: (item) => ValueKey(item.project.path),
      emptyMessage: 'No projects found. Add a directory in Settings.',
    );
  }
}

class _ProjectCleanupButton extends StatelessWidget {
  const _ProjectCleanupButton({
    required this.onPressed,
    required this.cleaning,
    this.disabled = false,
  });

  final VoidCallback onPressed;
  final bool cleaning;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    // CircleIconButton hardcodes zero padding now, so without an explicit
    // size here the button would just shrink to its icon's own bounds
    // instead of filling this reserved _actionsColumnWidth-wide slot.
    return SizedBox(
      width: _actionsColumnWidth,
      height: _actionsColumnWidth,
      child: CircleIconButton(
        onPressed: (cleaning || disabled) ? null : onPressed,
        backgroundColor: ProjectSizeType.cache.color,
        color: Colors.black,
        tooltip: 'Cleanup the project',
        icon: cleaning
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                CupertinoIcons.trash,
                size: 20,
              ),
      ),
    );
  }
}
