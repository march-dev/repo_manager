import 'package:hive_flutter/hive_flutter.dart';

import '../../repo_manager.dart';

/// The small, standalone UI preferences persisted across launches —
/// preferred IDE per language group, Explorer's grouping/pin-favourites
/// toggles, Storage's sort order. Grouped together because each is just a
/// trivial key-value read/write with no logic of its own, unlike the
/// other split-out repos (scanning, icons, sizing, ...).
class AppSettingsRepo {
  const AppSettingsRepo({required Box box}) : _box = box;

  final Box _box;

  String _preferredIdeKey(LanguageGroup group) => 'preferredIde:${group.name}';

  Ide getPreferredIde(LanguageGroup group) {
    final raw = _box.get(_preferredIdeKey(group)) as String?;
    // Validated against candidatesOnHost, not the full candidateIdes —
    // a preference saved on a different host (e.g. Visual Studio, saved
    // on Windows, synced into this same box on a Mac) shouldn't win here
    // just because it's still a nominal candidate for the group; it can't
    // actually launch on this host, so this falls through to defaultIde
    // exactly as if nothing had been saved.
    for (final ide in group.candidatesOnHost) {
      if (ide.name == raw) return ide;
    }
    return group.defaultIde;
  }

  Future<void> setPreferredIde(LanguageGroup group, Ide ide) async {
    await _box.put(_preferredIdeKey(group), ide.name);
  }

  static const _explorerPinFavouritesKey = 'explorerPinFavouritesKey';

  bool getExplorerPinFavourites() =>
      (_box.get(_explorerPinFavouritesKey) as bool?) ?? true;

  Future<void> setExplorerPinFavourites(bool value) async {
    await _box.put(_explorerPinFavouritesKey, value);
  }

  static const _explorerGroupingKey = 'explorerGroupingKey';

  ExplorerGrouping getExplorerGrouping() {
    final raw = _box.get(_explorerGroupingKey) as String?;
    return ExplorerGrouping.values.firstWhere(
      (grouping) => grouping.name == raw,
      orElse: () => ExplorerGrouping.none,
    );
  }

  Future<void> setExplorerGrouping(ExplorerGrouping grouping) async {
    await _box.put(_explorerGroupingKey, grouping.name);
  }

  static const _storageSortByKey = 'storageSortByKey';

  ProjectSortBy getStorageSortBy() {
    final raw = _box.get(_storageSortByKey) as String?;
    return ProjectSortBy.values.firstWhere(
      (sortBy) => sortBy.name == raw,
      orElse: () => ProjectSortBy.name,
    );
  }

  Future<void> setStorageSortBy(ProjectSortBy sortBy) async {
    await _box.put(_storageSortByKey, sortBy.name);
  }

  static const _storageSortAscendingKey = 'storageSortAscendingKey';

  bool getStorageSortAscending() =>
      (_box.get(_storageSortAscendingKey) as bool?) ?? true;

  Future<void> setStorageSortAscending(bool value) async {
    await _box.put(_storageSortAscendingKey, value);
  }
}
