import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../repo_manager.dart';

class _IdeIcon extends StatelessWidget {
  const _IdeIcon(this.ide);

  final Ide ide;

  @override
  Widget build(BuildContext context) {
    return MenuIcon(
      child: Image(
        image: AssetImage(ide.iconAsset),
        fit: BoxFit.contain,
        width: compactMenuImageSize,
        height: compactMenuImageSize,
      ),
    );
  }
}

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
  Offset globalPosition, {
  required CollectionsStore collectionsStore,
  required IdeLauncherStore ideLauncherStore,
  required ProjectScannerStore projectScannerStore,
}) async {
  // Flutter and React Native share the same ios/android(/...) platform
  // subfolder convention — see PlatformTarget for which frameworks this
  // currently covers.
  final platformTargets =
      await ideLauncherStore.availablePlatformTargets(project);

  if (!context.mounted) return;

  showContextMenu(
    context,
    globalPosition,
    _rootMenuChildren(
      context,
      project,
      platformTargets,
      collectionsStore: collectionsStore,
      ideLauncherStore: ideLauncherStore,
      projectScannerStore: projectScannerStore,
    ),
  );
}

/// A folder's own (much shorter) right-click menu — just "Open in VS
/// Code", since that's the one editor here where opening a bare directory
/// (no project file of any kind) is a meaningful thing to do at all.
void showFolderContextMenu(
  BuildContext context,
  String folderPath,
  Offset globalPosition, {
  required IdeLauncherStore ideLauncherStore,
}) {
  showContextMenu(context, globalPosition, [
    MenuItemButton(
      style: compactMenuButtonStyle(context),
      leadingIcon: const _IdeIcon(Ide.vscode),
      onPressed: () => ideLauncherStore.openPathInIde(folderPath, Ide.vscode),
      child: Text(AppLocalizations.of(context)!.menuOpenInVsCode),
    ),
  ]);
}

List<Widget> _rootMenuChildren(
  BuildContext context,
  ProjectModel project,
  List<PlatformTarget> platformTargets, {
  required CollectionsStore collectionsStore,
  required IdeLauncherStore ideLauncherStore,
  required ProjectScannerStore projectScannerStore,
}) {
  final framework = project.framework;
  final l10n = AppLocalizations.of(context)!;

  return [
    MenuItemButton(
      style: compactMenuButtonStyle(context),
      leadingIcon: _IdeIcon(ideLauncherStore.resolveIde(project)),
      onPressed: () => ideLauncherStore.openInEditor(project),
      child: Text(l10n.menuOpen),
    ),
    SubmenuButton(
      style: compactMenuButtonStyle(context),
      menuStyle: compactMenuStyle(context),
      alignmentOffset: const Offset(submenuGap, 0),
      leadingIcon: const MenuIcon(
        child: Icon(
          CupertinoIcons.arrow_up_right_square,
          size: compactMenuIconSize,
        ),
      ),
      menuChildren: _openWithMenuChildren(
        context,
        project,
        ideLauncherStore: ideLauncherStore,
      ),
      child: Text(l10n.openWithLabel),
    ),
    menuDivider(),
    SubmenuButton(
      style: compactMenuButtonStyle(context),
      menuStyle: compactMenuStyle(context),
      alignmentOffset: const Offset(submenuGap, 0),
      leadingIcon: const MenuIcon(
        child: Icon(
          CupertinoIcons.square_stack_3d_up,
          size: compactMenuIconSize,
        ),
      ),
      menuChildren: _collectionMenuChildren(
        context,
        project,
        collectionsStore: collectionsStore,
      ),
      child: Text(l10n.collectionsLabel),
    ),
    if (platformTargets.isNotEmpty && framework != null) ...[
      menuDivider(),
      SubmenuButton(
        style: compactMenuButtonStyle(context),
        menuStyle: compactMenuStyle(context),
        alignmentOffset: const Offset(submenuGap, 0),
        leadingIcon: MenuIcon(
          child: framework.iconAsset != null
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
        menuChildren: _platformTargetMenuChildren(
          context,
          project,
          platformTargets,
          ideLauncherStore: ideLauncherStore,
        ),
        child: Text(framework.label),
      ),
    ],
    // Always available (not just for a monorepo) — showProjectDetailsDialog
    // itself shows a plain project's path/IDE instead of a package tree
    // when there's nothing to browse.
    menuDivider(),
    MenuItemButton(
      style: compactMenuButtonStyle(context),
      leadingIcon: const MenuIcon(
        child: Icon(CupertinoIcons.info_circle, size: compactMenuIconSize),
      ),
      onPressed: () => showProjectDetailsDialog(
        context,
        project,
        collectionsStore: collectionsStore,
        ideLauncherStore: ideLauncherStore,
        projectScannerStore: projectScannerStore,
      ),
      child: Text(l10n.menuViewDetails),
    ),
  ];
}

List<Widget> _openWithMenuChildren(
  BuildContext context,
  ProjectModel project, {
  required IdeLauncherStore ideLauncherStore,
}) {
  final l10n = AppLocalizations.of(context)!;
  final preferred = ideLauncherStore.resolveIde(project);
  final others =
      project.language.supportedIdes.where((ide) => ide != preferred);

  return [
    MenuItemButton(
      style: compactMenuButtonStyle(context),
      leadingIcon: _IdeIcon(preferred),
      onPressed: () {
        ideLauncherStore.recordProjectOpened(project.path);
        ideLauncherStore.openPathInIde(project.path, preferred);
      },
      child: Text(l10n.menuOpenDefault(preferred.label)),
    ),
    if (others.isNotEmpty) menuDivider(height: 8),
    for (final ide in others)
      MenuItemButton(
        style: compactMenuButtonStyle(context),
        leadingIcon: _IdeIcon(ide),
        onPressed: () {
          ideLauncherStore.recordProjectOpened(project.path);
          ideLauncherStore.openPathInIde(project.path, ide);
        },
        child: Text(ide.label),
      ),
  ];
}

List<Widget> _collectionMenuChildren(
  BuildContext context,
  ProjectModel project, {
  required CollectionsStore collectionsStore,
}) {
  final l10n = AppLocalizations.of(context)!;
  final names = collectionsStore.names;
  final memberOf = collectionsStore.getProjectCollections(project.path);

  return [
    for (final name in names)
      MenuItemButton(
        style: compactMenuButtonStyle(context),
        leadingIcon: MenuIcon(
          child: Icon(
            memberOf.contains(name)
                ? CupertinoIcons.checkmark_square_fill
                : CupertinoIcons.square,
            size: compactMenuIconSize,
          ),
        ),
        onPressed: () =>
            collectionsStore.toggleProjectCollection(project.path, name),
        child: Text(name),
      ),
    if (names.isNotEmpty) menuDivider(),
    MenuItemButton(
      style: compactMenuButtonStyle(context),
      leadingIcon: const MenuIcon(
        child: Icon(CupertinoIcons.add, size: compactMenuIconSize),
      ),
      onPressed: () => _promptNewCollection(
        context,
        project,
        collectionsStore: collectionsStore,
      ),
      child: Text(l10n.menuNewCollection),
    ),
  ];
}

Future<void> _promptNewCollection(
  BuildContext context,
  ProjectModel project, {
  required CollectionsStore collectionsStore,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final name = await showTextInputDialog(
    context,
    title: l10n.newCollectionDialogTitle,
    hintText: l10n.newCollectionDialogHint,
    confirmLabel: l10n.newCollectionDialogConfirm,
  );
  if (name == null) return;

  final trimmed = name.trim();
  if (collectionsStore.names.contains(trimmed)) {
    SnackbarManager.show(l10n.collectionAlreadyExistsMessage(trimmed));
    // Already a member too (re-typed rather than picked from the list
    // above) — toggling blindly would then read as "add" but actually
    // remove it, so this leaves membership alone rather than flipping it
    // off; otherwise it falls through and joins the existing collection.
    if (collectionsStore
        .getProjectCollections(project.path)
        .contains(trimmed)) {
      return;
    }
  }

  await collectionsStore.createCollection(name);
  await collectionsStore.toggleProjectCollection(project.path, trimmed);
}

List<Widget> _platformTargetMenuChildren(
  BuildContext context,
  ProjectModel project,
  List<PlatformTarget> platformTargets, {
  required IdeLauncherStore ideLauncherStore,
}) {
  final l10n = AppLocalizations.of(context)!;

  return [
    for (final target in platformTargets)
      MenuItemButton(
        style: compactMenuButtonStyle(context),
        leadingIcon: _IdeIcon(target.ide),
        onPressed: () {
          ideLauncherStore.recordProjectOpened(project.path);
          ideLauncherStore.openPlatformTarget(project, target);
        },
        child: Text(l10n.menuOpenTarget(target.label)),
      ),
  ];
}
