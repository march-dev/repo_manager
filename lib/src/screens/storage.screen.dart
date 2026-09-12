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
        IconButton(
          onPressed: store.isRefreshing ? null : store.refreshAll,
          tooltip: 'Refresh projects',
          visualDensity: VisualDensity.compact,
          icon: store.isRefreshing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(CupertinoIcons.refresh, size: 18),
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
            ],
          ),
        ],
      ),
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
        VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant),
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
        VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant),
        const SizedBox(width: _actionsColumnWidth + _columnGap * 2),
        VerticalDivider(width: 1, thickness: 1, color: colorScheme.outlineVariant),
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
                        ProjectLanguageBadge(language: item.project.language),
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
                child: Center(
                  child: ProjectSizeBar(item: item),
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
  });

  final VoidCallback onPressed;
  final bool cleaning;

  @override
  Widget build(BuildContext context) {
    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: ProjectSizeType.cache.color,
          shape: const CircleBorder(),
        ),
      ),
      child: IconButton(
        onPressed: cleaning ? null : onPressed,
        color: Colors.white,
        visualDensity: VisualDensity.compact,
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
