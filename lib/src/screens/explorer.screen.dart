import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

// Falls back to VS Code for languages with no dedicated preferred-IDE
// setting (see LanguageGroup), matching ProjectRepo.openInEditor's own
// fallback so the tooltip never promises an IDE the tap won't actually use.
Ide _preferredIdeFor(ProjectLanguage language) {
  final group = LanguageGroup.forLanguage(language);
  return group != null ? ProjectRepo().getPreferredIde(group) : Ide.vscode;
}

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

// Row layout constants, shared between _ProjectRow and _ProjectsTableHeader
// so the header's "Name" label and sort control line up with the icon/name
// column of each row below it.
const _rowPadding = 12.0;
const _rowIconSize = 32.0;
const _favouriteIconSize = 20.0;
// Reserved so TableCard's always-visible scrollbar has its own lane instead
// of floating as an overlay on top of the favourite column.
const _scrollbarGutter = 12.0;

class _Scaffold extends StatelessObserverWidget {
  const _Scaffold();

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _ExplorerToolbar(),
            Expanded(
              child: TableCard(
                // Grouped-by-folder mode shows each group as its own card
                // with its own "Name" header (see _ProjectGroup), so a
                // single header frozen above the whole stack of cards
                // wouldn't belong to any one of them — only the flat list
                // gets the persistent card-level header.
                header: store.grouping == ExplorerGrouping.byFolder
                    ? null
                    : const _ProjectsTableHeader(),
                bodyBuilder: (context, scrollController) =>
                    _ExplorerBody(scrollController: scrollController),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplorerToolbar extends StatelessObserverWidget {
  const _ExplorerToolbar();

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();

    return HeaderCard(
      title: 'Projects Explorer',
      actions: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip:
              store.pinFavourites ? 'Favourites pinned to top' : 'No pinning',
          onPressed: store.togglePinFavourites,
          icon: Icon(
            store.pinFavourites
                ? CupertinoIcons.pin_fill
                : CupertinoIcons.pin_slash,
          ),
        ),
        const SizedBox(width: 12),
        SegmentedButton<ExplorerGrouping>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: ExplorerGrouping.none,
              label: Text('None'),
              icon: Icon(CupertinoIcons.square_stack),
            ),
            ButtonSegment(
              value: ExplorerGrouping.byFolder,
              label: Text('By Folder'),
              icon: Icon(CupertinoIcons.folder),
            ),
          ],
          selected: {store.grouping},
          onSelectionChanged: (selection) => store.setGrouping(selection.first),
        ),
      ],
    );
  }
}

// Shows a sortable "Name" column header, matching storage.screen.dart's
// table header. TableCard draws the divider below it.
class _ProjectsTableHeader extends StatelessObserverWidget {
  const _ProjectsTableHeader();

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();
    final colorScheme = Theme.of(context).colorScheme;

    return TableHeaderRow(
      children: [
        Expanded(
          child: SortableColumnHeader(
            label: 'Name',
            active: true,
            ascending: store.sortAscending,
            onTap: store.toggleNameSort,
            padding:
                const EdgeInsets.only(left: _rowIconSize + _rowPadding * 2),
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant,
        ),
        const SizedBox(width: _FavouriteButton.size + _rowPadding * 2),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant,
        ),
        const SizedBox(width: _scrollbarGutter),
      ],
    );
  }
}

class _ExplorerBody extends StatelessObserverWidget {
  const _ExplorerBody({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();
    final colorScheme = Theme.of(context).colorScheme;

    if (store.projects.isEmpty) {
      return _EmptyProjectList(
        scrollController: scrollController,
        message: 'No projects found. Add a directory in Settings.',
        colorScheme: colorScheme,
      );
    }

    if (store.grouping == ExplorerGrouping.byFolder) {
      return _ProjectGroupedView(
        scrollController: scrollController,
        grouped: store.groupedProjects,
      );
    }

    return _ProjectListView(
      scrollController: scrollController,
      projects: store.visibleProjects,
    );
  }
}

// A Scrollbar with `thumbVisibility: true` asserts that its controller has
// an attached ScrollPosition, so the empty state needs to be a real
// Scrollable (not a bare Center) — sized to the viewport so the message
// still reads as vertically centered.
class _EmptyProjectList extends StatelessWidget {
  const _EmptyProjectList({
    required this.scrollController,
    required this.message,
    required this.colorScheme,
  });

  final ScrollController scrollController;
  final String message;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        controller: scrollController,
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectListView extends StatelessWidget {
  const _ProjectListView({
    required this.scrollController,
    required this.projects,
  });

  final ScrollController scrollController;
  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4)
          .copyWith(right: _scrollbarGutter),
      itemCount: projects.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: colorScheme.outlineVariant),
      itemBuilder: (context, index) =>
          _ProjectRow(project: projects[index], index: index),
    );
  }
}

class _ProjectGroupedView extends StatelessWidget {
  const _ProjectGroupedView({
    required this.scrollController,
    required this.grouped,
  });

  final ScrollController scrollController;
  final Map<String, List<ProjectModel>> grouped;

  @override
  Widget build(BuildContext context) {
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final commonPrefix =
        _commonDirPrefix(entries.map((entry) => entry.key).toList());

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16).copyWith(right: 16 + _scrollbarGutter),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == entries.length - 1 ? 0 : 20,
          ),
          child: _ProjectGroup(
            fullPath: entry.key,
            displayPath: _stripCommonPrefix(entry.key, commonPrefix),
            projects: entry.value,
          ),
        );
      },
    );
  }
}

// The part of [path] that isn't shared by every group's directory, so two
// search directories like "/Users/x/Projects" and "/Users/x/Projects/other"
// show as just "Projects" and "Projects/other" instead of their full,
// mostly-identical absolute paths.
String _stripCommonPrefix(String path, String commonPrefix) {
  if (commonPrefix.isEmpty) return path;
  if (path == commonPrefix) return path.split(Platform.pathSeparator).last;

  final prefixWithSeparator = commonPrefix.endsWith(Platform.pathSeparator)
      ? commonPrefix
      : '$commonPrefix${Platform.pathSeparator}';
  return path.startsWith(prefixWithSeparator)
      ? path.substring(prefixWithSeparator.length)
      : path;
}

String _commonDirPrefix(List<String> paths) {
  if (paths.isEmpty) return '';

  final segmentLists = paths.map((p) => p.split(Platform.pathSeparator)).toList();
  final shortestLength =
      segmentLists.map((segments) => segments.length).reduce((a, b) => a < b ? a : b);

  var commonLength = shortestLength;
  for (var i = 0; i < shortestLength; i++) {
    final segment = segmentLists.first[i];
    if (!segmentLists.every((segments) => segments[i] == segment)) {
      commonLength = i;
      break;
    }
  }
  // Always leave at least the last segment of the shortest path
  // un-stripped, so a directory never shortens down to nothing.
  if (commonLength >= shortestLength) commonLength = shortestLength - 1;
  if (commonLength <= 0) return '';

  return segmentLists.first.sublist(0, commonLength).join(Platform.pathSeparator);
}

class _ProjectGroup extends StatelessWidget {
  const _ProjectGroup({
    required this.fullPath,
    required this.displayPath,
    required this.projects,
  });

  final String fullPath;
  final String displayPath;
  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // A card of its own — same border/radius as every other card in the
    // app, but filled with the app's own background color rather than the
    // usual card tint, so it reads as a cutout against TableCard's tinted
    // background instead of just stacking the same tint on top of itself.
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(_rowPadding, 10, _rowPadding, 10),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.folder_fill,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Tooltip(
                    message: fullPath,
                    child: Text(
                      displayPath,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 0.3,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          // Each group is its own card now (see the comment above), so its
          // "Name" column header lives here rather than frozen once above
          // every group at the TableCard level (see _Scaffold).
          const _ProjectsTableHeader(),
          Divider(height: 1, color: colorScheme.outlineVariant),
          for (var i = 0; i < projects.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colorScheme.outlineVariant),
            _ProjectRow(project: projects[i], index: i),
          ],
        ],
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project, required this.index});

  final ProjectModel project;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: index.isOdd
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
          : Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.read<ExplorerStore>().openProject(project),
          child: Tooltip(
            message: 'Open in ${_preferredIdeFor(project.language).label}',
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _rowPadding,
                vertical: 6,
              ),
              child: Row(
                children: [
                  ProjectIcon(iconPath: project.iconPath, size: _rowIconSize),
                  const SizedBox(width: _rowPadding),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        ProjectLanguageBadge(language: project.language),
                      ],
                    ),
                  ),
                  const SizedBox(width: 1),
                  _FavouriteButton(project: project),
                  const SizedBox(width: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.project});

  static const size = 48.0;

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashRadius: 24,
      padding: EdgeInsets.zero,
      tooltip:
          project.favourite ? 'Remove from favourites' : 'Add to favourites',
      onPressed: () => context.read<ExplorerStore>().toggleFavourite(project),
      icon: Icon(
        project.favourite ? CupertinoIcons.star_fill : CupertinoIcons.star,
        size: _favouriteIconSize,
        color: project.favourite ? Colors.amber : null,
      ),
    );
  }
}
