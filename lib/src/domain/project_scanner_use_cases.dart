import '../../repo_manager.dart';

/// Business logic for scanning/loading projects, shared by every screen
/// state that needs its own project list (ExplorerState, StorageState) and
/// by project_details.screen.dart's dialog (which needs to load a single
/// monorepo's own member-package tree, on demand, outside of either
/// screen's own load cycle). Centralizing the getProjects()/loadSubPackages
/// failure handling here means each of those callers doesn't repeat its
/// own try/catch for the same two calls.
class ProjectScannerUseCases {
  const ProjectScannerUseCases(this._scanner, this._l10n);

  final ProjectScanner _scanner;
  final AppLocalizations _l10n;

  /// Returns null (rather than throwing) on failure — the caller keeps
  /// whatever project list it already had rather than clearing it out.
  Future<List<ProjectModel>?> getProjects() async {
    try {
      return await _scanner.getProjects();
    } on Object catch (error, stackTrace) {
      logError('Load projects', error, stackTrace);
      SnackbarManager.show(_l10n.errorLoadProjects);
      return null;
    }
  }

  // getProjects() deliberately leaves a monorepo's member-package tree
  // unloaded so the caller's list shows up immediately — this fills one in
  // on demand. Marks subPackagesLoaded regardless of success so a caller's
  // loading state (e.g. a badge/spinner) doesn't spin forever over a scan
  // that failed.
  Future<ProjectModel> loadSubPackages(
    ProjectModel project, {
    bool forceRefresh = false,
  }) async {
    try {
      return await _scanner.loadSubPackages(project,
          forceRefresh: forceRefresh);
    } on Object catch (error, stackTrace) {
      logError('Load sub-packages for "${project.name}"', error, stackTrace);
      SnackbarManager.show(_l10n.errorLoadSubPackages(project.name));
      return project.copyWith(subPackagesLoaded: true);
    }
  }
}
