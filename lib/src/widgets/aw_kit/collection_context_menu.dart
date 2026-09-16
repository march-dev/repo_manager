import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../repo_manager.dart';

/// The right-click menu on a collection's own section header in Explorer's
/// "group by collection" view: rename it, or delete it outright. Deleting
/// only forgets the grouping — the member projects themselves are
/// untouched, they just fall back under the "Uncategorized" section.
void showCollectionContextMenu(
  BuildContext context,
  String collectionName,
  Offset globalPosition,
) {
  final l10n = AppLocalizations.of(context)!;

  showContextMenu(context, globalPosition, [
    MenuItemButton(
      style: compactMenuButtonStyle(context),
      leadingIcon: const MenuIcon(
        child: Icon(CupertinoIcons.pencil, size: compactMenuIconSize),
      ),
      onPressed: () => _renameCollection(context, collectionName),
      child: Text(l10n.menuRenameCollection),
    ),
    MenuItemButton(
      style: compactMenuButtonStyle(context),
      leadingIcon: const MenuIcon(
        child: Icon(CupertinoIcons.delete, size: compactMenuIconSize),
      ),
      onPressed: () => _confirmDeleteCollection(context, collectionName),
      child: Text(l10n.menuDeleteCollection),
    ),
  ]);
}

Future<void> _confirmDeleteCollection(
  BuildContext context,
  String collectionName,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showConfirmDialog(
    context,
    title: l10n.deleteCollectionDialogTitle,
    message: l10n.deleteCollectionDialogMessage(collectionName),
    confirmLabel: l10n.deleteCollectionDialogConfirm,
  );
  if (!confirmed) return;

  await collectionsStore.deleteCollection(collectionName);
}

Future<void> _renameCollection(
  BuildContext context,
  String collectionName,
) async {
  final l10n = AppLocalizations.of(context)!;
  final name = await showTextInputDialog(
    context,
    title: l10n.renameCollectionDialogTitle,
    hintText: l10n.newCollectionDialogHint,
    confirmLabel: l10n.renameCollectionDialogConfirm,
    initialValue: collectionName,
  );
  if (name == null) return;

  await collectionsStore.renameCollection(collectionName, name);
}
