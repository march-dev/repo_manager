import 'dart:io';

import 'package:mobx/mobx.dart';

import '../../repo_manager.dart';

part 'system_cleaner_state.g.dart';

class SystemCleanerState = _SystemCleanerStateBase with _$SystemCleanerState;

/// Reactive UI state for system_cleaner.screen.dart — [_scan]/[cleanSelected]
/// delegate the actual filesystem work to [SystemCleanerUseCases]
/// (SystemCleanerRepo does the real per-platform walk/delete); this only
/// tracks what the screen needs to observe and re-render on. See
/// test/system_cleaner_screen_test.dart for a fixture that seeds this
/// state directly with realistic category/entry data, for exercising the
/// screen's rendering independent of whatever caches genuinely exist on
/// the machine running the test.
///
/// A group (see CleanerCategory) is only ever shown once it has at least
/// one entry — "only if exists" per the app's own per-language/per-tool
/// groups (npm, Dart Related, Xcode Related, Gradle Related, C#, C++, Go,
/// PHP, Rust, Python, Game Engines Related, Docker Related), plus a
/// catch-all System group that's always eligible to show.
abstract class _SystemCleanerStateBase with Store {
  _SystemCleanerStateBase({required SystemCleanerUseCases useCases})
      : _useCases = useCases {
    _loadThenRefresh();
  }

  final SystemCleanerUseCases _useCases;

  // True only until the very first scan (cache-hit or not) resolves —
  // guards _Body's blocking skeleton for a genuinely cold start, same
  // as StorageState never re-blocking its own list on a later refresh.
  @observable
  bool scanning = true;

  // Drives the header's refresh icon — true for every scan below
  // (including the initial one), not just a manual rescan, so the icon
  // reflects "a scan is genuinely in flight" the whole time rather than
  // just the cold-start/background distinction _Body itself cares about.
  @observable
  bool isRefreshing = false;

  @observable
  ObservableList<CleanerCategory> categories =
      ObservableList<CleanerCategory>();

  @observable
  ObservableSet<String> selectedPaths = ObservableSet<String>();

  @observable
  bool cleaning = false;

  // Shows cached sizes immediately (forceRefresh: false — see
  // SystemCleanerRepo.scan's own doc), then silently recomputes the real,
  // current ones in the background once that's done — same shape as
  // StorageState's own load-then-refresh — so a cache that's grown/shrunk
  // since the last scan doesn't keep showing a stale number until the
  // user happens to hit rescan.
  Future<void> _loadThenRefresh() async {
    await _scan(forceRefresh: false);
    await _scan(forceRefresh: true);
  }

  // Always a forced rescan — a manual refresh (the header's own icon, or
  // F5) is exactly when a stale cached size is worth actually redoing the
  // walk for, the same reasoning StorageState's own refreshAll forces a
  // fresh recompute rather than serving whatever's cached.
  Future<void> rescan() => _scan(forceRefresh: true);

  @action
  Future<void> _scan({required bool forceRefresh}) async {
    isRefreshing = true;
    // Null means the scan itself failed (see SystemCleanerUseCases.scan's
    // own doc) — keep whatever this last showed rather than clearing it
    // to empty.
    final scanned = await _useCases.scan(forceRefresh: forceRefresh);

    runInAction(() {
      if (scanned != null) {
        categories
          ..clear()
          ..addAll(scanned.map(_withEntriesSortedByName));
        selectedPaths
          ..clear()
          ..addAll(
            categories
                .expand((c) => c.entries)
                .where((e) => e.defaultSelected)
                .map((e) => e.path),
          );
      }
      scanning = false;
      isRefreshing = false;
    });
  }

  @computed
  int get totalBytes => categories
      .expand((c) => c.entries)
      .fold(0, (sum, entry) => sum + entry.sizeBytes);

  @computed
  int get selectedBytes => categories
      .expand((c) => c.entries)
      .where((entry) => selectedPaths.contains(entry.path))
      .fold(0, (sum, entry) => sum + entry.sizeBytes);

  // Pinned groups (System) always lead, in whatever order they were
  // found in; everyone else follows, largest reclaimable total first —
  // recomputed off [categories] rather than sorted in place there, so a
  // partial clean's own removeAt/index-based rebuild (see cleanSelected)
  // never has to account for a reordered list.
  @computed
  List<CleanerCategory> get sortedCategories {
    final pinned = categories.where((c) => c.pinned).toList();
    final rest = categories.where((c) => !c.pinned).toList()
      ..sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
    return [...pinned, ...rest];
  }

  bool isEntrySelected(CleanerEntry entry) =>
      selectedPaths.contains(entry.path);

  bool isCategoryFullySelected(CleanerCategory category) =>
      category.entries.every((entry) => selectedPaths.contains(entry.path));

  bool isCategoryPartiallySelected(CleanerCategory category) =>
      category.entries.any((entry) => selectedPaths.contains(entry.path));

  @action
  void toggleEntry(CleanerEntry entry) {
    if (!selectedPaths.remove(entry.path)) selectedPaths.add(entry.path);
  }

  @action
  void toggleCategory(CleanerCategory category) {
    final selectAll = !isCategoryFullySelected(category);
    for (final entry in category.entries) {
      if (selectAll) {
        selectedPaths.add(entry.path);
      } else {
        selectedPaths.remove(entry.path);
      }
    }
  }

  // Deletes every selected entry's own path(s) first (concurrently, same
  // throttling as ExplorerState's own background fill-in), and only then
  // drops the ones that actually succeeded from the list below — a
  // failure partway through (a permission error, something already
  // mid-use by another process) leaves that one entry showing, still
  // selected, so the list keeps reflecting what's genuinely still on
  // disk rather than assuming every deletion worked.
  @action
  Future<void> cleanSelected() async {
    cleaning = true;

    final selectedEntries = categories
        .expand((c) => c.entries)
        .where((entry) => selectedPaths.contains(entry.path))
        .toList();

    final deletedPaths = <String>{};
    await runWithConcurrency(
      [
        for (final entry in selectedEntries)
          () async {
            if (await _useCases.cleanEntry(entry)) {
              deletedPaths.add(entry.path);
            }
          },
      ],
      concurrency: Platform.numberOfProcessors,
    );

    runInAction(() {
      for (var i = categories.length - 1; i >= 0; i--) {
        final category = categories[i];
        final remaining = category.entries
            .where((entry) => !deletedPaths.contains(entry.path))
            .toList();
        if (remaining.length == category.entries.length) continue;
        if (remaining.isEmpty) {
          categories.removeAt(i);
        } else {
          categories[i] = CleanerCategory(
            id: category.id,
            icon: category.icon,
            language: category.language,
            iconAssetPath: category.iconAssetPath,
            title: category.title,
            entries: remaining,
            pinned: category.pinned,
          );
        }
      }
      selectedPaths.removeWhere(deletedPaths.contains);
      cleaning = false;
    });
  }

  // Applied once per category in _scan() — inside a card, entries read
  // better alphabetically than in whatever order the real filesystem
  // walk happens to discover them, the same way the categories
  // themselves (see sortedCategories) get their own ordering imposed
  // rather than shown in scan order.
  CleanerCategory _withEntriesSortedByName(CleanerCategory category) {
    final sorted = [...category.entries]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return CleanerCategory(
      id: category.id,
      icon: category.icon,
      language: category.language,
      iconAssetPath: category.iconAssetPath,
      title: category.title,
      pinned: category.pinned,
      entries: sorted,
    );
  }
}
