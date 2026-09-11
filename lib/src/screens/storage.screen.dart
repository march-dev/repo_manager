import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

const _iconGap = 16.0;
const _actionsColumnWidth = 96.0;
const _projectIconSize = 40.0;

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
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _StorageHeader(),
            Expanded(child: _TableCard()),
          ],
        ),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      // A local Material ancestor, clipped to the same rounded rect as the
      // card itself: InkWell splashes (e.g. the Name column header) paint
      // onto the nearest ancestor Material, which without this would be
      // Scaffold's own full-screen Material — unclipped by our Container's
      // clipBehavior, since that only clips this Container's own child
      // subtree, not a separate ink layer owned by an ancestor render object.
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(12),
        child: const Column(
          children: [
            _TableHeader(),
            Divider(height: 1),
            Expanded(child: _ProjectList()),
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

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Projects',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Total: ${formatBytes(total)}',
                    style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.7)),
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
              ),
            ],
          ),
          const SizedBox(height: 12),
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

    return Container(
      height: 32,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _TableHeaderLabel(
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
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
          Expanded(
            flex: 2,
            child: _TableHeaderLabel(
              label: 'Size',
              active: store.sortBy == ProjectSortBy.size,
              ascending: store.sortAscending,
              onTap: () => store.setSortBy(ProjectSortBy.size),
              alignment: Alignment.center,
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(width: _actionsColumnWidth),
          const SizedBox(width: _iconGap),
        ],
      ),
    );
  }
}

class _TableHeaderLabel extends StatelessWidget {
  const _TableHeaderLabel({
    required this.label,
    required this.active,
    required this.ascending,
    required this.onTap,
    this.alignment = Alignment.centerLeft,
    this.padding = EdgeInsets.zero,
  });

  final String label;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;
  final Alignment alignment;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = active
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.6);

    // InkWell must be the outer widget so it inherits the full column size
    // from its parent (Expanded/SizedBox); Align alone would only size
    // itself to the label's content, shrinking the tappable area. ClipRect
    // keeps the ink response confined to that column (e.g. the Name column
    // reserves left padding for the row icon above it — without the clip,
    // the splash can bleed into that reserved area past the label itself).
    return ClipRect(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Align(
            alignment: alignment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: color,
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: 2),
                  Icon(
                    ascending
                        ? CupertinoIcons.arrow_up
                        : CupertinoIcons.arrow_down,
                    size: 12,
                    color: color,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectList extends StatelessObserverWidget {
  const _ProjectList();

  @override
  Widget build(BuildContext context) {
    final store = context.read<StorageStore>();
    final items = store.sortedItems;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
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
                    child: Text(
                      item.project.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 1),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsetsGeometry.symmetric(horizontal: 12),
                child: Center(
                  child: ProjectSizeBar(item: item),
                ),
              ),
            ),
            const SizedBox(width: 1),
            SizedBox(
              width: _actionsColumnWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: _ProjectCleanupButton(
                  onPressed: item.cleanup,
                  cleaning: item.cleaning,
                ),
              ),
            ),
            const SizedBox(width: _iconGap),
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
