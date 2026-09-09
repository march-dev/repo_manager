import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../../repo_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _store = DashboardStore();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _DashboardToolbar(store: _store),
            const Divider(height: 1),
            Expanded(
              child: Observer(
                builder: (context) {
                  final items = _store.sortedItems;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _ProjectListTile(item: items[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardToolbar extends StatelessWidget {
  const _DashboardToolbar({required this.store});

  final DashboardStore store;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Observer(
          builder: (context) => Row(
            children: [
              _SizeSummary(label: 'Total', bytes: store.totalBytes),
              const SizedBox(width: 16),
              _SizeSummary(
                label: 'Core',
                bytes: store.coreBytes,
                color: ProjectSizeType.core.color,
              ),
              const SizedBox(width: 16),
              _SizeSummary(
                label: 'Cache',
                bytes: store.cacheBytes,
                color: ProjectSizeType.cache.color,
              ),
              const Spacer(),
              _SortChip(
                label: 'Name',
                sortBy: ProjectSortBy.name,
                store: store,
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'Size',
                sortBy: ProjectSortBy.size,
                store: store,
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: store.isRefreshing ? null : store.refreshAll,
                tooltip: 'Refresh projects',
                icon: store.isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(CupertinoIcons.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SizeSummary extends StatelessWidget {
  const _SizeSummary({required this.label, required this.bytes, this.color});

  final String label;
  final int bytes;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (color != null) ...[
          _ColorDot(color: color!),
          const SizedBox(width: 6),
        ],
        Text('$label: ${formatBytes(bytes)}'),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip(
      {required this.label, required this.sortBy, required this.store});

  final String label;
  final ProjectSortBy sortBy;
  final DashboardStore store;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = store.sortBy == sortBy;
    final foreground = active ? colorScheme.onPrimary : colorScheme.onSurface;

    return FilterChip(
      label: Text(label, style: TextStyle(color: foreground)),
      selected: active,
      showCheckmark: false,
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHighest,
      avatar: active
          ? Icon(
              store.sortAscending
                  ? CupertinoIcons.arrow_up
                  : CupertinoIcons.arrow_down,
              size: 16,
              color: foreground,
            )
          : null,
      onSelected: (_) => store.setSortBy(sortBy),
    );
  }
}

class _ProjectListTile extends StatelessWidget {
  const _ProjectListTile({required this.item});

  final ProjectItemStore item;

  @override
  Widget build(BuildContext context) {
    final title = Row(
      children: [
        Expanded(
          child: Text(item.project.name, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 24),
        _ProjectSizeBar(item: item),
        const SizedBox(width: 24),
      ],
    );

    final trailing = Observer(
      builder: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          _ProjectCleanupButton(
            onPressed: item.cleanup,
            cleaning: item.cleaning,
          ),
          _ProjectOpenButton(
            onPressed: item.openInEditor,
          ),
        ],
      ),
    );

    return SizedBox(
      height: 64,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: _ProjectIcon(iconPath: item.project.iconPath),
        title: title,
        trailing: trailing,
      ),
    );
  }
}

class _ProjectIcon extends StatelessWidget {
  const _ProjectIcon({required this.iconPath});

  final String iconPath;

  @override
  Widget build(BuildContext context) {
    if (iconPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(iconPath),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return const Icon(CupertinoIcons.folder, size: 40);
    }
  }
}

class _ProjectSizeBar extends StatelessWidget {
  const _ProjectSizeBar({required this.item});

  static const _width = 120.0;
  static const _height = 12.0;
  static const _animationDuration = Duration(milliseconds: 350);

  final ProjectItemStore item;

  WidgetSpan _legendDot(Color color) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: _width,
      height: _height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_height / 2),
        color: colorScheme.surfaceContainerHighest,
      ),
      child: Observer(
        builder: (context) {
          final size = item.size;

          Widget content;

          if (size == null) {
            content = LinearProgressIndicator(
              key: const ValueKey('loading'),
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            );
          } else if (size.totalBytes <= 0) {
            content = const SizedBox.expand(key: ValueKey('empty'));
          } else {
            final coreWidth = _width * size.baseBytes / size.totalBytes;
            final cacheWidth = _width * size.cacheBytes / size.totalBytes;

            content = Tooltip(
              key: const ValueKey('bar'),
              verticalOffset: 12,
              richMessage: TextSpan(
                children: [
                  _legendDot(ProjectSizeType.core.color),
                  TextSpan(text: ' Core: ${formatBytes(size.baseBytes)}\n'),
                  _legendDot(ProjectSizeType.cache.color),
                  TextSpan(text: ' Cache: ${formatBytes(size.cacheBytes)}'),
                ],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: _animationDuration,
                    curve: Curves.easeInOut,
                    width: coreWidth,
                    color: ProjectSizeType.core.color,
                  ),
                  AnimatedContainer(
                    duration: _animationDuration,
                    curve: Curves.easeInOut,
                    width: cacheWidth,
                    color: ProjectSizeType.cache.color,
                  ),
                ],
              ),
            );
          }

          return AnimatedSwitcher(
            duration: _animationDuration,
            child: content,
          );
        },
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
    final colorScheme = Theme.of(context).colorScheme;

    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.error,
        ),
      ),
      child: IconButton(
        onPressed: cleaning ? null : onPressed,
        color: colorScheme.onError,
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

class _ProjectOpenButton extends StatelessWidget {
  const _ProjectOpenButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: Colors.teal[600],
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        color: Colors.white,
        tooltip: 'Open the project in VSCode',
        icon: const Icon(
          CupertinoIcons.arrow_up_right_square,
          size: 20,
        ),
      ),
    );
  }
}
