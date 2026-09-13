import 'dart:io';

import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'storage.store.g.dart';

enum ProjectSortBy { name, size }

class StorageStore = _StorageStoreBase with _$StorageStore;

abstract class _StorageStoreBase with Store {
  _StorageStoreBase() {
    // Shows cached sizes immediately (loadProjects defaults to
    // forceRefresh: false), then silently recomputes the real ones in the
    // background once that's done — so a project whose cache/build output
    // grew since the last launch doesn't keep showing a stale number until
    // someone happens to hit refresh.
    loadProjects().then((_) => refreshSizesInBackground());
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
  // The largest single project's total size currently known — each row's
  // SizeBar scales its width relative to this, so the bar's length itself
  // reads as a size comparison across the list, not just this project's
  // own core:cache ratio.
  @computed
  int get maxProjectTotalBytes {
    var max = 0;
    for (final item in items) {
      final total = item.size?.totalBytes ?? 0;
      if (total > max) max = total;
    }
    return max;
  }

  @action
  Future<void> loadProjects({bool forceRefresh = false}) async {
    final projects = await ProjectRepo().getProjects();
    final newItems = [
      for (final project in projects) ProjectItemStore(project)
    ];
    items
      ..clear()
      ..addAll(newItems);

    // Same throttling as refreshSizesInBackground/cleanupAll, so every
    // place sizes get (re)computed behaves consistently instead of this
    // one firing all of them at once via each item's own constructor.
    await runWithConcurrency(
      [
        for (final item in newItems)
          () => item.loadSize(forceRefresh: forceRefresh)
      ],
      concurrency: Platform.numberOfProcessors,
    );
  }

  // Recomputes every currently-listed project's real size, throttled the
  // same way cleanupAll is — one recursive directory walk per project is
  // real filesystem work, so this caps how many run at once rather than
  // firing them all simultaneously. Drives the same isRefreshing flag the
  // manual refresh button does, so it spins/disables for this too.
  @action
  Future<void> refreshSizesInBackground() async {
    isRefreshing = true;
    await runWithConcurrency(
      [for (final item in items) item.refreshInBackground],
      concurrency: Platform.numberOfProcessors,
    );
    isRefreshing = false;
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
