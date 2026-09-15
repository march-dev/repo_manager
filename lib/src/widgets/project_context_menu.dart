import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../repo_manager.dart';

// Sized close to Storage's own "Clean All" button (icon size 18) rather
// than Material's much roomier default menu rows — this menu is meant to
// read as a fast, dense desktop context menu.
const compactMenuIconSize = 16.0;
const compactMenuImageSize = 13.0;
const _compactMenuItemHeight = 32.0;

// White-ish rather than colorScheme.outlineVariant: outlineVariant reads
// too close to the (also-themed) background to actually show up against
// it, whereas a translucent white edge stays visible in both light and
// dark mode.
const _menuBorderColor = Color(0x40FFFFFF);

// A little breathing room between a submenu and the button that opened
// it, rather than the submenu sitting flush against it.
const _submenuGap = 4.0;

const _menuDivider = Divider(height: 4, thickness: 1, color: _menuBorderColor);

ButtonStyle _compactMenuButtonStyle(BuildContext context) => ButtonStyle(
      visualDensity: VisualDensity.compact,
      minimumSize:
          const WidgetStatePropertyAll(Size(0, _compactMenuItemHeight)),
      padding:
          const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.bodyMedium),
    );

// Same shape/fill as TableCard/HeaderCard (12px rounded corners,
// surfaceContainerHighest as the fill) — this menu is meant to read as
// another one of the app's own cards, not Material's default elevated
// menu surface (a plain white/dark card with a drop shadow). The border
// and internal divider use a white-ish tint rather than the cards'
// outlineVariant, since outlineVariant sat too close to this menu's own
// background to actually be visible against it.
MenuStyle _compactMenuStyle(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return MenuStyle(
    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    visualDensity: VisualDensity.compact,
    elevation: const WidgetStatePropertyAll(0),
    // Material's default surfaceTint/shadow would otherwise blend into the
    // border and mute it relative to a plain Divider — kill both so the
    // border reads at the same full-strength color as the divider.
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    backgroundColor: WidgetStatePropertyAll(
      colorScheme.surfaceContainerHighest,
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _menuBorderColor, width: 1),
      ),
    ),
  );
}

/// Wraps a region of the app (Explorer's table, the workspace-packages
/// dialog's row list, ...) so [showProjectContextMenu]/
/// [showFolderContextMenu] can be called from anywhere inside it. Needed
/// because [MenuAnchor] — unlike the old `showMenu`, which this replaced —
/// has to already be mounted in the tree before it can be opened; there's
/// no one-shot "just show a menu here" call for it.
///
/// [MenuAnchor]'s own [SubmenuButton] is what actually buys the thing the
/// old showMenu-based version couldn't do: a submenu that cascades open
/// on hover, the way a native macOS context menu does, rather than
/// requiring a click to drill down and replace the current menu.
class ProjectContextMenuRegion extends StatefulWidget {
  const ProjectContextMenuRegion({super.key, required this.child});

  final Widget child;

  @override
  State<ProjectContextMenuRegion> createState() =>
      _ProjectContextMenuRegionState();
}

class _ProjectContextMenuRegionState extends State<ProjectContextMenuRegion> {
  final _controller = MenuController();
  List<Widget> _menuChildren = const [];
  bool _isOpen = false;

  void _openAt(Offset globalPosition, List<Widget> menuChildren) {
    final box = context.findRenderObject()! as RenderBox;
    setState(() => _menuChildren = menuChildren);
    _controller.open(position: box.globalToLocal(globalPosition));
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      style: _compactMenuStyle(context),
      // MenuAnchor's own consumeOutsideTap is meant to cover this same
      // "don't let the dismissing tap also hit whatever's underneath"
      // case, but it works by racing the tap into the gesture arena
      // against a dummy recognizer — in practice a row's own InkWell can
      // still end up winning that race and firing its onTap. The
      // Positioned.fill GestureDetector below is a blunter but reliable
      // fix: while the menu is open, it sits directly on top of the
      // anchor's own child (though still underneath the menu itself,
      // which renders in its own overlay entry above both), so a tap
      // outside the menu is guaranteed to hit *it* first, closing the
      // menu without ever reaching the row underneath.
      consumeOutsideTap: true,
      onOpen: () => setState(() => _isOpen = true),
      onClose: () => setState(() => _isOpen = false),
      menuChildren: _menuChildren,
      child: Stack(
        children: [
          widget.child,
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _controller.close,
                onSecondaryTap: _controller.close,
              ),
            ),
        ],
      ),
    );
  }
}

_ProjectContextMenuRegionState _regionOf(BuildContext context) {
  final state =
      context.findAncestorStateOfType<_ProjectContextMenuRegionState>();
  assert(
    state != null,
    'showProjectContextMenu/showFolderContextMenu need a '
    'ProjectContextMenuRegion ancestor to open into.',
  );
  return state!;
}

// Image (unlike Icon) has no inherent size of its own — without an
// explicit width/height it renders at the source asset's actual pixel
// dimensions (these IDE/framework logos are saved at up to 512px), which
// is what was blowing the menu up. menuIcon() is the one place that sizes
// every icon shown in this menu, so nothing can skip it by accident.
Widget _menuIcon(Widget child) {
  return Container(
    alignment: Alignment.center,
    width: compactMenuIconSize,
    height: compactMenuIconSize,
    child: child,
  );
}

Widget _ideIcon(Ide ide) => _menuIcon(
      Image(
        image: AssetImage(ide.iconAsset),
        fit: BoxFit.contain,
        width: compactMenuImageSize,
        height: compactMenuImageSize,
      ),
    );

/// The right-click menu shared by Explorer's rows and the workspace-
/// packages dialog's project rows:
///  - Open — with the project's resolved/preferred IDE
///  - Open With — every IDE the project's language supports, the
///    preferred one marked and listed first, then a divider, then the
///    rest; cascades open on hover, like a native context menu
///  - <Framework> (e.g. "Flutter") — its native platform targets
///    (ios//android/... subfolders), only shown when any were found;
///    cascades open on hover too
///  - View Details — the project's info dialog, its member-package tree
///    too if it's a monorepo
Future<void> showProjectContextMenu(
  BuildContext context,
  ProjectModel project,
  Offset globalPosition,
) async {
  // Flutter and React Native share the same ios/android(/...) platform
  // subfolder convention — see PlatformTarget for which frameworks this
  // currently covers.
  final platformTargets = await ProjectRepo().availablePlatformTargets(
    project,
  );

  if (!context.mounted) return;

  _regionOf(context)._openAt(
    globalPosition,
    _rootMenuChildren(context, project, platformTargets),
  );
}

/// A folder's own (much shorter) right-click menu — just "Open in VS
/// Code", since that's the one editor here where opening a bare directory
/// (no project file of any kind) is a meaningful thing to do at all.
void showFolderContextMenu(
  BuildContext context,
  String folderPath,
  Offset globalPosition,
) {
  _regionOf(context)._openAt(globalPosition, [
    MenuItemButton(
      style: _compactMenuButtonStyle(context),
      leadingIcon: _ideIcon(Ide.vscode),
      onPressed: () => ProjectRepo().openPathInIde(folderPath, Ide.vscode),
      child: Text(AppLocalizations.of(context)!.menuOpenInVsCode),
    ),
  ]);
}

List<Widget> _rootMenuChildren(
  BuildContext context,
  ProjectModel project,
  List<PlatformTarget> platformTargets,
) {
  final framework = project.framework;
  final l10n = AppLocalizations.of(context)!;

  return [
    MenuItemButton(
      style: _compactMenuButtonStyle(context),
      leadingIcon: _ideIcon(ProjectRepo().resolveIde(project)),
      onPressed: () => ProjectRepo().openInEditor(project),
      child: Text(l10n.menuOpen),
    ),
    SubmenuButton(
      style: _compactMenuButtonStyle(context),
      menuStyle: _compactMenuStyle(context),
      alignmentOffset: const Offset(_submenuGap, 0),
      leadingIcon: _menuIcon(
        const Icon(
          CupertinoIcons.arrow_up_right_square,
          size: compactMenuIconSize,
        ),
      ),
      menuChildren: _openWithMenuChildren(context, project),
      child: Text(l10n.openWithLabel),
    ),
    if (platformTargets.isNotEmpty && framework != null) ...[
      _menuDivider,
      SubmenuButton(
        style: _compactMenuButtonStyle(context),
        menuStyle: _compactMenuStyle(context),
        alignmentOffset: const Offset(_submenuGap, 0),
        leadingIcon: _menuIcon(
          framework.iconAsset != null
              ? Image(
                  image: AssetImage(framework.iconAsset!),
                  fit: BoxFit.contain,
                  width: compactMenuImageSize,
                  height: compactMenuImageSize,
                )
              : const Icon(
                  CupertinoIcons.app_badge,
                  size: compactMenuIconSize,
                ),
        ),
        menuChildren:
            _platformTargetMenuChildren(context, project, platformTargets),
        child: Text(framework.label),
      ),
    ],
    // Always available (not just for a monorepo) — showProjectDetailsDialog
    // itself shows a plain project's path/IDE instead of a package tree
    // when there's nothing to browse.
    _menuDivider,
    MenuItemButton(
      style: _compactMenuButtonStyle(context),
      leadingIcon: _menuIcon(
        const Icon(CupertinoIcons.info_circle, size: compactMenuIconSize),
      ),
      onPressed: () => showProjectDetailsDialog(context, project),
      child: Text(l10n.menuViewDetails),
    ),
  ];
}

List<Widget> _openWithMenuChildren(BuildContext context, ProjectModel project) {
  final l10n = AppLocalizations.of(context)!;
  final preferred = ProjectRepo().resolveIde(project);
  final others =
      project.language.supportedIdes.where((ide) => ide != preferred);

  return [
    MenuItemButton(
      style: _compactMenuButtonStyle(context),
      leadingIcon: _ideIcon(preferred),
      onPressed: () {
        ProjectRepo().recordProjectOpened(project.path);
        ProjectRepo().openPathInIde(project.path, preferred);
      },
      child: Text(l10n.menuOpenDefault(preferred.label)),
    ),
    if (others.isNotEmpty)
      const Divider(
        height: 8,
        thickness: 1,
        color: _menuBorderColor,
      ),
    for (final ide in others)
      MenuItemButton(
        style: _compactMenuButtonStyle(context),
        leadingIcon: _ideIcon(ide),
        onPressed: () {
          ProjectRepo().recordProjectOpened(project.path);
          ProjectRepo().openPathInIde(project.path, ide);
        },
        child: Text(ide.label),
      ),
  ];
}

List<Widget> _platformTargetMenuChildren(
  BuildContext context,
  ProjectModel project,
  List<PlatformTarget> platformTargets,
) {
  final l10n = AppLocalizations.of(context)!;

  return [
    for (final target in platformTargets)
      MenuItemButton(
        style: _compactMenuButtonStyle(context),
        leadingIcon: _ideIcon(target.ide),
        onPressed: () {
          ProjectRepo().recordProjectOpened(project.path);
          ProjectRepo().openPlatformTarget(project, target);
        },
        child: Text(l10n.menuOpenTarget(target.label)),
      ),
  ];
}
