import 'dart:io';

import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'storage.store.g.dart';

enum ProjectSortBy { name, size }

class StorageStore = _StorageStoreBase with _$StorageStore;

abstract class _StorageStoreBase with Store {
  _StorageStoreBase() {
    loadProjects();
    sortBy = ProjectRepo().getStorageSortBy();
    sortAscending = ProjectRepo().getStorageSortAscending();
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
    ProjectRepo().setStorageSortBy(sortBy);
    ProjectRepo().setStorageSortAscending(sortAscending);
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

  @observable
  bool cleaningAll = false;
  @action
  Future<void> cleanupAll() async {
    cleaningAll = true;
    // Running every project's cleanup at once could spin up dozens of
    // `flutter clean`/deletion tasks simultaneously — cap it to the number
    // of available processors instead, a reasonable stand-in for how much
    // this machine can actually do in parallel.
    await runWithConcurrency(
      [for (final item in items) item.cleanup],
      concurrency: Platform.numberOfProcessors,
    );
    cleaningAll = false;
  }
}
