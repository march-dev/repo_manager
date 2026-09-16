import 'package:mobx/mobx.dart';

import '../repos/project.repo.dart';

part 'collections.store.g.dart';

class CollectionsStore = _CollectionsStoreBase with _$CollectionsStore;

/// Global registry of user-created collections and which projects belong
/// to each. A plain top-level singleton (see [collectionsStore]) rather
/// than something provided via Provider — showProjectContextMenu (where
/// projects get added to a collection) is also reachable from
/// showProjectDetailsDialog's modal, which sits outside the app's Provider
/// subtree (see _RootScaffold in app.dart), so anything this needs to read
/// or react to has to work without a BuildContext at all.
abstract class _CollectionsStoreBase with Store {
  _CollectionsStoreBase() {
    names = ObservableList.of(ProjectRepo().getCollectionNames());
  }

  @observable
  ObservableList<String> names = ObservableList<String>();

  // Bumped on every membership change so a @computed elsewhere (e.g.
  // ExplorerStore.groupedByCollection) can depend on this store for
  // reactivity, while still reading the actual project<->collection
  // mapping straight from ProjectRepo rather than this duplicating it.
  @observable
  int membershipVersion = 0;

  @action
  Future<void> createCollection(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || names.contains(trimmed)) return;
    await ProjectRepo().createCollection(trimmed);
    names.add(trimmed);
  }

  @action
  Future<void> toggleProjectCollection(
    String projectPath,
    String collectionName,
  ) async {
    final current = ProjectRepo().getProjectCollections(projectPath);
    if (current.contains(collectionName)) {
      await ProjectRepo().removeProjectFromCollection(
        projectPath,
        collectionName,
      );
    } else {
      await ProjectRepo().addProjectToCollection(projectPath, collectionName);
    }
    membershipVersion++;
  }

  // Merges into newName if a collection by that name already exists (see
  // ProjectRepo.renameCollection) — either way, names ends up holding
  // exactly one entry for it afterwards.
  @action
  Future<void> renameCollection(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName) return;
    await ProjectRepo().renameCollection(oldName, trimmed);
    names.remove(oldName);
    if (!names.contains(trimmed)) names.add(trimmed);
    membershipVersion++;
  }

  @action
  Future<void> deleteCollection(String name) async {
    await ProjectRepo().deleteCollection(name);
    names.remove(name);
    membershipVersion++;
  }
}

/// The single global instance — read/act on this directly (not via
/// Provider); see [CollectionsStore]'s doc for why.
final collectionsStore = CollectionsStore();
