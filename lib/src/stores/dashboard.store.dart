import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

enum ProjectSortBy { name, size }

class DashboardStore {
  DashboardStore() {
    loadProjects();
  }

  final ObservableList<ProjectItemStore> items =
      ObservableList<ProjectItemStore>();

  final Observable<bool> _isRefreshing = Observable(false);
  bool get isRefreshing => _isRefreshing.value;

  final Observable<ProjectSortBy> _sortBy = Observable(ProjectSortBy.name);
  ProjectSortBy get sortBy => _sortBy.value;

  final Observable<bool> _sortAscending = Observable(true);
  bool get sortAscending => _sortAscending.value;

  void setSortBy(ProjectSortBy value) {
    runInAction(() {
      if (_sortBy.value == value) {
        _sortAscending.value = !_sortAscending.value;
      } else {
        _sortBy.value = value;
        _sortAscending.value = true;
      }
    });
  }

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

  int get totalBytes =>
      items.fold(0, (sum, item) => sum + (item.size?.totalBytes ?? 0));
  int get coreBytes =>
      items.fold(0, (sum, item) => sum + (item.size?.baseBytes ?? 0));
  int get cacheBytes =>
      items.fold(0, (sum, item) => sum + (item.size?.cacheBytes ?? 0));

  Future<void> loadProjects({bool forceRefresh = false}) async {
    final projects = await ProjectRepo().getProjects();
    runInAction(() {
      items
        ..clear()
        ..addAll(projects.map((project) =>
            ProjectItemStore(project, forceRefresh: forceRefresh)));
    });
  }

  Future<void> refreshAll() async {
    runInAction(() => _isRefreshing.value = true);
    await loadProjects(forceRefresh: true);
    runInAction(() => _isRefreshing.value = false);
  }
}
