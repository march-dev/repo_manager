import 'package:mobx/mobx.dart';

import '../../repo_manager.dart';

part 'system_cleaner_state.g.dart';

class SystemCleanerState = _SystemCleanerStateBase with _$SystemCleanerState;

/// Reactive UI state for system_cleaner.screen.dart. [_scan] doesn't do a
/// real per-platform filesystem walk yet — it always finds nothing, until
/// that's built — so the live app currently shows this screen's empty
/// state; see test/system_cleaner_screen_test.dart for a fixture that
/// seeds this state directly with realistic category/entry data to
/// exercise the screen's actual rendering in the meantime.
///
/// A group (see CleanerCategory) is only ever shown once it has at least
/// one entry — "only if exists" per the app's own per-language/per-tool
/// groups (npm, Dart Related, Xcode Related, Gradle Related, C#, C++, Go,
/// PHP, Rust, Python, Game Engines Related, Docker Related), plus a
/// catch-all System group that's always eligible to show.
abstract class _SystemCleanerStateBase with Store {
  _SystemCleanerStateBase() {
    _scan();
  }

  @observable
  bool scanning = true;

  @observable
  ObservableList<CleanerCategory> categories =
      ObservableList<CleanerCategory>();

  @observable
  ObservableSet<String> selectedPaths = ObservableSet<String>();

  @observable
  bool cleaning = false;

  Future<void> rescan() => _scan();

  @action
  Future<void> _scan() async {
    scanning = true;
    // TODO: a real per-platform filesystem walk (Xcode DerivedData,
    // ~/.pub-cache, ~/.gradle/caches, ...) — see this class's own doc.
    // Always empty until then; _withEntriesSortedByName is still applied
    // here so a real implementation only has to populate this list, not
    // also remember to sort it.
    await Future.delayed(const Duration(milliseconds: 500));
    final found = const <CleanerCategory>[].map(_withEntriesSortedByName);

    runInAction(() {
      categories
        ..clear()
        ..addAll(found);
      selectedPaths
        ..clear()
        ..addAll(
          categories
              .expand((c) => c.entries)
              .where((e) => e.defaultSelected)
              .map((e) => e.path),
        );
      scanning = false;
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

  // Schematic only — removes the selected entries from view rather than
  // touching the filesystem. A real implementation deletes each selected
  // path first and only then drops it here, so a failure partway through
  // still leaves the list showing what's genuinely still on disk.
  @action
  Future<void> cleanSelected() async {
    cleaning = true;
    await Future.delayed(const Duration(milliseconds: 600));

    runInAction(() {
      for (var i = categories.length - 1; i >= 0; i--) {
        final category = categories[i];
        final remaining = category.entries
            .where((entry) => !selectedPaths.contains(entry.path))
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
      selectedPaths.clear();
      cleaning = false;
    });
  }

  // Applied once per category in _scan() — inside a card, entries read
  // better alphabetically than in whatever order a real filesystem walk
  // happens to discover them, the same way the categories themselves
  // (see sortedCategories) get their own ordering imposed rather than
  // shown in scan order.
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
