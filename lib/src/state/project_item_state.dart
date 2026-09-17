import 'dart:async';

import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'project_item_state.g.dart';

class ProjectItemState = _ProjectItemStateBase with _$ProjectItemState;

/// Reactive UI state for a single row in Storage's list — its size, and
/// whether it's currently being cleaned up. One instance per project, held
/// by [StorageState]. Business logic (computing the real size, deleting the
/// reclaimable cache) lives in [ProjectSizeUseCases]; this only tracks what
/// the row needs to observe and re-render on.
abstract class _ProjectItemStateBase with Store {
  // Doesn't kick off loadSize itself — every place that creates one of
  // these (see StorageState.loadProjects) drives the initial load through
  // runWithConcurrency instead, so an unthrottled burst of N simultaneous
  // directory walks can't happen just from constructing N items at once.
  _ProjectItemStateBase(
    this.project, {
    required ProjectSizeUseCases projectSizeUseCases,
    required IdeLauncherUseCases ideLauncherUseCases,
  })  : _projectSizeUseCases = projectSizeUseCases,
        _ideLauncherUseCases = ideLauncherUseCases;

  final ProjectSizeUseCases _projectSizeUseCases;
  final IdeLauncherUseCases _ideLauncherUseCases;

  static const _cleanupRefreshInterval = Duration(seconds: 1);

  // Observable (not final) so StorageState can swap in an updated
  // ProjectModel once its monorepo member-package tree finishes loading
  // in the background — otherwise this row's MonorepoBadge would have no
  // way to notice the count becoming known.
  @observable
  ProjectModel project;

  @action
  void updateProject(ProjectModel updated) => project = updated;

  CancellationToken? _sizeCancellationToken;

  // What this project's SizeBar last actually displayed, if anything.
  // Lives here (not as widget state) because reordering the project list
  // (e.g. re-sorting by size) discards and recreates the row's widgets —
  // ListView.builder/.separated reconciles children by index, not by
  // following a key to its new position — but this store instance itself
  // persists, so a freshly-recreated widget can pick up visually where
  // the old one left off instead of either replaying the entrance
  // animation or popping in unanimated.
  ProjectSizeModel? lastShownSize;

  @observable
  ProjectSizeModel? size;
  @action
  Future<void> loadSize({bool forceRefresh = false}) async {
    size = null;
    await _refreshSize(forceRefresh: forceRefresh);
  }

  @action
  Future<void> _refreshSize({bool forceRefresh = false}) async {
    // A previous size scan may still be running (e.g. the cleanup timer
    // below fires again before the last scan finished) — cancel it so it
    // stops walking the filesystem for a result this call is about to
    // replace anyway.
    _sizeCancellationToken?.cancel();
    final cancellationToken = CancellationToken();
    _sizeCancellationToken = cancellationToken;

    final nextSize = await _projectSizeUseCases.getProjectSize(
      project.path,
      project.name,
      forceRefresh: forceRefresh,
      cancellationToken: cancellationToken,
    );
    if (nextSize == null) return;

    // This call was itself superseded by a newer one while awaiting above;
    // let that newer call's result win instead of overwriting it.
    if (cancellationToken.isCancelled) return;
    size = nextSize;
  }

  /// Recomputes this project's real size without first resetting [size] to
  /// null — unlike [loadSize], so a row already showing its cached size
  /// keeps showing it (no loading-spinner flash) while the fresh number is
  /// computed, then just updates in place once it's ready.
  Future<void> refreshInBackground() => _refreshSize(forceRefresh: true);

  @observable
  bool cleaning = false;
  @action
  Future<void> cleanup() async {
    cleaning = true;

    final refreshTimer = Timer.periodic(
      _cleanupRefreshInterval,
      (_) => _refreshSize(forceRefresh: true),
    );

    try {
      await _projectSizeUseCases.cleanupProject(project.path, project.name);
    } finally {
      // Regardless of success/failure — otherwise a failed cleanup would
      // leave this timer running and `cleaning` stuck true forever.
      refreshTimer.cancel();
      cleaning = false;
    }
    await _refreshSize(forceRefresh: true);
  }

  // Error handling lives in IdeLauncherUseCases (see its own doc) rather
  // than being duplicated here — this just delegates to it.
  Future<void> openInEditor() {
    return _ideLauncherUseCases.openInEditor(project);
  }
}
