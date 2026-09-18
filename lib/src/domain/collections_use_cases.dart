import '../../repo_manager.dart';

/// Business logic for creating/renaming/deleting collections and toggling
/// a project's membership in one — a thin wrapper around [CollectionsRepo]
/// that also owns this feature area's own failure handling (log + tell the
/// user via [SnackbarManager]), so [CollectionsState] only has to hold the
/// reactive UI-facing list/version counter, not repeat this per action.
class CollectionsUseCases {
  const CollectionsUseCases(this._repo, this._l10n);

  final CollectionsRepo _repo;
  final AppLocalizations _l10n;

  List<String> getCollectionNames() => _repo.getCollectionNames();

  List<String> getProjectCollections(String projectPath) =>
      _repo.getProjectCollections(projectPath);

  Future<bool> createCollection(String name) async {
    try {
      await _repo.createCollection(name);
      return true;
    } catch (error, stackTrace) {
      logError('Create collection "$name"', error, stackTrace);
      SnackbarManager.show(_l10n.errorCreateCollection);
      return false;
    }
  }

  Future<bool> toggleProjectCollection(
    String projectPath,
    String collectionName,
  ) async {
    try {
      final current = _repo.getProjectCollections(projectPath);
      if (current.contains(collectionName)) {
        await _repo.removeProjectFromCollection(projectPath, collectionName);
      } else {
        await _repo.addProjectToCollection(projectPath, collectionName);
      }
      return true;
    } catch (error, stackTrace) {
      logError(
        'Toggle collection "$collectionName" for $projectPath',
        error,
        stackTrace,
      );
      SnackbarManager.show(_l10n.errorUpdateCollection);
      return false;
    }
  }

  // Merges into newName if a collection by that name already exists (see
  // CollectionsRepo.renameCollection).
  Future<bool> renameCollection(String oldName, String newName) async {
    try {
      await _repo.renameCollection(oldName, newName);
      return true;
    } catch (error, stackTrace) {
      logError('Rename collection "$oldName" to "$newName"', error, stackTrace);
      SnackbarManager.show(_l10n.errorRenameCollection);
      return false;
    }
  }

  Future<bool> deleteCollection(String name) async {
    try {
      await _repo.deleteCollection(name);
      return true;
    } catch (error, stackTrace) {
      logError('Delete collection "$name"', error, stackTrace);
      SnackbarManager.show(_l10n.errorDeleteCollection);
      return false;
    }
  }
}
