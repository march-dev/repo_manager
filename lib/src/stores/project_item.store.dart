import 'dart:async';

import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

class ProjectItemStore {
  ProjectItemStore(this.project, {bool forceRefresh = false}) {
    loadSize(forceRefresh: forceRefresh);
  }

  static const _cleanupRefreshInterval = Duration(seconds: 1);

  final ProjectModel project;

  final Observable<ProjectSizeModel?> _size = Observable(null);
  ProjectSizeModel? get size => _size.value;

  final Observable<bool> _cleaning = Observable(false);
  bool get cleaning => _cleaning.value;

  Future<void> loadSize({bool forceRefresh = false}) async {
    runInAction(() => _size.value = null);
    await _refreshSize(forceRefresh: forceRefresh);
  }

  Future<void> _refreshSize({bool forceRefresh = false}) async {
    final size = await ProjectRepo()
        .getProjectSize(project.path, forceRefresh: forceRefresh);
    runInAction(() => _size.value = size);
  }

  Future<void> cleanup() async {
    runInAction(() => _cleaning.value = true);

    final refreshTimer = Timer.periodic(
      _cleanupRefreshInterval,
      (_) => _refreshSize(forceRefresh: true),
    );

    await ProjectRepo().cleanupProject(project.path);

    refreshTimer.cancel();
    runInAction(() => _cleaning.value = false);
    await _refreshSize(forceRefresh: true);
  }

  Future<void> openInEditor() {
    return ProjectRepo().openInEditor(project.path);
  }
}
