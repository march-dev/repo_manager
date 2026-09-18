import '../../repo_manager.dart';

/// Business logic for the small standalone UI preferences persisted across
/// launches — preferred IDE per language group, Explorer's grouping/pin-
/// favourites toggles, Storage's sort order. Every write here is just a
/// preference save that already applied in memory regardless of whether it
/// persists — so a failure is only worth logging, never worth a snackbar.
class AppSettingsUseCases {
  const AppSettingsUseCases(this._repo);

  final AppSettingsRepo _repo;

  Ide getPreferredIde(LanguageGroup group) => _repo.getPreferredIde(group);

  Future<void> setPreferredIde(LanguageGroup group, Ide ide) async {
    try {
      await _repo.setPreferredIde(group, ide);
    } catch (error, stackTrace) {
      logError('Save preferred IDE for ${group.name}', error, stackTrace);
    }
  }

  bool getExplorerPinFavourites() => _repo.getExplorerPinFavourites();

  Future<void> setExplorerPinFavourites(bool value) async {
    try {
      await _repo.setExplorerPinFavourites(value);
    } catch (error, stackTrace) {
      logError('Save pin-favourites preference', error, stackTrace);
    }
  }

  ExplorerGrouping getExplorerGrouping() => _repo.getExplorerGrouping();

  Future<void> setExplorerGrouping(ExplorerGrouping grouping) async {
    try {
      await _repo.setExplorerGrouping(grouping);
    } catch (error, stackTrace) {
      logError('Save explorer grouping preference', error, stackTrace);
    }
  }

  ProjectSortBy getStorageSortBy() => _repo.getStorageSortBy();

  bool getStorageSortAscending() => _repo.getStorageSortAscending();

  Future<void> saveStorageSortPrefs(
      ProjectSortBy sortBy, bool ascending) async {
    try {
      await _repo.setStorageSortBy(sortBy);
      await _repo.setStorageSortAscending(ascending);
    } catch (error, stackTrace) {
      logError('Save storage sort preference', error, stackTrace);
    }
  }
}
