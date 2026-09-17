import 'dart:async';
import 'dart:io';

import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'storage_state.g.dart';

enum ProjectSortBy { name, size }

class StorageState = _StorageStateBase with _$StorageState;

/// Reactive UI state for Storage's screen (and Dashboard's own reclaimable-
/// storage stat, which reads the same live size data — see _RootScaffold
/// in app.dart, which provides this above both screens). All the actual
/// business logic lives in the relevant use-case class; this only tracks
/// what the UI needs to observe and re-render on.
abstract class _StorageStateBase with Store {
  _StorageStateBase({
    required ProjectScannerUseCases projectScannerUseCases,
    required AppSettingsUseCases appSettingsUseCases,
    required ProjectSizeUseCases projectSizeUseCases,
    required IdeLauncherUseCases ideLauncherUseCases,
  })  : _projectScannerUseCases = projectScannerUseCases,
        _appSettingsUseCases = appSettingsUseCases,
        _projectSizeUseCases = projectSizeUseCases,
        _ideLauncherUseCases = ideLauncherUseCases {
    // Shows cached sizes immediately (loadProjects defaults to
    // forceRefresh: false), then silently recomputes the real ones in the
    // background once that's done — so a project whose cache/build output
    // grew since the last launch doesn't keep showing a stale number until
    // someone happens to hit refresh. Loading each monorepo's own member-
    // package tree (for the MonorepoBadge's count) runs the same way, in
    // parallel with the size refresh rather than blocking it.
    loadProjects().then((_) {
      refreshSizesInBackground();
      _loadSubPackagesInBackground();
    });
    sortBy = _appSettingsUseCases.getStorageSortBy();
    sortAscending = _appSettingsUseCases.getStorageSortAscending();
  }

  final ProjectScannerUseCases _projectScannerUseCases;
  final AppSettingsUseCases _appSettingsUseCases;
  final ProjectSizeUseCases _projectSizeUseCases;
  final IdeLauncherUseCases _ideLauncherUseCases;

  @observable
  ObservableList<ProjectItemState> items = ObservableList<ProjectItemState>();
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
    final projects = await _projectScannerUseCases.getProjects();
    if (projects == null) return;

    final newItems = [
      for (final project in projects)
        ProjectItemState(
          project,
          projectSizeUseCases: _projectSizeUseCases,
          ideLauncherUseCases: _ideLauncherUseCases,
        ),
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

  // getProjects() deliberately leaves a monorepo's member-package tree
  // unloaded so the list above shows up immediately — this fills each one
  // in afterwards, throttled the same way size calculation/cleanup are,
  // updating that item's own project (and thus its MonorepoBadge's count)
  // in place as each one finishes.
  @action
  Future<void> _loadSubPackagesInBackground() async {
    final pending =
        items.where((item) => !item.project.subPackagesLoaded).toList();

    await runWithConcurrency(
      [
        for (final item in pending)
          () async {
            final updated =
                await _projectScannerUseCases.loadSubPackages(item.project);
            item.updateProject(updated);
          },
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
    _appSettingsUseCases.saveStorageSortPrefs(sortBy, sortAscending);
  }

  @computed
  List<ProjectItemState> get sortedItems {
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
    // loadProjects rebuilds items from scratch, so every monorepo's tree
    // needs re-fetching too — same as the initial background load.
    unawaited(_loadSubPackagesInBackground());
  }

  @observable
  bool cleaningAll = false;
  @action
  Future<void> cleanupAll() async {
    cleaningAll = true;
    // Running every project's cleanup at once could spin up dozens of
    // `flutter clean`/deletion tasks simultaneously — cap it to the number
    // of available processors instead, a reasonable stand-in for how much
    // this machine can actually do in parallel. Each item's own cleanup()
    // already catches and reports its own failure, so one project's
    // cleanup failing doesn't stop the rest from being attempted.
    await runWithConcurrency(
      [for (final item in items) item.cleanup],
      concurrency: Platform.numberOfProcessors,
    );
    cleaningAll = false;
  }
}
