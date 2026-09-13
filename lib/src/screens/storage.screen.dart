import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

const _iconGap = 16.0;
const _columnGap = 12.0;
const _actionsColumnWidth = 40.0;
const _projectIconSize = 40.0;
// Reserved so TableCard's always-visible scrollbar has its own lane instead
// of floating as an overlay on top of the last column — without it, the
// thumb sits on top of the button's own right-hand gap, making that gap
// look uneven next to the others.
const _scrollbarGutter = 12.0;

class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<StorageStore>(
      create: (_) => StorageStore(),
      child: const _Scaffold(),
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _StorageHeader(),
            Expanded(
              child: TableCard(
                header: const _TableHeader(),
                bodyBuilder: (context, scrollController) =>
                    _ProjectList(scrollController: scrollController),
              ),
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
  const _CleanAllButton({required this.cleaning, required this.onPressed});

  final bool cleaning;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: cleaning ? null : onPressed,
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

class _TableHeader extends StatelessObserverWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final store = context.read<StorageStore>();
    final colorScheme = Theme.of(context).colorScheme;

    return TableHeaderRow(
      children: [
        Expanded(
          flex: 3,
          child: SortableColumnHeader(
            label: 'Name',
            active: store.sortBy == ProjectSortBy.name,
            ascending: store.sortAscending,
            onTap: () => store.setSortBy(ProjectSortBy.name),
            padding: const EdgeInsets.only(
              left: _projectIconSize + _iconGap * 2,
            ),
          ),
        ),
        VerticalDivider(
            width: 1, thickness: 1, color: colorScheme.outlineVariant),
        Expanded(
          flex: 2,
          child: SortableColumnHeader(
            label: 'Size',
            active: store.sortBy == ProjectSortBy.size,
            ascending: store.sortAscending,
            onTap: () => store.setSortBy(ProjectSortBy.size),
            alignment: Alignment.center,
          ),
        ),
        VerticalDivider(
            width: 1, thickness: 1, color: colorScheme.outlineVariant),
        const SizedBox(width: _actionsColumnWidth + _columnGap * 2),
        VerticalDivider(
            width: 1, thickness: 1, color: colorScheme.outlineVariant),
        const SizedBox(width: _scrollbarGutter),
      ],
    );
  }
}

class _ProjectList extends StatelessObserverWidget {
  const _ProjectList({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final store = context.read<StorageStore>();
    final items = store.sortedItems;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      controller: scrollController,
      // Leaves room for TableCard's scrollbar (see _scrollbarGutter) so its
      // thumb doesn't overlay the last column's own right-hand gap.
      padding: const EdgeInsets.only(right: _scrollbarGutter),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: colorScheme.outlineVariant),
      itemBuilder: (context, index) => _ProjectListTile(
        key: ValueKey(items[index].project.path),
        item: items[index],
        index: index,
      ),
    );
  }
}

class _ProjectListTile extends StatelessObserverWidget {
  const _ProjectListTile({super.key, required this.item, required this.index});

  final ProjectItemStore item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final store = context.read<StorageStore>();
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: index.isOdd
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
          : Colors.transparent,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
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
                        Text(
                          item.project.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        ProjectLanguageBadge(
                          language: item.project.language,
                          framework: item.project.framework,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 1),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsetsGeometry.symmetric(
                  horizontal: _columnGap,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ProjectSizeBar(
                    item: item,
                    maxTotalBytes: store.maxProjectTotalBytes,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _columnGap),
              child: SizedBox(
                width: _actionsColumnWidth,
                child: Center(
                  child: _ProjectCleanupButton(
                    onPressed: item.cleanup,
                    cleaning: item.cleaning,
                    disabled: store.cleaningAll,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 1),
          ],
        ),
      ),
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
