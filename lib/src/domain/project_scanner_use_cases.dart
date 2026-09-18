import '../../repo_manager.dart';

/// Business logic for scanning/loading projects, shared by every screen
/// state that needs its own project list (ExplorerState, StorageState) and
/// by project_details.screen.dart's dialog (which needs to load a single
/// monorepo's own member-package tree, on demand, outside of either
/// screen's own load cycle). Centralizing the getProjects()/loadSubPackages
/// failure handling here means each of those callers doesn't repeat its
/// own try/catch for the same two calls.
class ProjectScannerUseCases {
  ProjectScannerUseCases(this._scanner, this._l10n);

  final ProjectScanner _scanner;
  final AppLocalizations _l10n;

  // ExplorerState and StorageState each own an independent scan/copy of
  // the project list, and both reload from the exact same trigger —
  // ProjectDirectoryRepo.dirsVersion bumping notifies both of their
  // listeners synchronously, one right after the other. Without this,
  // that's two full directory walks for the one underlying change. Only
  // ever shares a scan that's *already running* — cleared the moment it
  // settles — so it can't hand a later, genuinely new call (e.g. a
  // follow-up dirsVersion bump for a further directory change) a stale
  // result from before that change; it only ever collapses callers asking
  // about the same state at the same time.
  Future<List<ProjectModel>?>? _inFlightGetProjects;

  /// Returns null (rather than throwing) on failure — the caller keeps
  /// whatever project list it already had rather than clearing it out.
  Future<List<ProjectModel>?> getProjects() {
    return _inFlightGetProjects ??=
        _getProjects().whenComplete(() => _inFlightGetProjects = null);
  }

  Future<List<ProjectModel>?> _getProjects() async {
    try {
      return await _scanner.getProjects();
    } catch (error, stackTrace) {
      logError('Load projects', error, stackTrace);
      SnackbarManager.show(_l10n.errorLoadProjects);
      return null;
    }
  }

  // Same reasoning as _inFlightGetProjects: ExplorerState's and
  // StorageState's own background sub-package loaders both walk their
  // (often-overlapping) project lists on the same dirsVersion-triggered
  // reload, so the same monorepo can end up asked for twice at once here
  // too. Keyed by path — cleared the moment that path's call settles, so
  // it only ever collapses truly concurrent callers, never a later one.
  final Map<String, Future<ProjectModel>> _inFlightLoadSubPackages = {};

  // getProjects() deliberately leaves a monorepo's member-package tree
  // unloaded so the caller's list shows up immediately — this fills one in
  // on demand. Marks subPackagesLoaded regardless of success so a caller's
  // loading state (e.g. a badge/spinner) doesn't spin forever over a scan
  // that failed.
  Future<ProjectModel> loadSubPackages(
    ProjectModel project, {
    bool forceRefresh = false,
  }) {
    // A forced refresh is a deliberate one-off (project_details.screen.dart's
    // own refresh action) — it wants a genuinely fresh result right now,
    // not to be folded into (or to have a background caller folded into)
    // whichever slot a passive background load happens to be sitting in.
    if (forceRefresh) return _loadSubPackages(project, forceRefresh: true);

    // Block body, not `() => _inFlightLoadSubPackages.remove(...)` — Map.
    // remove() returns the removed value, which here is the very Future
    // whenComplete is building; returning it from this callback makes
    // whenComplete chain that Future onto itself and deadlock forever.
    return _inFlightLoadSubPackages[project.path] ??=
        _loadSubPackages(project, forceRefresh: false).whenComplete(() {
      _inFlightLoadSubPackages.remove(project.path);
    });
  }

  Future<ProjectModel> _loadSubPackages(
    ProjectModel project, {
    required bool forceRefresh,
  }) async {
    try {
      return await _scanner.loadSubPackages(project,
          forceRefresh: forceRefresh);
    } catch (error, stackTrace) {
      logError('Load sub-packages for "${project.name}"', error, stackTrace);
      SnackbarManager.show(_l10n.errorLoadSubPackages(project.name));
      return project.copyWith(subPackagesLoaded: true);
    }
  }
}
