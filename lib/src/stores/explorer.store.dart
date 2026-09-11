import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'explorer.store.g.dart';

enum ExplorerLayout { list, grid }

enum ExplorerGrouping { none, byFolder }

class ExplorerStore = _ExplorerStoreBase with _$ExplorerStore;

abstract class _ExplorerStoreBase with Store {
  _ExplorerStoreBase() {
    loadProjects();
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
  ExplorerLayout layout = ExplorerLayout.list;

  @action
  void cycleLayout() {
    const values = ExplorerLayout.values;
    layout = values[(layout.index + 1) % values.length];
  }

  @observable
  ExplorerGrouping grouping = ExplorerGrouping.none;

  @action
  void cycleGrouping() {
    const values = ExplorerGrouping.values;
    grouping = values[(grouping.index + 1) % values.length];
  }

  @observable
  bool favouritesOnly = false;

  @action
  void toggleFavouritesOnly() => favouritesOnly = !favouritesOnly;

  // Favourites are pinned first (both in the flat list/grid and within each
  // folder group below), alphabetically among themselves; everyone else
  // follows, also alphabetical.
  @computed
  List<ProjectModel> get visibleProjects {
    final filtered = favouritesOnly
        ? projects.where((project) => project.favourite).toList()
        : projects.toList();
    filtered.sort((a, b) {
      if (a.favourite != b.favourite) return a.favourite ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return filtered;
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
    return ProjectRepo().openInVsCode(project.path);
  }
}
