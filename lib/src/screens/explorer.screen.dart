import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

// ExplorerStore is provided above this screen (see _RootScaffold) rather
// than here, so DashboardScreen — a sibling, not a descendant — can read
// the same live project list/favourites for its own quick-launch section
// instead of duplicating ProjectRepo's filesystem scan in a second store.
class ExplorerScreen extends StatelessWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Scaffold();
  }
}

// Row layout constants, shared between _ProjectTable's cells and header so
// the "Name" label and sort control line up with the icon/name column of
// each row below it. Matches storage.screen.dart's own icon size/gap so
// both screens' rows look identical; row height and scrollbar gutter are
// AppTable's own matching defaults, so this screen doesn't need to repeat
// them.
const _rowPadding = 16.0;
const _rowIconSize = 40.0;
const _favouriteIconSize = 20.0;
// Matches storage.screen.dart's _columnGap, used the same way: padding
// around the trailing icon-button column.
const _columnGap = 12.0;

// A folder-path section's display data: the full path (shown in a
// tooltip) and the common-prefix-stripped path actually printed in the
// section header.
typedef _DirSection = ({String fullPath, String displayPath});

class _Scaffold extends StatelessWidget {
  const _Scaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ExplorerToolbar(),
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

class _ExplorerToolbar extends StatelessObserverWidget {
  const _ExplorerToolbar();

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();
    final l10n = AppLocalizations.of(context)!;

    return HeaderCard(
      title: l10n.explorerTitle,
      actions: [
        _SearchField(
          value: store.searchQuery,
          onChanged: store.setSearchQuery,
        ),
        const SizedBox(width: 12),
        SegmentedButton<ExplorerGrouping>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: ExplorerGrouping.none,
              label: Text(l10n.explorerGroupingNone),
              icon: const Icon(CupertinoIcons.square_stack),
            ),
            ButtonSegment(
              value: ExplorerGrouping.byFolder,
              label: Text(l10n.explorerGroupingByFolder),
              icon: const Icon(CupertinoIcons.folder),
            ),
          ],
          selected: {store.grouping},
          onSelectionChanged: (selection) => store.setGrouping(selection.first),
          // Unselected segments otherwise pick up the theme's default
          // surface tint, which reads as a separate panel floating over
          // the header card rather than sitting flush with the page
          // behind it — matching the app's own background instead makes
          // the selected segment the only thing that stands out.
          style: SegmentedButton.styleFrom(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ],
    );
  }
}

// A fixed width rather than flexing with the header card — this is a quick
// filter box, not a primary layout element, so it shouldn't compete for
// space with the grouping control next to it.
const _searchFieldWidth = 220.0;
const _actionIconSize = 32.0;

class _SearchField extends StatefulWidget {
  const _SearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  // Owns its own controller rather than rebuilding from widget.value on
  // every keystroke — store.searchQuery only ever changes via this field's
  // own onChanged, so there's no external source to resync from, and doing
  // so would just risk fighting the cursor position.
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _searchFieldWidth,
      child: TextField(
        controller: _controller,
        // setState just to redraw the suffix clear button's visibility —
        // the actual filtering runs through widget.onChanged into the store.
        onChanged: (value) => setState(() => widget.onChanged(value)),
        style: const TextStyle(
          fontSize: 13,
          height: 17 / 13,
        ),
        decoration: InputDecoration(
          isDense: true,
          // Same reasoning as the segmented button's unselected segments —
          // the default fill reads as a separate floating panel, whereas
          // matching the app background lets this sit flush with the page.
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          hintText: AppLocalizations.of(context)!.explorerSearchHint,
          hintStyle: TextStyle(
            fontSize: 13,
            height: 17 / 13,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          prefixIcon: const Icon(CupertinoIcons.search, size: 16),
          prefixIconConstraints: const BoxConstraints(
            minWidth: _actionIconSize,
            maxHeight: _actionIconSize,
          ),
          // Both icon slots are constrained to the same fixed size, and the
          // clear IconButton's own tap-target constraints are pinned too —
          // otherwise its default (48x48) intent overflows this field's
          // fixed height the moment it appears, regrowing the field to a
          // different height depending on whether text has been typed.
          suffixIconConstraints: const BoxConstraints(
            minWidth: _actionIconSize,
            maxHeight: _actionIconSize,
          ),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon:
                      const Icon(CupertinoIcons.clear_circled_solid, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    maxWidth: _actionIconSize,
                    maxHeight: _actionIconSize,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                ),
          // Explicit enabled/focused borders — otherwise focusing this field
          // pulls in the theme's default focused-border color (primary,
          // bright cyan), which reads far louder than the segmented
          // button's own neutral outline right next to it. Focused is a
          // lightened step of that same outline (not a different hue), so
          // it reads as "this field is active" without shouting.
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Color.lerp(
                Theme.of(context).colorScheme.outline,
                Theme.of(context).colorScheme.onSurface,
                0.4,
              )!,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 11.5),
        ),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
      ),
    );
  }
}

const _columns = [
  FlexColumn(),
  DividerColumn(),
  FixedColumn(_FavouriteButton.size + _columnGap * 2),
];

class _ProjectTable extends StatelessObserverWidget {
  const _ProjectTable();

  List<AppTableHeaderCell> _headerBuilder(
    BuildContext context,
    ExplorerStore store,
  ) {
    return [
      HeaderSortableButton(
        text: AppLocalizations.of(context)!.nameColumnHeader,
        ascending: store.sortAscending,
        onChanged: (_) => store.toggleNameSort(),
        padding: const EdgeInsets.only(left: _rowIconSize + _rowPadding * 2),
      ),
      _PinToggleButton(store: store),
    ];
  }

  List<Widget> _rowBuilder(
    BuildContext context,
    ProjectModel project,
    bool isHovered,
  ) {
    final monorepoTool = project.monorepoTool;

    return [
      Row(
        children: [
          const SizedBox(width: _rowPadding),
          ProjectIcon(iconPath: project.iconPath, size: _rowIconSize),
          const SizedBox(width: _rowPadding),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(project.name, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ProjectLanguageBadge(
                            language: project.language,
                            framework: project.framework,
                          ),
                          // Tapping the badge opens the member-package
                          // tree in its own dialog, rather than the row
                          // growing an always-visible expand/collapse UI —
                          // keeps the list itself just as light whether or
                          // not a given project happens to be a monorepo.
                          // Shown as soon as monorepoTool is known, even
                          // before the tree itself has finished loading in
                          // the background — MonorepoBadge just shows the
                          // tool name until subPackagesLoaded catches up.
                          if (monorepoTool != null) ...[
                            const SizedBox(width: 6),
                            MonorepoBadge(
                              tool: monorepoTool,
                              count: project.subPackagesLoaded
                                  ? project.subPackages.projectCount
                                  : null,
                              onTap: () =>
                                  showProjectDetailsDialog(context, project),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Replaces a plain hover tooltip with the same "Open in
                // <IDE>" text shown inline, at the end of the name
                // section, only while the row is hovered.
                if (isHovered) ...[
                  const SizedBox(width: _rowPadding),
                  _OpenInHint(ide: ProjectRepo().resolveIde(project)),
                  const SizedBox(width: _rowPadding),
                ],
              ],
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: _columnGap),
        child: Center(child: _FavouriteButton(project: project)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();
    final l10n = AppLocalizations.of(context)!;

    if (store.grouping == ExplorerGrouping.byFolder) {
      final entries = store.groupedProjects.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final commonPrefix =
          commonDirPrefix(entries.map((entry) => entry.key).toList());

      return AppTable<ProjectModel, _DirSection>.sectioned(
        columns: _columns,
        headerBuilder: (context) => _headerBuilder(context, store),
        rowBuilder: _rowBuilder,
        sections: [
          for (final entry in entries)
            AppTableSection(
              section: (
                fullPath: entry.key,
                displayPath: stripCommonPrefix(entry.key, commonPrefix),
              ),
              items: entry.value,
            ),
        ],
        sectionBuilder: (context, section) => _DirSectionHeader(
          fullPath: section.fullPath,
          displayPath: section.displayPath,
        ),
        onRowTap: store.openProject,
        onRowDoubleTap: (project) => showProjectDetailsDialog(context, project),
        onRowSecondaryTapUp: showProjectContextMenu,
        rowKey: (project) => ValueKey(project.path),
        emptyMessage: l10n.noProjectsFoundMessage,
      );
    }

    return AppTable<ProjectModel, Never>(
      columns: _columns,
      headerBuilder: (context) => _headerBuilder(context, store),
      rowBuilder: _rowBuilder,
      items: store.visibleProjects,
      onRowTap: store.openProject,
      onRowDoubleTap: (project) => showProjectDetailsDialog(context, project),
      onRowSecondaryTapUp: showProjectContextMenu,
      rowKey: (project) => ValueKey(project.path),
      emptyMessage: l10n.noProjectsFoundMessage,
    );
  }
}

class _PinToggleButton extends AppTableHeaderCell {
  const _PinToggleButton({required this.store});

  final ExplorerStore store;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // An InkWell rather than an IconButton, matching HeaderSortableButton
    // next to it instead of looking like a stray action button — the icon
    // is sized to sit next to that header's own 11px label/12px sort arrow
    // instead of a full IconButton's much larger default tap target.
    final l10n = AppLocalizations.of(context)!;

    return ClipRect(
      child: Tooltip(
        message: store.pinFavourites
            ? l10n.explorerPinFavouritesOnTooltip
            : l10n.explorerPinFavouritesOffTooltip,
        child: InkWell(
          onTap: store.togglePinFavourites,
          child: Center(
            child: Icon(
              store.pinFavourites
                  ? CupertinoIcons.pin_fill
                  : CupertinoIcons.pin_slash,
              size: 12,
              color: store.pinFavourites
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _DirSectionHeader extends StatelessWidget {
  const _DirSectionHeader({required this.fullPath, required this.displayPath});

  final String fullPath;
  final String displayPath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: AppTable.defaultSectionGap,
      padding: const EdgeInsets.symmetric(horizontal: _rowPadding),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Tooltip(
        message: fullPath,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.folder_fill,
              size: 16,
              color: colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                displayPath,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.3,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenInHint extends StatelessWidget {
  const _OpenInHint({required this.ide});

  final Ide ide;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.openInLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Image(image: AssetImage(ide.iconAsset), width: 14, height: 14),
          ],
        ),
        const SizedBox(height: 2),
        Text(ide.label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.project});

  // Matches storage.screen.dart's _actionsColumnWidth.
  static const size = 40.0;

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    // CircleIconButton hardcodes zero padding now, so without an explicit
    // size here the button would shrink to its icon's own bounds instead of
    // the tap target this column's width (see the header's FixedColumn
    // using this same `size`) assumes it fills.
    return SizedBox(
      width: size,
      height: size,
      child: CircleIconButton(
        backgroundColor: Colors.transparent,
        color: project.favourite ? Colors.amber : null,
        tooltip: project.favourite
            ? AppLocalizations.of(context)!.explorerRemoveFavouriteTooltip
            : AppLocalizations.of(context)!.explorerAddFavouriteTooltip,
        onPressed: () => context.read<ExplorerStore>().toggleFavourite(project),
        icon: Icon(
          project.favourite ? CupertinoIcons.star_fill : CupertinoIcons.star,
          size: _favouriteIconSize,
        ),
      ),
    );
  }
}
