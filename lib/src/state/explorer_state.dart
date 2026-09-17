import 'dart:io';

import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'explorer_state.g.dart';

enum ExplorerGrouping { none, byFolder, byCollection }

// Sentinel groupedByCollection key for projects that aren't in any
// collection — an empty string can never collide with a real collection
// name, since CollectionsUseCases.createCollection rejects blank/whitespace
// names.
const uncategorizedCollectionKey = '';

class ExplorerState = _ExplorerStateBase with _$ExplorerState;

/// Reactive UI state for Explorer's screen (and Dashboard's own quick-launch
/// section, which reads the same live project list — see _RootScaffold in
/// app.dart, which provides this above both screens). All the actual
/// business logic — scanning for projects, toggling a favourite, persisting
/// a preference — lives in the relevant use-case class; this only tracks
/// what the UI needs to observe and re-render on, plus a little
/// presentation-only derived data (search/sort/grouping).
abstract class _ExplorerStateBase with Store {
  _ExplorerStateBase({
    required ProjectScannerUseCases projectScannerUseCases,
    required FavouritesUseCases favouritesUseCases,
    required AppSettingsUseCases appSettingsUseCases,
    required CollectionsState collectionsState,
    required IdeLauncherUseCases ideLauncherUseCases,
  })  : _projectScannerUseCases = projectScannerUseCases,
        _favouritesUseCases = favouritesUseCases,
        _appSettingsUseCases = appSettingsUseCases,
        _collectionsState = collectionsState,
        _ideLauncherUseCases = ideLauncherUseCases {
    loadProjects().then((_) => _loadSubPackagesInBackground());
    grouping = _appSettingsUseCases.getExplorerGrouping();
    pinFavourites = _appSettingsUseCases.getExplorerPinFavourites();
  }

  final ProjectScannerUseCases _projectScannerUseCases;
  final FavouritesUseCases _favouritesUseCases;
  final AppSettingsUseCases _appSettingsUseCases;
  final CollectionsState _collectionsState;
  final IdeLauncherUseCases _ideLauncherUseCases;

  @observable
  ObservableList<ProjectModel> projects = ObservableList<ProjectModel>();

  @action
  Future<void> loadProjects() async {
    final loaded = await _projectScannerUseCases.getProjects();
    if (loaded == null) return;
    projects
      ..clear()
      ..addAll(loaded);
  }

  // getProjects() deliberately leaves a monorepo's member-package tree
  // unloaded so the list above shows up immediately — this fills each one
  // in afterwards, throttled the same way size calculation/cleanup are
  // elsewhere in the app, updating that project's row (and thus its
  // MonorepoBadge's count) in place as each one finishes.
  @action
  Future<void> _loadSubPackagesInBackground() async {
    final pending =
        projects.where((project) => !project.subPackagesLoaded).toList();

    await runWithConcurrency(
      [
        for (final project in pending)
          () async {
            final updated =
                await _projectScannerUseCases.loadSubPackages(project);
            final index = projects.indexWhere((p) => p.path == updated.path);
            if (index != -1) projects[index] = updated;
          },
      ],
      concurrency: Platform.numberOfProcessors,
    );
  }

  @observable
  ExplorerGrouping grouping = ExplorerGrouping.none;

  @action
  Future<void> setGrouping(ExplorerGrouping value) async {
    grouping = value;
    await _appSettingsUseCases.setExplorerGrouping(value);
  }

  @observable
  bool pinFavourites = true;

  @action
  Future<void> togglePinFavourites() async {
    pinFavourites = !pinFavourites;
    await _appSettingsUseCases.setExplorerPinFavourites(pinFavourites);
  }

  @observable
  bool sortAscending = true;

  @action
  void toggleNameSort() => sortAscending = !sortAscending;

  @observable
  String searchQuery = '';

  @action
  void setSearchQuery(String value) => searchQuery = value;

  // When pinFavourites is on, favourites come first (both in the flat list
  // and within each folder group below), alphabetical among themselves;
  // everyone else follows, also alphabetical. When it's off, favourite
  // status is ignored entirely and everything sorts by name together.
  @computed
  List<ProjectModel> get visibleProjects {
    final sorted = projects
        .where((project) => fuzzyMatch(searchQuery, project.name))
        .toList();
    sorted.sort((a, b) {
      if (pinFavourites && a.favourite != b.favourite) {
        return a.favourite ? -1 : 1;
      }
      final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return sortAscending ? comparison : -comparison;
    });
    return sorted;
  }

  // Directory path -> its projects, used when grouping is enabled. Grouped
  // by the search directory each project was discovered under (see
  // ProjectModel.sourceDir); order within each group follows visibleProjects,
  // so favourites stay pinned first inside each folder group too.
  @computed
  Map<String, List<ProjectModel>> get groupedProjects {
    final grouped = <String, List<ProjectModel>>{};
    for (final project in visibleProjects) {
      grouped.putIfAbsent(project.sourceDir, () => []).add(project);
    }
    return grouped;
  }

  // Collection name -> its projects (a project in several collections
  // appears in several groups; one with none goes under
  // uncategorizedCollectionKey). Every known collection gets an entry up
  // front — even an empty one — so it still gets a section header to
  // right-click rename/delete on; otherwise a collection with nothing in
  // it (yet, or any more) would be invisible and unreachable in this view.
  // Membership itself lives in CollectionsUseCases (via _collectionsState),
  // not on ProjectModel, so this also depends on
  // _collectionsState.membershipVersion to know when to recompute.
  @computed
  Map<String, List<ProjectModel>> get groupedByCollection {
    // Read purely to establish the MobX dependency above.
    _collectionsState.membershipVersion;

    final grouped = <String, List<ProjectModel>>{
      for (final name in _collectionsState.names) name: <ProjectModel>[],
    };
    for (final project in visibleProjects) {
      final names = _collectionsState.getProjectCollections(project.path);
      if (names.isEmpty) {
        grouped.putIfAbsent(uncategorizedCollectionKey, () => []).add(project);
      } else {
        for (final name in names) {
          grouped.putIfAbsent(name, () => []).add(project);
        }
      }
    }
    return grouped;
  }

  @action
  Future<void> toggleFavourite(ProjectModel project) async {
    if (!await _favouritesUseCases.toggleFavourite(project)) return;
    final index = projects.indexWhere((p) => p.path == project.path);
    if (index == -1) return;
    projects[index] = project.copyWith(favourite: !project.favourite);
  }

  // Error handling lives in IdeLauncherUseCases (see its own doc) rather
  // than being duplicated here — this just delegates to it.
  Future<void> openProject(ProjectModel project) {
    return _ideLauncherUseCases.openInEditor(project);
  }
}
