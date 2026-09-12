import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'explorer.store.g.dart';

enum ExplorerGrouping { none, byFolder }

class ExplorerStore = _ExplorerStoreBase with _$ExplorerStore;

abstract class _ExplorerStoreBase with Store {
  _ExplorerStoreBase() {
    loadProjects();
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

  // When pinFavourites is on, favourites come first (both in the flat list
  // and within each folder group below), alphabetical among themselves;
  // everyone else follows, also alphabetical. When it's off, favourite
  // status is ignored entirely and everything sorts by name together.
  @computed
  List<ProjectModel> get visibleProjects {
    final sorted = projects.toList();
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

  @action
  Future<void> toggleFavourite(ProjectModel project) async {
    await ProjectRepo().toggleFavoriteProject(project.path);
    final index = projects.indexWhere((p) => p.path == project.path);
    if (index == -1) return;
    projects[index] = project.copyWith(favourite: !project.favourite);
  }

  Future<void> openProject(ProjectModel project) {
    return ProjectRepo().openInEditor(project.path, project.language);
  }
}
