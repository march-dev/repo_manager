import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../repo_manager.dart';

Widget _ideIcon(Ide ide) => menuIcon(
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

  showContextMenu(
    context,
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
  showContextMenu(context, globalPosition, [
    MenuItemButton(
      style: compactMenuButtonStyle(context),
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
      style: compactMenuButtonStyle(context),
      leadingIcon: _ideIcon(ProjectRepo().resolveIde(project)),
      onPressed: () => ProjectRepo().openInEditor(project),
      child: Text(l10n.menuOpen),
    ),
    SubmenuButton(
      style: compactMenuButtonStyle(context),
      menuStyle: compactMenuStyle(context),
      alignmentOffset: const Offset(submenuGap, 0),
      leadingIcon: menuIcon(
        const Icon(
          CupertinoIcons.arrow_up_right_square,
          size: compactMenuIconSize,
        ),
      ),
      menuChildren: _openWithMenuChildren(context, project),
      child: Text(l10n.openWithLabel),
    ),
    if (platformTargets.isNotEmpty && framework != null) ...[
      menuDivider,
      SubmenuButton(
        style: compactMenuButtonStyle(context),
        menuStyle: compactMenuStyle(context),
        alignmentOffset: const Offset(submenuGap, 0),
        leadingIcon: menuIcon(
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
    menuDivider,
    MenuItemButton(
      style: compactMenuButtonStyle(context),
      leadingIcon: menuIcon(
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
      style: compactMenuButtonStyle(context),
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
        thickness: AppSizes.borderWidth,
        color: menuBorderColor,
      ),
    for (final ide in others)
      MenuItemButton(
        style: compactMenuButtonStyle(context),
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
        style: compactMenuButtonStyle(context),
        leadingIcon: _ideIcon(target.ide),
        onPressed: () {
          ProjectRepo().recordProjectOpened(project.path);
          ProjectRepo().openPlatformTarget(project, target);
        },
        child: Text(l10n.menuOpenTarget(target.label)),
      ),
  ];
}
