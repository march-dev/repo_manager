import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../repo_manager.dart';

part 'project_details_state.g.dart';

class ProjectDetailsState = _ProjectDetailsStateBase with _$ProjectDetailsState;

enum ProjectDetailsTab { general, subpackages, git }

/// Reactive UI state for project_details.screen.dart's full-screen page —
/// the project being viewed (possibly refined once its own monorepo tree/
/// size/language/framework composition finish loading in the background),
/// the Subpackages/Git tab, tree sort/expand state, and per-page favourite
/// overlays. Business logic (loading a monorepo's tree, computing/cleaning
/// its size, computing its byte-based language/framework composition,
/// toggling a favourite) lives in [ProjectActionsState]; this only tracks
/// what the page needs to observe and re-render on.
///
/// One instance per page (scoped to it via a `Provider` in
/// project_details.screen.dart, not part of _RootScaffold's app-wide
/// MultiProvider) — a fresh page always starts a fresh scan/load, the same
/// way the dialog this page replaced used to.
abstract class _ProjectDetailsStateBase with Store {
  _ProjectDetailsStateBase({
    required ProjectModel initialProject,
    required ProjectActionsState actions,
    // Genuinely passed at project_details.screen.dart's own
    // `ProjectDetailsState(..., owningProject: owningProject)` call site
    // — the analyzer just can't trace a call through ProjectDetailsState's
    // synthetic (mixin-application) forwarding constructor back to this
    // one.
    // ignore: unused_element_parameter
    this.owningProject,
  })  : project = initialProject,
        _actions = actions {
    // loadFrameworkComposition isn't started here directly — it needs
    // project.subPackages already resolved to know which paths belong to
    // which member project (see its own doc), so _loadSubPackages chains
    // it on once that's in.
    _loadSubPackages();
    loadSize();
    loadLanguageComposition();
    _loadNotInstalledIdes();
  }

  final ProjectActionsState _actions;

  // Every Ide value not actually installed on this machine — see
  // IdeLauncherRepo.notInstalledIdes' own doc. Checked at construction, and
  // rechecked by refreshEverything's own forceRefresh below; this page's
  // own summary row and Internal Projects tree rows both resolve their
  // hover hint/tap-to-open through this rather than each re-deriving their
  // own.
  @observable
  ObservableSet<Ide> notInstalledIdes = ObservableSet<Ide>();

  @action
  Future<void> _loadNotInstalledIdes({bool forceRefresh = false}) async {
    final result = forceRefresh
        ? await _actions.refreshNotInstalledIdes()
        : await _actions.notInstalledIdes();
    notInstalledIdes
      ..clear()
      ..addAll(result);
  }

  // See showProjectDetailsPage's own doc — only known when this page was
  // reached by drilling into another project's Internal Projects tree.
  // Fixed for this page's whole lifetime (set once, at construction,
  // never reassigned), so a plain final field rather than an observable.
  final ProjectModel? owningProject;

  // The row that opened this page may have been tapped before the
  // background load (see ExplorerState/StorageState's own
  // _loadSubPackagesInBackground) finished for this specific project —
  // _loadSubPackages fetches it directly in that case rather than this
  // page showing an empty tree.
  @observable
  ProjectModel project;

  @observable
  ProjectDetailsTab tab = ProjectDetailsTab.general;

  @action
  void setTab(ProjectDetailsTab value) => tab = value;

  @observable
  bool sortAscending = true;

  @action
  void toggleSort() => sortAscending = !sortAscending;

  // Which member-tree node paths are currently expanded — local to this
  // page (rebuilt fresh every time it's opened anyway, so there's nothing
  // worth persisting past its own lifetime).
  @observable
  Set<String> expanded = const {};

  @action
  void toggleExpanded(String path) {
    final next = Set<String>.of(expanded);
    if (!next.remove(path)) next.add(path);
    expanded = next;
  }

  @observable
  ProjectSizeModel? size;

  @observable
  bool sizeLoading = true;

  // Distinct from sizeLoading — set only around an explicit
  // refreshEverything() press (size + subpackages together), so the
  // header's own RefreshIconButton actually shows it's doing something,
  // the same way StorageState.isRefreshing drives its own refresh button.
  // sizeLoading itself deliberately stays false during a forced refresh
  // (see loadSize) so the size/cache figures don't flash a loading state
  // on every background rescan too.
  @observable
  bool refreshing = false;

  @observable
  bool cleaning = false;

  @computed
  bool get isMonorepo => project.monorepoTool != null;

  // How many bytes of source, under this project's own directory tree,
  // belong to each language — loaded async (a real filesystem walk, same
  // as [size]) rather than computed from [project], since it counts bytes
  // by file extension, not anything already known about the project or
  // its subPackages tree. See ProjectCompositionRepo's own doc for why
  // this reads truer than a per-project tally ("this tree is 98% Dart" by
  // actual source weight, not "12 of these 13 packages happen to be Dart
  // regardless of size").
  @observable
  Map<ProjectLanguage, int> languageComposition = const {};

  @observable
  bool languageCompositionLoading = true;

  @action
  Future<void> loadLanguageComposition({bool forceRefresh = false}) async {
    if (!forceRefresh) languageCompositionLoading = true;
    final result = await _actions.getLanguageComposition(
      project.path,
      project.name,
      forceRefresh: forceRefresh,
    );
    runInAction(() {
      if (result != null) languageComposition = result;
      languageCompositionLoading = false;
    });
  }

  // How many bytes of source belong to each framework — same byte-walk
  // approach as [languageComposition] (see ProjectCompositionRepo's own
  // doc for how a framework, not itself a per-file signal the way a
  // language is, still gets weighted by bytes: every file belongs to
  // exactly one project in the tree, and that project's own framework,
  // if any, is what the file's bytes count toward) rather than a plain
  // "one project in this tree, one vote" tally.
  @observable
  Map<ProjectFramework, int> frameworkComposition = const {};

  @observable
  bool frameworkCompositionLoading = true;

  @action
  Future<void> loadFrameworkComposition({bool forceRefresh = false}) async {
    if (!forceRefresh) frameworkCompositionLoading = true;
    final result = await _actions.getFrameworkComposition(
      project,
      forceRefresh: forceRefresh,
    );
    runInAction(() {
      if (result != null) frameworkComposition = result;
      frameworkCompositionLoading = false;
    });
  }

  @action
  void _loadSubPackages() {
    final subPackagesFuture = !project.subPackagesLoaded
        // Nothing to show yet at all (cached or otherwise) — load(),
        // which reads the Hive-cached tree if there is one, and only
        // actually rescans the filesystem if there isn't.
        ? _actions.loadSubPackages(project)
        // Already showing a tree (fresh or from cache) — quietly rescan
        // in the background so a package added/removed on disk since the
        // cache was written shows up without the visible loading state,
        // same "show the cached one now, update silently" pattern
        // project sizes already use.
        : _actions.loadSubPackages(project, forceRefresh: true);

    subPackagesFuture.then((updated) {
      _setProject(updated);
      // Only correct once project.subPackages reflects the real tree —
      // see loadFrameworkComposition's own doc.
      loadFrameworkComposition();
    });
  }

  @action
  void _setProject(ProjectModel updated) => project = updated;

  @action
  Future<void> loadSize({bool forceRefresh = false}) async {
    if (!forceRefresh) sizeLoading = true;
    // getProjectSize walks projectPath recursively — for a monorepo this
    // already includes every member package's own files, so this one call
    // is this project's real total, no extra per-member aggregation needed.
    final result = await _actions.getProjectSize(
      project.path,
      project.name,
      forceRefresh: forceRefresh,
    );
    runInAction(() {
      if (result != null) size = result;
      sizeLoading = false;
    });
  }

  Future<void> refreshEverything() async {
    runInAction(() => refreshing = true);
    final sizeFuture = loadSize(forceRefresh: true);
    final languageFuture = loadLanguageComposition(forceRefresh: true);
    final projectFuture =
        _actions.loadSubPackages(project, forceRefresh: true).then((updated) {
      _setProject(updated);
      // Chained the same way _loadSubPackages does — needs the freshly
      // rescanned project.subPackages in place first.
      return loadFrameworkComposition(forceRefresh: true);
    });
    // A stale "IDE not installed" verdict is the same kind of staleness
    // this refresh already exists to fix (see
    // IdeLauncherRepo.refreshNotInstalledIdes' own doc) — included in the
    // same Future.wait so refreshing stays true until this settles too.
    final notInstalledIdesFuture = _loadNotInstalledIdes(forceRefresh: true);
    await Future.wait(
        [sizeFuture, languageFuture, projectFuture, notInstalledIdesFuture]);
    runInAction(() => refreshing = false);
  }

  @action
  Future<void> cleanup() async {
    cleaning = true;
    await _actions.cleanupProject(project.path, project.name);
    runInAction(() => cleaning = false);
    await loadSize(forceRefresh: true);
  }

  Future<void> toggleOwnFavourite() async {
    if (!await _actions.toggleFavourite(project)) return;
    _setProject(project.copyWith(favourite: !project.favourite));
  }

  // Folders first, then projects — each group alphabetized by
  // [sortAscending] independently, so reversing the sort only flips the
  // order *within* each group rather than interleaving folders and
  // projects, matching how Finder/VS Code/most file browsers keep
  // containers grouped ahead of leaves regardless of sort direction.
  List<WorkspaceEntry> sorted(List<WorkspaceEntry> entries) {
    int compareNames(WorkspaceEntry a, WorkspaceEntry b) {
      final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return sortAscending ? comparison : -comparison;
    }

    final folders = entries.whereType<WorkspaceFolderEntry>().toList()
      ..sort(compareNames);
    final projects = entries.whereType<WorkspaceProjectEntry>().toList()
      ..sort(compareNames);

    return [...folders, ...projects];
  }
}
