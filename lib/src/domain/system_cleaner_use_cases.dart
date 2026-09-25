import '../../repo_manager.dart';

/// Business logic for System Cleaner's real per-platform scan/clean —
/// wraps [SystemCleanerRepo] with the same "log and surface a snackbar
/// rather than throw" error handling every other use-case in this app
/// uses.
class SystemCleanerUseCases {
  const SystemCleanerUseCases(this._repo, this._l10n);

  final SystemCleanerRepo _repo;
  final AppLocalizations _l10n;

  /// Returns null (rather than throwing) on failure — the caller keeps
  /// whatever it last showed rather than clearing it to nothing.
  Future<List<CleanerCategory>?> scan({bool forceRefresh = false}) async {
    try {
      return await _repo.scan(forceRefresh: forceRefresh);
    } catch (error, stackTrace) {
      logError('Scan for reclaimable caches', error, stackTrace);
      SnackbarManager.show(_l10n.errorScanSystemCleaner);
      return null;
    }
  }

  /// Returns null (rather than throwing) on failure — the caller leaves
  /// this entry's own shimmer/last-known size as-is rather than treating
  /// a failed recompute as "genuinely empty, drop it".
  Future<int?> computeEntrySize(CleanerEntry entry) async {
    try {
      return await _repo.computeEntrySize(entry);
    } catch (error, stackTrace) {
      logError('Compute size for "${entry.name}"', error, stackTrace);
      SnackbarManager.show(_l10n.errorComputeEntrySize(entry.name));
      return null;
    }
  }

  Future<bool> cleanEntry(CleanerEntry entry) async {
    try {
      await _repo.deleteEntry(entry);
      return true;
    } catch (error, stackTrace) {
      logError('Clean up "${entry.name}"', error, stackTrace);
      SnackbarManager.show(_l10n.errorCleanSystemCleanerEntry(entry.name));
      return false;
    }
  }
}
