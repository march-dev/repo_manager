import 'package:flutter/foundation.dart';

import '../../repo_manager.dart';

/// State for the shared "project actions" widget group — the right-click
/// menu (project_context_menu.dart), the quick-launch tile
/// (quick_launch_tile.dart) and the project-details dialog
/// (project_details.screen.dart) — rather than any single screen, since all
/// three are used from Explorer, Storage and Dashboard alike. Combines
/// exactly the two use cases that group needs: launching a project in its
/// IDE, and loading a monorepo's member-package tree on demand.
///
/// Registered as a plain `Provider<ProjectActionsState>` in _RootScaffold's
/// MultiProvider (app.dart). project_context_menu.dart's menu overlay and
/// project_details.screen.dart's dialog route both sit outside that
/// Provider subtree (siblings of it in the Navigator's Overlay, not
/// descendants), so neither can fetch this via `context.read` directly —
/// instead, whichever Provider-reachable screen opens them reads it via
/// `context.read` once and passes it in explicitly.
class ProjectActionsState {
  const ProjectActionsState({
    required IdeLauncherUseCases ideLauncherUseCases,
    required ProjectScannerUseCases projectScannerUseCases,
  })  : _ideLauncherUseCases = ideLauncherUseCases,
        _projectScannerUseCases = projectScannerUseCases;

  final IdeLauncherUseCases _ideLauncherUseCases;
  final ProjectScannerUseCases _projectScannerUseCases;

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
}
