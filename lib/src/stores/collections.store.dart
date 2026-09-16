import 'package:mobx/mobx.dart';

import '../../l10n/generated/app_localizations.dart';
import '../repos/collections.repo.dart';
import '../utils/error_logging.util.dart';
import '../widgets/ui_kit/notifications/snackbar_manager.dart';

part 'collections.store.g.dart';

class CollectionsStore = _CollectionsStoreBase with _$CollectionsStore;

/// Registry of user-created collections and which projects belong to each,
/// registered as a plain `Provider<CollectionsStore>` in _RootScaffold's
/// MultiProvider (app.dart). showProjectContextMenu (where projects get
/// added to a collection) is also reachable from showProjectDetailsDialog's
/// modal, which sits outside that Provider subtree — so that call chain
/// gets this instance passed in explicitly by whichever Provider-reachable
/// call site opened the dialog, rather than reading it via `context.read`
/// itself.
abstract class _CollectionsStoreBase with Store {
  _CollectionsStoreBase(this._repo, this._l10n) {
    names = ObservableList.of(_repo.getCollectionNames());
  }

  final CollectionsRepo _repo;
  final AppLocalizations _l10n;

  @observable
  ObservableList<String> names = ObservableList<String>();

  // Bumped on every membership change so a @computed elsewhere (e.g.
  // ExplorerStore.groupedByCollection) can depend on this store for
  // reactivity, while still reading the actual project<->collection
  // mapping straight from CollectionsRepo (via [getProjectCollections]
  // below) rather than this duplicating it.
  @observable
  int membershipVersion = 0;

  List<String> getProjectCollections(String projectPath) =>
      _repo.getProjectCollections(projectPath);

  @action
  Future<void> createCollection(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || names.contains(trimmed)) return;
    try {
      await _repo.createCollection(trimmed);
      names.add(trimmed);
    } on Object catch (error, stackTrace) {
      logError('Create collection "$trimmed"', error, stackTrace);
      SnackbarManager.show(_l10n.errorCreateCollection);
    }
  }

  @action
  Future<void> toggleProjectCollection(
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
      membershipVersion++;
    } on Object catch (error, stackTrace) {
      logError(
        'Toggle collection "$collectionName" for $projectPath',
        error,
        stackTrace,
      );
      SnackbarManager.show(_l10n.errorUpdateCollection);
    }
  }

  // Merges into newName if a collection by that name already exists (see
  // CollectionsRepo.renameCollection) — either way, names ends up holding
  // exactly one entry for it afterwards.
  @action
  Future<void> renameCollection(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName) return;
    try {
      await _repo.renameCollection(oldName, trimmed);
      names.remove(oldName);
      if (!names.contains(trimmed)) names.add(trimmed);
      membershipVersion++;
    } on Object catch (error, stackTrace) {
      logError('Rename collection "$oldName" to "$trimmed"', error, stackTrace);
      SnackbarManager.show(_l10n.errorRenameCollection);
    }
  }

  @action
  Future<void> deleteCollection(String name) async {
    try {
      await _repo.deleteCollection(name);
      names.remove(name);
      membershipVersion++;
    } on Object catch (error, stackTrace) {
      logError('Delete collection "$name"', error, stackTrace);
      SnackbarManager.show(_l10n.errorDeleteCollection);
    }
  }
}
