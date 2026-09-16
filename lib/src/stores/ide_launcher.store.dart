import 'package:flutter/foundation.dart';

import '../../repo_manager.dart';

/// UI-facing proxy for [IdeLauncherRepo]. Not a Provider-scoped store like
/// ExplorerStore/StorageStore — project_context_menu.dart's right-click menu
/// and project_details.screen.dart's dialog both need this too, and both
/// sit outside the app's Provider subtree (a context-menu overlay and a
/// dialog route are siblings of wherever ExplorerStore's own Provider is
/// scoped, not descendants of it — see _RootScaffold in app.dart), so
/// nothing here can be fetched via `context.read`. See
/// lib/src/stores/global_stores.dart for the single shared instance every
/// one of those call sites actually uses — this class itself is still
/// built with its [IdeLauncherRepo] passed in explicitly, not looked up.
class IdeLauncherStore {
  const IdeLauncherStore(this._repo);

  final IdeLauncherRepo _repo;

  ValueListenable<int> get recentlyOpenedVersion => _repo.recentlyOpenedVersion;

  Ide resolveIde(ProjectModel project) => _repo.resolveIde(project);

  List<String> getRecentlyOpenedProjectPaths() =>
      _repo.getRecentlyOpenedProjectPaths();

  Future<void> openInEditor(ProjectModel project) =>
      _repo.openInEditor(project);

  Future<void> openPathInIde(String path, Ide ide) =>
      _repo.openPathInIde(path, ide);

  Future<void> recordProjectOpened(String projectPath) =>
      _repo.recordProjectOpened(projectPath);

  Future<List<PlatformTarget>> availablePlatformTargets(
    ProjectModel project,
  ) =>
      _repo.availablePlatformTargets(project);

  Future<void> openPlatformTarget(
          ProjectModel project, PlatformTarget target) =>
      _repo.openPlatformTarget(project, target);
}
