import 'package:mobx/mobx.dart';

import '../repos/collections.repo.dart';

part 'collections.store.g.dart';

class CollectionsStore = _CollectionsStoreBase with _$CollectionsStore;

/// Global registry of user-created collections and which projects belong
/// to each. Not Provider-scoped — showProjectContextMenu (where projects
/// get added to a collection) is also reachable from
/// showProjectDetailsDialog's modal, which sits outside the app's Provider
/// subtree (see _RootScaffold in app.dart), so anything this needs to read
/// or react to has to work without a BuildContext at all. See
/// lib/src/stores/global_stores.dart for the single shared instance,
/// explicitly constructed from DependencyResolver.collectionsRepo in main.dart
/// rather than this store reaching for its own repo via a factory/singleton.
abstract class _CollectionsStoreBase with Store {
  _CollectionsStoreBase(this._repo) {
    names = ObservableList.of(_repo.getCollectionNames());
  }

  final CollectionsRepo _repo;

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
    await _repo.createCollection(trimmed);
    names.add(trimmed);
  }

  @action
  Future<void> toggleProjectCollection(
    String projectPath,
    String collectionName,
  ) async {
    final current = _repo.getProjectCollections(projectPath);
    if (current.contains(collectionName)) {
      await _repo.removeProjectFromCollection(projectPath, collectionName);
    } else {
      await _repo.addProjectToCollection(projectPath, collectionName);
    }
    membershipVersion++;
  }

  // Merges into newName if a collection by that name already exists (see
  // CollectionsRepo.renameCollection) — either way, names ends up holding
  // exactly one entry for it afterwards.
  @action
  Future<void> renameCollection(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName) return;
    await _repo.renameCollection(oldName, trimmed);
    names.remove(oldName);
    if (!names.contains(trimmed)) names.add(trimmed);
    membershipVersion++;
  }

  @action
  Future<void> deleteCollection(String name) async {
    await _repo.deleteCollection(name);
    names.remove(name);
    membershipVersion++;
  }
}
