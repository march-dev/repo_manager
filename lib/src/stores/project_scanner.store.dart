import '../../repo_manager.dart';

/// UI-facing proxy for [ProjectScanner], used only by
/// project_details.screen.dart's dialog: it needs to load one project's own
/// monorepo member-package tree, but the dialog is a route pushed outside
/// the app's Provider subtree, so it can't reach ExplorerStore/StorageStore
/// (which each load a whole project *list*, not a single one anyway) via
/// `context.read`. Registered as a plain `Provider<ProjectScannerStore>` in
/// _RootScaffold's MultiProvider (app.dart); whichever Provider-reachable
/// call site opens the dialog reads it via `context.read` and passes it
/// into `showProjectDetailsDialog` explicitly, since the dialog itself
/// can't reach it that way.
class ProjectScannerStore {
  const ProjectScannerStore(this._scanner, this._l10n);

  final ProjectScanner _scanner;
  final AppLocalizations _l10n;

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
      // Marks the tree "loaded" (as empty) anyway, rather than project
      // unchanged — otherwise the dialog would show a perpetual loading
      // spinner for a load that already failed and isn't retrying.
      return project.copyWith(subPackagesLoaded: true);
    }
  }
}
