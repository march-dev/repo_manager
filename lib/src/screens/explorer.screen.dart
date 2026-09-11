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

class _Scaffold extends StatelessWidget {
  const _Scaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _ExplorerCard()),
          ],
        ),
      ),
    );
  }
}

class _ExplorerCard extends StatelessWidget {
  const _ExplorerCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      // A local Material ancestor, clipped to the card's own rounded rect —
      // see storage.screen.dart's _TableCard for why this is needed (ink
      // splashes otherwise paint onto Scaffold's unclipped full-screen
      // Material instead of being confined to this card).
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(12),
        child: const Column(
          children: [
            _ExplorerHeader(),
            Divider(height: 1),
            Expanded(child: _ExplorerBody()),
          ],
        ),
      ),
    );
  }
}

class _ExplorerHeader extends StatelessObserverWidget {
  const _ExplorerHeader();

  IconData _layoutIcon(ExplorerLayout layout) {
    switch (layout) {
      case ExplorerLayout.list:
        return CupertinoIcons.list_bullet;
      case ExplorerLayout.grid:
        return CupertinoIcons.square_grid_2x2;
    }
  }

  String _layoutTooltip(ExplorerLayout layout) {
    switch (layout) {
      case ExplorerLayout.list:
        return 'List view';
      case ExplorerLayout.grid:
        return 'Grid view';
    }
  }

  IconData _groupingIcon(ExplorerGrouping grouping) {
    switch (grouping) {
      case ExplorerGrouping.none:
        return CupertinoIcons.square_stack;
      case ExplorerGrouping.byFolder:
        return CupertinoIcons.folder;
    }
  }

  String _groupingTooltip(ExplorerGrouping grouping) {
    switch (grouping) {
      case ExplorerGrouping.none:
        return 'Ungrouped';
      case ExplorerGrouping.byFolder:
        return 'Grouped by folder';
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Row(
        children: [
          Text(
            'Explorer',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: store.favouritesOnly
                ? 'Showing favourites only'
                : 'Showing all projects',
            onPressed: store.toggleFavouritesOnly,
            icon: Icon(
              store.favouritesOnly
                  ? CupertinoIcons.star_fill
                  : CupertinoIcons.star,
              color: store.favouritesOnly ? Colors.amber : null,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: _layoutTooltip(store.layout),
            onPressed: store.cycleLayout,
            icon: Icon(_layoutIcon(store.layout)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: _groupingTooltip(store.grouping),
            onPressed: store.cycleGrouping,
            icon: Icon(_groupingIcon(store.grouping)),
          ),
        ],
      ),
    );
  }
}

class _ExplorerBody extends StatelessObserverWidget {
  const _ExplorerBody();

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();
    final colorScheme = Theme.of(context).colorScheme;

    if (store.projects.isEmpty) {
      return Center(
        child: Text(
          'No projects found. Add a directory in Settings.',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }

    final visible = store.visibleProjects;
    if (visible.isEmpty) {
      return Center(
        child: Text(
          'No favourite projects yet.',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }

    if (store.grouping == ExplorerGrouping.byFolder) {
      return _ProjectGroupedView(
        grouped: store.groupedProjects,
        asTiles: store.layout == ExplorerLayout.grid,
      );
    }

    switch (store.layout) {
      case ExplorerLayout.list:
        return _ProjectListView(projects: visible);
      case ExplorerLayout.grid:
        return _ProjectGridView(projects: visible);
    }
  }
}

class _ProjectListView extends StatelessWidget {
  const _ProjectListView({required this.projects});

  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: projects.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: colorScheme.outlineVariant),
      itemBuilder: (context, index) => _ProjectRow(project: projects[index]),
    );
  }
}

class _ProjectGridView extends StatelessWidget {
  const _ProjectGridView({required this.projects});

  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: _TileGrid(projects: projects),
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.projects});

  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final project in projects) _ProjectTile(project: project),
      ],
    );
  }
}

class _ProjectGroupedView extends StatelessWidget {
  const _ProjectGroupedView({required this.grouped, required this.asTiles});

  final Map<String, List<ProjectModel>> grouped;
  final bool asTiles;

  @override
  Widget build(BuildContext context) {
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == entries.length - 1 ? 0 : 20,
          ),
          child: _ProjectGroup(
            dirPath: entry.key,
            projects: entry.value,
            asTiles: asTiles,
          ),
        );
      },
    );
  }
}

class _ProjectGroup extends StatelessWidget {
  const _ProjectGroup({
    required this.dirPath,
    required this.projects,
    required this.asTiles,
  });

  final String dirPath;
  final List<ProjectModel> projects;
  final bool asTiles;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.folder_fill,
              size: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dirPath,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 0.3,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (asTiles)
          _TileGrid(projects: projects)
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                for (var i = 0; i < projects.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: colorScheme.outlineVariant),
                  _ProjectRow(project: projects[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.read<ExplorerStore>().openProject(project),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              ProjectIcon(iconPath: project.iconPath, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(project.name, overflow: TextOverflow.ellipsis),
              ),
              _FavouriteButton(project: project),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project});

  final ProjectModel project;

  static const _width = 140.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: _width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          // Only this InkWell (not Positioned) sizes the Stack, so the
          // favourite button below can sit exactly at the tile's corner
          // without affecting the tile's layout or pushing content down.
          children: [
            InkWell(
              onTap: () => context.read<ExplorerStore>().openProject(project),
              // Stack loosens the width constraint it hands to non-positioned
              // children (StackFit.loose), so without this the InkWell would
              // shrink to its content's width instead of the full tile —
              // visible as a hover/splash highlight narrower than the card.
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ProjectIcon(iconPath: project.iconPath, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        project.name,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _FavouriteButton(project: project, visualSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.project, this.visualSize = 20});

  final ProjectModel project;
  final double visualSize;

  // The tappable area is much bigger than the icon itself, via an
  // OverflowBox: the button's layout footprint stays exactly [visualSize],
  // so it doesn't push surrounding content around or throw off symmetric
  // spacing, while the actual hit-testable button overflows that footprint
  // evenly on every side.
  static const _tapSize = 48.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: visualSize,
      height: visualSize,
      child: OverflowBox(
        minWidth: _tapSize,
        minHeight: _tapSize,
        maxWidth: _tapSize,
        maxHeight: _tapSize,
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints:
              const BoxConstraints(minWidth: _tapSize, minHeight: _tapSize),
          tooltip: project.favourite
              ? 'Remove from favourites'
              : 'Add to favourites',
          onPressed: () =>
              context.read<ExplorerStore>().toggleFavourite(project),
          icon: Icon(
            project.favourite ? CupertinoIcons.star_fill : CupertinoIcons.star,
            size: visualSize,
            color: project.favourite ? Colors.amber : null,
          ),
        ),
      ),
    );
  }
}
