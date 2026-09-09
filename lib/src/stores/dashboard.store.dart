import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'dashboard.store.g.dart';

enum ProjectSortBy { name, size }

class DashboardStore = _DashboardStoreBase with _$DashboardStore;

abstract class _DashboardStoreBase with Store {
  _DashboardStoreBase() {
    loadProjects();
  }

  @observable
  ObservableList<ProjectItemStore> items = ObservableList<ProjectItemStore>();
  @computed
  int get totalBytes =>
      items.fold(0, (sum, item) => sum + (item.size?.totalBytes ?? 0));
  @computed
  int get coreBytes =>
      items.fold(0, (sum, item) => sum + (item.size?.baseBytes ?? 0));
  @computed
  int get cacheBytes =>
      items.fold(0, (sum, item) => sum + (item.size?.cacheBytes ?? 0));
  @action
  Future<void> loadProjects({bool forceRefresh = false}) async {
    final projects = await ProjectRepo().getProjects();
    items
      ..clear()
      ..addAll(projects.map(
          (project) => ProjectItemStore(project, forceRefresh: forceRefresh)));
  }

  @observable
  bool sortAscending = true;
  @observable
  ProjectSortBy sortBy = ProjectSortBy.name;
  @action
  void setSortBy(ProjectSortBy value) {
    if (sortBy == value) {
      sortAscending = !sortAscending;
    } else {
      sortBy = value;
      sortAscending = true;
    }
  }

  @computed
  List<ProjectItemStore> get sortedItems {
    final sorted = items.toList();

    switch (sortBy) {
      case ProjectSortBy.name:
        sorted.sort(
          (a, b) => a.project.name
              .toLowerCase()
              .compareTo(b.project.name.toLowerCase()),
        );
      case ProjectSortBy.size:
        sorted.sort(
          (a, b) =>
              (a.size?.totalBytes ?? 0).compareTo(b.size?.totalBytes ?? 0),
        );
    }

    return sortAscending ? sorted : sorted.reversed.toList();
  }

  @observable
  bool isRefreshing = false;
  @action
  Future<void> refreshAll() async {
    isRefreshing = true;
    await loadProjects(forceRefresh: true);
    isRefreshing = false;
  }
}
