import 'dart:io';

import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'explorer.store.g.dart';

enum ExplorerGrouping { none, byFolder, byCollection }

// Sentinel groupedByCollection key for projects that aren't in any
// collection — an empty string can never collide with a real collection
// name, since CollectionsStore.createCollection rejects blank/whitespace
// names.
const uncategorizedCollectionKey = '';

class ExplorerStore = _ExplorerStoreBase with _$ExplorerStore;

abstract class _ExplorerStoreBase with Store {
  _ExplorerStoreBase({
    required ProjectScanner projectScanner,
    required AppSettingsRepo appSettingsRepo,
    required FavouritesRepo favouritesRepo,
    required CollectionsStore collectionsStore,
    required IdeLauncherStore ideLauncherStore,
    required AppLocalizations l10n,
  })  : _projectScanner = projectScanner,
        _appSettingsRepo = appSettingsRepo,
        _favouritesRepo = favouritesRepo,
        _collectionsStore = collectionsStore,
        _ideLauncherStore = ideLauncherStore,
        _l10n = l10n {
    loadProjects().then((_) => _loadSubPackagesInBackground());
    grouping = _appSettingsRepo.getExplorerGrouping();
    pinFavourites = _appSettingsRepo.getExplorerPinFavourites();
  }

  final ProjectScanner _projectScanner;
  final AppSettingsRepo _appSettingsRepo;
  final FavouritesRepo _favouritesRepo;
  final CollectionsStore _collectionsStore;
  final IdeLauncherStore _ideLauncherStore;
  final AppLocalizations _l10n;

  @observable
  ObservableList<ProjectModel> projects = ObservableList<ProjectModel>();

  @action
  Future<void> loadProjects() async {
    try {
      final loaded = await _projectScanner.getProjects();
      projects
        ..clear()
        ..addAll(loaded);
    } on Object catch (error, stackTrace) {
      logError('Load projects', error, stackTrace);
      SnackbarManager.show(_l10n.errorLoadProjects);
    }
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
            try {
              final updated = await _projectScanner.loadSubPackages(project);
              final index = projects.indexWhere((p) => p.path == updated.path);
              if (index != -1) projects[index] = updated;
            } on Object catch (error, stackTrace) {
              logError(
                'Load sub-packages for "${project.name}"',
                error,
                stackTrace,
              );
              SnackbarManager.show(_l10n.errorLoadSubPackages(project.name));
            }
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
    try {
      await _appSettingsRepo.setExplorerGrouping(value);
    } on Object catch (error, stackTrace) {
      // Just a preference save — the grouping itself already applied
      // above regardless, so this is only worth logging.
      logError('Save explorer grouping preference', error, stackTrace);
    }
  }

  @observable
  bool pinFavourites = true;

  @action
  Future<void> togglePinFavourites() async {
    pinFavourites = !pinFavourites;
    try {
      await _appSettingsRepo.setExplorerPinFavourites(pinFavourites);
    } on Object catch (error, stackTrace) {
      logError('Save pin-favourites preference', error, stackTrace);
    }
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
  // Membership itself lives in CollectionsRepo (via _collectionsStore), not
  // on ProjectModel, so this also depends on
  // _collectionsStore.membershipVersion to know when to recompute.
  @computed
  Map<String, List<ProjectModel>> get groupedByCollection {
    // Read purely to establish the MobX dependency above.
    _collectionsStore.membershipVersion;

    final grouped = <String, List<ProjectModel>>{
      for (final name in _collectionsStore.names) name: <ProjectModel>[],
    };
    for (final project in visibleProjects) {
      final names = _collectionsStore.getProjectCollections(project.path);
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
    try {
      await _favouritesRepo.toggleFavoriteProject(project.path);
    } on Object catch (error, stackTrace) {
      logError('Toggle favourite for "${project.name}"', error, stackTrace);
      SnackbarManager.show(_l10n.errorToggleFavourite(project.name));
      return;
    }
    final index = projects.indexWhere((p) => p.path == project.path);
    if (index == -1) return;
    projects[index] = project.copyWith(favourite: !project.favourite);
  }

  // Error handling lives in IdeLauncherStore (see its own doc) rather than
  // being duplicated here — this just delegates to it.
  Future<void> openProject(ProjectModel project) {
    return _ideLauncherStore.openInEditor(project);
  }
}
