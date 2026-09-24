import 'package:flutter/foundation.dart';

import '../../repo_manager.dart';

/// State for the shared "project actions" widget group — the right-click
/// menu (project_context_menu.dart), the quick-launch tile
/// (quick_launch_tile.dart) and the project-details page
/// (project_details.screen.dart) — rather than any single screen, since all
/// three are used from Explorer, Storage and Dashboard alike. Combines
/// exactly the use cases that group needs: launching a project in its IDE,
/// loading a monorepo's member-package tree on demand, toggling a
/// project's favourite flag, computing/cleaning up its on-disk size, and
/// computing its language/framework composition by bytes.
///
/// Registered as a plain `Provider<ProjectActionsState>` in _RootScaffold's
/// MultiProvider (app.dart). project_context_menu.dart's menu overlay and
/// project_details.screen.dart's pushed page both sit outside that
/// Provider subtree (a `MaterialPageRoute` becomes a new sibling route in
/// the same `Navigator`'s Overlay, not a descendant of whatever pushed it
/// — the same reason a `showDialog` route already can't reach it either),
/// so neither can fetch this via `context.read` directly — instead,
/// whichever Provider-reachable screen opens them reads it via
/// `context.read` once and passes it in explicitly.
class ProjectActionsState {
  const ProjectActionsState({
    required IdeLauncherUseCases ideLauncherUseCases,
    required ProjectScannerUseCases projectScannerUseCases,
    required FavouritesUseCases favouritesUseCases,
    required ProjectSizeUseCases projectSizeUseCases,
    required ProjectCompositionUseCases projectCompositionUseCases,
  })  : _ideLauncherUseCases = ideLauncherUseCases,
        _projectScannerUseCases = projectScannerUseCases,
        _favouritesUseCases = favouritesUseCases,
        _projectSizeUseCases = projectSizeUseCases,
        _projectCompositionUseCases = projectCompositionUseCases;

  final IdeLauncherUseCases _ideLauncherUseCases;
  final ProjectScannerUseCases _projectScannerUseCases;
  final FavouritesUseCases _favouritesUseCases;
  final ProjectSizeUseCases _projectSizeUseCases;
  final ProjectCompositionUseCases _projectCompositionUseCases;

  ValueListenable<int> get recentlyOpenedVersion =>
      _ideLauncherUseCases.recentlyOpenedVersion;

  List<String> getRecentlyOpenedProjectPaths() =>
      _ideLauncherUseCases.getRecentlyOpenedProjectPaths();

  Ide resolveIde(ProjectModel project) =>
      _ideLauncherUseCases.resolveIde(project);

  Future<void> openInEditor(ProjectModel project) =>
      _ideLauncherUseCases.openInEditor(project);

  Future<void> openPathInIde(String path, Ide ide) =>
      _ideLauncherUseCases.openPathInIde(path, ide);

  Future<void> recordProjectOpened(String projectPath) =>
      _ideLauncherUseCases.recordProjectOpened(projectPath);

  Future<List<PlatformTarget>> availablePlatformTargets(
    ProjectModel project,
  ) =>
      _ideLauncherUseCases.availablePlatformTargets(project);

  Future<void> openPlatformTarget(
          ProjectModel project, PlatformTarget target) =>
      _ideLauncherUseCases.openPlatformTarget(project, target);

  Future<void> revealInFileManager(String path) =>
      _ideLauncherUseCases.revealInFileManager(path);

  Future<ProjectModel> loadSubPackages(
    ProjectModel project, {
    bool forceRefresh = false,
  }) =>
      _projectScannerUseCases.loadSubPackages(project,
          forceRefresh: forceRefresh);

  Future<bool> toggleFavourite(ProjectModel project) =>
      _favouritesUseCases.toggleFavourite(project);

  Future<ProjectSizeModel?> getProjectSize(
    String projectPath,
    String projectName, {
    bool forceRefresh = false,
    CancellationToken? cancellationToken,
  }) =>
      _projectSizeUseCases.getProjectSize(
        projectPath,
        projectName,
        forceRefresh: forceRefresh,
        cancellationToken: cancellationToken,
      );

  Future<bool> cleanupProject(String projectPath, String projectName) =>
      _projectSizeUseCases.cleanupProject(projectPath, projectName);

  Future<Map<ProjectLanguage, int>?> getLanguageComposition(
    String projectPath,
    String projectName, {
    bool forceRefresh = false,
    CancellationToken? cancellationToken,
  }) =>
      _projectCompositionUseCases.getLanguageComposition(
        projectPath,
        projectName,
        forceRefresh: forceRefresh,
        cancellationToken: cancellationToken,
      );

  Future<Map<ProjectFramework, int>?> getFrameworkComposition(
    ProjectModel project, {
    bool forceRefresh = false,
    CancellationToken? cancellationToken,
  }) =>
      _projectCompositionUseCases.getFrameworkComposition(
        project,
        forceRefresh: forceRefresh,
        cancellationToken: cancellationToken,
      );
}
