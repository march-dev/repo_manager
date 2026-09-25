import 'package:flutter/foundation.dart';

import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'dashboard_state.g.dart';

class DashboardState = _DashboardStateBase with _$DashboardState;

/// Reactive UI state for Dashboard's screen — purely derived from
/// [ExplorerState]/[StorageState]/[SystemCleanerState] (all already
/// loading/scanning on their own screens, and provided above Dashboard too
/// — see _RootScaffold in app.dart) and [ProjectActionsState]'s
/// recently-opened tracking. Holds no data or business logic of its own;
/// every getter here is computed from state that already exists elsewhere,
/// just reshaped into what Dashboard's summary cards/sections actually
/// want to render.
abstract class _DashboardStateBase with Store {
  _DashboardStateBase({
    required ExplorerState explorerState,
    required StorageState storageState,
    required SystemCleanerState systemCleanerState,
    required ProjectActionsState projectActionsState,
  })  : _explorerState = explorerState,
        _storageState = storageState,
        _systemCleanerState = systemCleanerState,
        _projectActionsState = projectActionsState;

  final ExplorerState _explorerState;
  final StorageState _storageState;
  final SystemCleanerState _systemCleanerState;
  final ProjectActionsState _projectActionsState;

  // Most recently opened first, kept out of the store's public surface —
  // recentlyOpened(maxShown) below is what the UI actually wants.
  static const _maxRecentlyOpened = 6;

  @computed
  List<ProjectModel> get projects => _explorerState.projects;

  @computed
  int get favouriteCount => projects.where((p) => p.favourite).length;

  @computed
  int get monorepoCount => projects.where((p) => p.monorepoTool != null).length;

  // Storage's own per-project scan plus System Cleaner's own dev-tool
  // cache scan (Xcode DerivedData, ~/.pub-cache, ~/.gradle/caches, ...) —
  // two disjoint filesystem walks over different locations, so the two
  // totals are additive rather than one subsuming the other. System
  // Cleaner's own total is entirely reclaimable junk, not a project's
  // working files, so it folds into [cacheBytes] rather than [coreBytes].
  @computed
  int get totalBytes =>
      _storageState.totalBytes + _systemCleanerState.totalBytes;

  @computed
  int get coreBytes => _storageState.coreBytes;

  @computed
  int get cacheBytes =>
      _storageState.cacheBytes + _systemCleanerState.totalBytes;

  @computed
  List<ProjectModel> get pinnedProjects {
    final favourites = projects.where((p) => p.favourite).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return favourites;
  }

  ValueListenable<int> get recentlyOpenedVersion =>
      _projectActionsState.recentlyOpenedVersion;

  // IdeLauncherRepo itself keeps a longer history than _maxRecentlyOpened
  // — only the most recent handful are actually worth surfacing here. A
  // path with no matching known project (deleted, moved, or its search
  // directory removed in Settings) is silently skipped rather than shown
  // as a broken tile.
  List<ProjectModel> get recentlyOpened {
    final byPath = {for (final project in projects) project.path: project};
    return [
      for (final path in _projectActionsState.getRecentlyOpenedProjectPaths())
        if (byPath[path] != null) byPath[path]!,
    ].take(_maxRecentlyOpened).toList();
  }

  @computed
  Map<ProjectLanguage, int> get languageCounts {
    final counts = <ProjectLanguage, int>{};
    for (final project in projects) {
      counts.update(project.language, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  // Only counts projects with a detected framework — a plain-language
  // project (no framework layered on top) isn't a meaningful "framework"
  // category of its own, so it's left out rather than lumped under a
  // generic "None" bar.
  @computed
  Map<ProjectFramework, int> get frameworkCounts {
    final counts = <ProjectFramework, int>{};
    for (final project in projects) {
      final framework = project.framework;
      if (framework != null) {
        counts.update(framework, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    return counts;
  }
}
