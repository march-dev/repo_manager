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

const _compactMenuButtonStyle = ButtonStyle(
  visualDensity: VisualDensity.compact,
  minimumSize: WidgetStatePropertyAll(Size(0, _compactMenuItemHeight)),
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 13)),
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
///  - View Workspace Packages — only for a monorepo root
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
      style: _compactMenuButtonStyle,
      leadingIcon: _ideIcon(Ide.vscode),
      onPressed: () => ProjectRepo().openPathInIde(folderPath, Ide.vscode),
      child: const Text('Open in VS Code'),
    ),
  ]);
}

List<Widget> _rootMenuChildren(
  BuildContext context,
  ProjectModel project,
  List<PlatformTarget> platformTargets,
) {
  final framework = project.framework;

  return [
    MenuItemButton(
      style: _compactMenuButtonStyle,
      leadingIcon: _ideIcon(ProjectRepo().resolveIde(project)),
      onPressed: () => ProjectRepo().openInEditor(project),
      child: const Text('Open'),
    ),
    SubmenuButton(
      style: _compactMenuButtonStyle,
      menuStyle: _compactMenuStyle(context),
      alignmentOffset: const Offset(_submenuGap, 0),
      leadingIcon: _menuIcon(
        const Icon(
          CupertinoIcons.arrow_up_right_square,
          size: compactMenuIconSize,
        ),
      ),
      menuChildren: _openWithMenuChildren(project),
      child: const Text('Open With'),
    ),
    if (platformTargets.isNotEmpty && framework != null) ...[
      _menuDivider,
      SubmenuButton(
        style: _compactMenuButtonStyle,
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
        menuChildren: _platformTargetMenuChildren(project, platformTargets),
        child: Text(framework.label),
      ),
    ],
    // subPackages can still be empty here while its background load is
    // in flight (see ProjectModel.subPackagesLoaded) — monorepoTool alone
    // is what actually says this project has a tree worth viewing.
    if (project.monorepoTool != null) ...[
      _menuDivider,
      MenuItemButton(
        style: _compactMenuButtonStyle,
        leadingIcon: _menuIcon(
          const Icon(
            CupertinoIcons.square_stack_3d_up,
            size: compactMenuIconSize,
          ),
        ),
        onPressed: () => showWorkspacePackagesDialog(context, project),
        child: const Text('View Workspace Packages'),
      ),
    ],
  ];
}

List<Widget> _openWithMenuChildren(ProjectModel project) {
  final preferred = ProjectRepo().resolveIde(project);
  final others =
      project.language.supportedIdes.where((ide) => ide != preferred);

  return [
    MenuItemButton(
      style: _compactMenuButtonStyle,
      leadingIcon: _ideIcon(preferred),
      onPressed: () => ProjectRepo().openPathInIde(project.path, preferred),
      child: Text('${preferred.label} (default)'),
    ),
    if (others.isNotEmpty)
      const Divider(
        height: 8,
        thickness: 1,
        color: _menuBorderColor,
      ),
    for (final ide in others)
      MenuItemButton(
        style: _compactMenuButtonStyle,
        leadingIcon: _ideIcon(ide),
        onPressed: () => ProjectRepo().openPathInIde(project.path, ide),
        child: Text(ide.label),
      ),
  ];
}

List<Widget> _platformTargetMenuChildren(
  ProjectModel project,
  List<PlatformTarget> platformTargets,
) {
  return [
    for (final target in platformTargets)
      MenuItemButton(
        style: _compactMenuButtonStyle,
        leadingIcon: _ideIcon(target.ide),
        onPressed: () => ProjectRepo().openPlatformTarget(project, target),
        child: Text('Open ${target.label}'),
      ),
  ];
}
