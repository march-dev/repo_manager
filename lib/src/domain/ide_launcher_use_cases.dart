import 'package:flutter/foundation.dart';

import '../../repo_manager.dart';

/// Business logic for resolving which IDE a project opens in, actually
/// launching it (or one of its native platform-target subfolders) there,
/// and tracking recently opened projects.
///
/// Registered as a plain `Provider<IdeLauncherUseCases>` in _RootScaffold's
/// MultiProvider (app.dart). project_context_menu.dart's right-click menu
/// and project_details.screen.dart's dialog both need this too, but both
/// sit outside the app's Provider subtree (a context-menu overlay and a
/// dialog route are siblings of wherever this Provider is scoped, not
/// descendants of it), so neither can fetch it via `context.read` directly
/// — instead, whichever Provider-reachable call site opens them reads it
/// via `context.read` once and passes it in explicitly as a
/// constructor/function parameter.
///
/// Every action here (as opposed to the plain reads below) catches its own
/// failures — launching an IDE process is the single most externally
/// fragile thing this app does (the IDE might not be installed, or not on
/// PATH) — logs them, and tells the user via [SnackbarManager] rather than
/// the action just silently doing nothing.
class IdeLauncherUseCases {
  const IdeLauncherUseCases(this._repo, this._l10n);

  final IdeLauncherRepo _repo;
  final AppLocalizations _l10n;

  ValueListenable<int> get recentlyOpenedVersion => _repo.recentlyOpenedVersion;

  Ide resolveIde(ProjectModel project) => _repo.resolveIde(project);

  // Plain reads (like resolveIde above), not wrapped in try/catch — the
  // repo's own isIdeInstalled already swallows the one thing here that can
  // throw (see its own doc), so there's nothing left for a failure
  // snackbar to report.
  Future<Set<Ide>> notInstalledIdes() => _repo.notInstalledIdes();

  Future<Set<Ide>> refreshNotInstalledIdes() => _repo.refreshNotInstalledIdes();

  Ide? resolveInstalledIde(ProjectModel project, Set<Ide> notInstalledIdes) =>
      _repo.resolveInstalledIde(project, notInstalledIdes);

  Ide? resolveIdeForTarget(PlatformTarget target, Set<Ide> notInstalledIdes) =>
      _repo.resolveIdeForTarget(target, notInstalledIdes);

  List<String> getRecentlyOpenedProjectPaths() =>
      _repo.getRecentlyOpenedProjectPaths();

  Future<void> openInEditor(ProjectModel project) async {
    try {
      await _repo.openInEditor(project);
    } catch (error, stackTrace) {
      logError('Open "${project.name}" in editor', error, stackTrace);
      SnackbarManager.show(_l10n.errorOpenProject(project.name));
    }
  }

  Future<void> openPathInIde(String path, Ide ide) async {
    try {
      await _repo.openPathInIde(path, ide);
    } catch (error, stackTrace) {
      logError('Open $path in ${ide.label}', error, stackTrace);
      SnackbarManager.show(_l10n.errorOpenInIde(ide.label));
    }
  }

  Future<void> recordProjectOpened(String projectPath) async {
    try {
      await _repo.recordProjectOpened(projectPath);
    } catch (error, stackTrace) {
      // Just bookkeeping (recent-list ordering) — logged, but not worth a
      // snackbar since it doesn't affect the actual action the user cares
      // about (opening the project).
      logError('Record project opened: $projectPath', error, stackTrace);
    }
  }

  Future<List<PlatformTarget>> availablePlatformTargets(
    ProjectModel project,
  ) =>
      _repo.availablePlatformTargets(project);

  Future<void> openPlatformTarget(
    ProjectModel project,
    PlatformTarget target,
    Ide ide,
  ) async {
    try {
      await _repo.openPlatformTarget(project, target, ide);
    } catch (error, stackTrace) {
      logError(
        'Open ${target.label} for "${project.name}"',
        error,
        stackTrace,
      );
      SnackbarManager.show(
          _l10n.errorOpenPlatformTarget(target.label, project.name));
    }
  }

  Future<void> revealInFileManager(String path) async {
    try {
      await _repo.revealInFileManager(path);
    } catch (error, stackTrace) {
      logError('Reveal $path in file manager', error, stackTrace);
      SnackbarManager.show(_l10n.errorOpenFileManager);
    }
  }
}
