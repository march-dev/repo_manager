import 'dart:async';

import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'project_item.store.g.dart';

class ProjectItemStore = _ProjectItemStoreBase with _$ProjectItemStore;

abstract class _ProjectItemStoreBase with Store {
  // Doesn't kick off loadSize itself — every place that creates one of
  // these (see StorageStore.loadProjects) drives the initial load through
  // runWithConcurrency instead, so an unthrottled burst of N simultaneous
  // directory walks can't happen just from constructing N items at once.
  _ProjectItemStoreBase(this.project);

  static const _cleanupRefreshInterval = Duration(seconds: 1);

  final ProjectModel project;

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

    final nextSize = await ProjectRepo().getProjectSize(
      project.path,
      forceRefresh: forceRefresh,
      cancellationToken: cancellationToken,
    );

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

    await ProjectRepo().cleanupProject(project.path);

    refreshTimer.cancel();
    cleaning = false;
    await _refreshSize(forceRefresh: true);
  }

  Future<void> openInEditor() {
    return ProjectRepo().openInEditor(project);
  }
}
