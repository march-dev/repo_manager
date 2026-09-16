import '../../repo_manager.dart';

/// UI-facing proxy for [ProjectScanner], used only by
/// project_details.screen.dart's dialog: it needs to load one project's own
/// monorepo member-package tree, but the dialog is a route pushed outside
/// the app's Provider subtree, so it can't reach ExplorerStore/StorageStore
/// (which each load a whole project *list*, not a single one anyway) via
/// `context.read`. See lib/src/stores/global_stores.dart for the shared
/// instance.
class ProjectScannerStore {
  const ProjectScannerStore(this._scanner);

  final ProjectScanner _scanner;

  Future<ProjectModel> loadSubPackages(
    ProjectModel project, {
    bool forceRefresh = false,
  }) =>
      _scanner.loadSubPackages(project, forceRefresh: forceRefresh);
}
