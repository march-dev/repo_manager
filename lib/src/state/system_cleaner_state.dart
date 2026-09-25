import 'dart:io';

import 'package:mobx/mobx.dart';

import '../../repo_manager.dart';

part 'system_cleaner_state.g.dart';

class SystemCleanerState = _SystemCleanerStateBase with _$SystemCleanerState;

/// Reactive UI state for system_cleaner.screen.dart — [_scanStructure]/
/// [_computePendingSizes]/[cleanSelected] delegate the actual filesystem
/// work to [SystemCleanerUseCases] (SystemCleanerRepo does the real
/// per-platform walk/delete); this only tracks what the screen needs to
/// observe and re-render on. See test/system_cleaner_screen_test.dart
/// for a fixture that seeds this state directly with realistic
/// category/entry data, for exercising the screen's rendering
/// independent of whatever caches genuinely exist on the machine running
/// the test.
///
/// A group (see CleanerCategory) is only ever shown once it has at least
/// one entry — "only if exists" per the app's own per-language/per-tool
/// groups (npm, Dart Related, Xcode Related, Gradle Related, C#, C++, Go,
/// PHP, Rust, Python, Game Engines Related, Docker Related), plus a
/// catch-all System group that's always eligible to show.
abstract class _SystemCleanerStateBase with Store {
  _SystemCleanerStateBase({required SystemCleanerUseCases useCases})
      : _useCases = useCases {
    _loadInitial();
  }

  final SystemCleanerUseCases _useCases;

  // True only until the very first load (structure + every entry's own
  // size) fully resolves — guards _Body's blocking whole-page skeleton
  // for a genuinely cold start. Never true again afterwards: a later
  // [rescan] instead leaves the list up and shimmers only the sizes
  // still being recomputed (see [isRefreshing]/CleanerEntry.sizeBytes'
  // own docs) rather than blocking the whole page a second time.
  @observable
  bool scanning = true;

  // Drives the header's refresh icon during a manual [rescan] — the
  // initial load has its own [scanning] flag/skeleton instead, so this
  // stays false for it.
  @observable
  bool isRefreshing = false;

  @observable
  ObservableList<CleanerCategory> categories =
      ObservableList<CleanerCategory>();

  @observable
  ObservableSet<String> selectedPaths = ObservableSet<String>();

  @observable
  bool cleaning = false;

  // Resolves structure (forceRefresh: false — cached sizes filled in
  // where available) and computes every entry still missing a size
  // (nothing cached yet) before revealing anything — "loading" here
  // means the whole page's own shimmer skeleton (_CategoryListSkeleton),
  // same as before this ever had per-entry granularity. Followed by the
  // same background refresh [rescan] itself triggers, same reasoning as
  // StorageState's own load-then-refresh: showing cached sizes
  // immediately is only half the guarantee — this is what catches one
  // that's grown/shrunk since the cache was last written, without
  // holding up the initial reveal to do it.
  Future<void> _loadInitial() async {
    await _scanStructure(forceRefresh: false);
    await _computePendingSizes();
    scanning = false;
    await _refreshInBackground();
  }

  // Always a forced rescan (F5, or the header's own refresh icon) —
  // unlike the initial load, this doesn't block the page.
  Future<void> rescan() => _refreshInBackground();

  // [_scanStructure]'s forceRefresh: true immediately nulls every entry's
  // own size (see CleanerEntry.sizeBytes' own doc), which
  // _EntryRow/_CategoryHeaderRow show as a shimmer in place of the real
  // number, and [_computePendingSizes] then fills each one back in —
  // concurrently, each on its own isolate (see SystemCleanerRepo.
  // computeEntrySize's own doc) — the moment its own computation
  // finishes, independent of how long any other entry's own walk takes.
  @action
  Future<void> _refreshInBackground() async {
    if (isRefreshing) return;
    isRefreshing = true;
    await _scanStructure(forceRefresh: true);
    await _computePendingSizes();
    isRefreshing = false;
  }

  @action
  Future<void> _scanStructure({required bool forceRefresh}) async {
    // Null means the scan itself failed (see SystemCleanerUseCases.scan's
    // own doc) — keep whatever this last showed rather than clearing it
    // to empty.
    final scanned = await _useCases.scan(forceRefresh: forceRefresh);
    if (scanned == null) return;

    runInAction(() {
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
    });
  }

  // Concurrently computes every currently-listed entry whose size isn't
  // known yet (null — either never cached, or just nulled by
  // _scanStructure's own forced rescan above), applying each one the
  // moment ITS OWN computation finishes rather than waiting for the
  // whole batch — see SystemCleanerRepo.computeEntrySize's own doc for
  // why this is real, isolate-parallel work rather than one big
  // sequential walk.
  Future<void> _computePendingSizes() async {
    final pending = categories
        .expand((c) => c.entries)
        .where((entry) => entry.sizeBytes == null)
        .toList();

    await runWithConcurrency(
      [
        for (final entry in pending)
          () async {
            final sizeBytes = await _useCases.computeEntrySize(entry);
            // Null means the compute itself failed (see
            // SystemCleanerUseCases.computeEntrySize's own doc) — leave
            // this entry's row shimmering rather than guessing 0/dropping
            // it outright.
            if (sizeBytes != null) {
              runInAction(() => _applyEntrySize(entry, sizeBytes));
            }
          },
      ],
      concurrency: Platform.numberOfProcessors,
    );
  }

  // Splices [sizeBytes] back into whichever category still holds an
  // entry at [entry.path] (matched by path, not identity — a rescan in
  // between could have already replaced categories/entries with fresh
  // instances by the time this particular entry's own computation
  // resolves) — or, if [sizeBytes] is exactly 0, drops that entry
  // entirely, the same as SystemCleanerRepo.scan itself silently
  // dropping a path that resolves empty.
  void _applyEntrySize(CleanerEntry entry, int sizeBytes) {
    for (var i = 0; i < categories.length; i++) {
      final category = categories[i];
      final index = category.entries.indexWhere((e) => e.path == entry.path);
      if (index == -1) continue;

      final updatedEntries = [...category.entries];
      if (sizeBytes == 0) {
        updatedEntries.removeAt(index);
      } else {
        final stale = updatedEntries[index];
        updatedEntries[index] = CleanerEntry(
          name: stale.name,
          path: stale.path,
          sizeBytes: sizeBytes,
          extraPaths: stale.extraPaths,
          icon: stale.icon,
          iconAssetPath: stale.iconAssetPath,
          defaultSelected: stale.defaultSelected,
          safetyLevel: stale.safetyLevel,
          safetyReason: stale.safetyReason,
        );
      }

      if (updatedEntries.isEmpty) {
        categories.removeAt(i);
      } else {
        categories[i] = CleanerCategory(
          id: category.id,
          icon: category.icon,
          language: category.language,
          iconAssetPath: category.iconAssetPath,
          title: category.title,
          pinned: category.pinned,
          entries: updatedEntries,
        );
      }
      return;
    }
  }

  @computed
  int get totalBytes => categories
      .expand((c) => c.entries)
      .fold(0, (sum, entry) => sum + (entry.sizeBytes ?? 0));

  @computed
  int get selectedBytes => categories
      .expand((c) => c.entries)
      .where((entry) => selectedPaths.contains(entry.path))
      .fold(0, (sum, entry) => sum + (entry.sizeBytes ?? 0));

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

  // Applied once per category in _scanStructure() — inside a card, entries read
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
