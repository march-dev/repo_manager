import 'dart:io';

import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'explorer.store.g.dart';

enum ExplorerGrouping { none, byFolder, byCollection }

// Sentinel groupedByCollection key for projects that aren't in any
// collection — an empty string can never collide with a real collection
// name, since CollectionsStore.createCollection rejects blank/whitespace
// names.
const uncategorizedCollectionKey = '';

class ExplorerStore = _ExplorerStoreBase with _$ExplorerStore;

abstract class _ExplorerStoreBase with Store {
  _ExplorerStoreBase() {
    loadProjects().then((_) => _loadSubPackagesInBackground());
    grouping = ProjectRepo().getExplorerGrouping();
    pinFavourites = ProjectRepo().getExplorerPinFavourites();
  }

  @observable
  ObservableList<ProjectModel> projects = ObservableList<ProjectModel>();

  @action
  Future<void> loadProjects() async {
    final loaded = await ProjectRepo().getProjects();
    projects
      ..clear()
      ..addAll(loaded);
  }

  // getProjects() deliberately leaves a monorepo's member-package tree
  // unloaded so the list above shows up immediately — this fills each one
  // in afterwards, throttled the same way size calculation/cleanup are
  // elsewhere in the app, updating that project's row (and thus its
  // MonorepoBadge's count) in place as each one finishes.
  @action
  Future<void> _loadSubPackagesInBackground() async {
    final pending =
        projects.where((project) => !project.subPackagesLoaded).toList();

    await runWithConcurrency(
      [
        for (final project in pending)
          () async {
            final updated = await ProjectRepo().loadSubPackages(project);
            final index = projects.indexWhere((p) => p.path == updated.path);
            if (index != -1) projects[index] = updated;
          },
      ],
      concurrency: Platform.numberOfProcessors,
    );
  }

  @observable
  ExplorerGrouping grouping = ExplorerGrouping.none;

  @action
  Future<void> setGrouping(ExplorerGrouping value) async {
    grouping = value;
    await ProjectRepo().setExplorerGrouping(value);
  }

  @observable
  bool pinFavourites = true;

  @action
  Future<void> togglePinFavourites() async {
    pinFavourites = !pinFavourites;
    await ProjectRepo().setExplorerPinFavourites(pinFavourites);
  }

  @observable
  bool sortAscending = true;

  @action
  void toggleNameSort() => sortAscending = !sortAscending;

  @observable
  String searchQuery = '';

  @action
  void setSearchQuery(String value) => searchQuery = value;

  // When pinFavourites is on, favourites come first (both in the flat list
  // and within each folder group below), alphabetical among themselves;
  // everyone else follows, also alphabetical. When it's off, favourite
  // status is ignored entirely and everything sorts by name together.
  @computed
  List<ProjectModel> get visibleProjects {
    final sorted = projects
        .where((project) => fuzzyMatch(searchQuery, project.name))
        .toList();
    sorted.sort((a, b) {
      if (pinFavourites && a.favourite != b.favourite) {
        return a.favourite ? -1 : 1;
      }
      final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return sortAscending ? comparison : -comparison;
    });
    return sorted;
  }

  // Directory path -> its projects, used when grouping is enabled. Grouped
  // by the search directory each project was discovered under (see
  // ProjectModel.sourceDir); order within each group follows visibleProjects,
  // so favourites stay pinned first inside each folder group too.
  @computed
  Map<String, List<ProjectModel>> get groupedProjects {
    final grouped = <String, List<ProjectModel>>{};
    for (final project in visibleProjects) {
      grouped.putIfAbsent(project.sourceDir, () => []).add(project);
    }
    return grouped;
  }

  // Collection name -> its projects (a project in several collections
  // appears in several groups; one with none goes under
  // uncategorizedCollectionKey). Every known collection gets an entry up
  // front — even an empty one — so it still gets a section header to
  // right-click rename/delete on; otherwise a collection with nothing in
  // it (yet, or any more) would be invisible and unreachable in this view.
  // Membership itself lives in ProjectRepo, not on ProjectModel, so this
  // also depends on collectionsStore.membershipVersion to know when to
  // recompute.
  @computed
  Map<String, List<ProjectModel>> get groupedByCollection {
    // Read purely to establish the MobX dependency above.
    collectionsStore.membershipVersion;

    final grouped = <String, List<ProjectModel>>{
      for (final name in collectionsStore.names) name: <ProjectModel>[],
    };
    for (final project in visibleProjects) {
      final names = ProjectRepo().getProjectCollections(project.path);
      if (names.isEmpty) {
        grouped.putIfAbsent(uncategorizedCollectionKey, () => []).add(project);
      } else {
        for (final name in names) {
          grouped.putIfAbsent(name, () => []).add(project);
        }
      }
    }
    return grouped;
  }

  @action
  Future<void> toggleFavourite(ProjectModel project) async {
    await ProjectRepo().toggleFavoriteProject(project.path);
    final index = projects.indexWhere((p) => p.path == project.path);
    if (index == -1) return;
    projects[index] = project.copyWith(favourite: !project.favourite);
  }

  Future<void> openProject(ProjectModel project) {
    return ProjectRepo().openInEditor(project);
  }
}
