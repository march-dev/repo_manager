import 'package:mobx/mobx.dart';

import '../../repo_manager.dart';

part 'collections_state.g.dart';

class CollectionsState = _CollectionsStateBase with _$CollectionsState;

/// Reactive UI state for the collections list — which names exist, and a
/// version counter that bumps on every membership change (see
/// [membershipVersion]). All the actual business logic (persisting a
/// create/rename/delete/toggle, plus its own failure handling) lives in
/// [CollectionsUseCases]; this class only tracks what the UI needs to
/// observe and re-render on.
///
/// Registered as a plain `Provider<CollectionsState>` in _RootScaffold's
/// MultiProvider (app.dart). showProjectContextMenu (where projects get
/// added to a collection) is also reachable from showProjectDetailsPage's
/// pushed route, which sits outside that Provider subtree — so that call
/// chain gets this instance passed in explicitly by whichever Provider-
/// reachable call site opened it, rather than reading it via `context.read`
/// itself.
abstract class _CollectionsStateBase with Store {
  _CollectionsStateBase(this._useCases) {
    names = ObservableList.of(_useCases.getCollectionNames());
  }

  final CollectionsUseCases _useCases;

  @observable
  ObservableList<String> names = ObservableList<String>();

  // Bumped on every membership change so a @computed elsewhere (e.g.
  // ExplorerState.groupedByCollection) can depend on this state for
  // reactivity, while still reading the actual project<->collection
  // mapping straight from CollectionsUseCases (via [getProjectCollections]
  // below) rather than this duplicating it.
  @observable
  int membershipVersion = 0;

  List<String> getProjectCollections(String projectPath) =>
      _useCases.getProjectCollections(projectPath);

  @action
  Future<void> createCollection(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || names.contains(trimmed)) return;
    if (await _useCases.createCollection(trimmed)) names.add(trimmed);
  }

  @action
  Future<void> toggleProjectCollection(
    String projectPath,
    String collectionName,
  ) async {
    if (await _useCases.toggleProjectCollection(projectPath, collectionName)) {
      membershipVersion++;
    }
  }

  // Merges into newName if a collection by that name already exists (see
  // CollectionsRepo.renameCollection) — either way, names ends up holding
  // exactly one entry for it afterwards.
  @action
  Future<void> renameCollection(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName) return;
    if (await _useCases.renameCollection(oldName, trimmed)) {
      names.remove(oldName);
      if (!names.contains(trimmed)) names.add(trimmed);
      membershipVersion++;
    }
  }

  @action
  Future<void> deleteCollection(String name) async {
    if (await _useCases.deleteCollection(name)) {
      names.remove(name);
      membershipVersion++;
    }
  }
}
