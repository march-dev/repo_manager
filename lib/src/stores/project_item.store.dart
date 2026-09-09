import 'dart:async';

import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'project_item.store.g.dart';

class ProjectItemStore = _ProjectItemStoreBase with _$ProjectItemStore;

abstract class _ProjectItemStoreBase with Store {
  _ProjectItemStoreBase(this.project, {bool forceRefresh = false}) {
    loadSize(forceRefresh: forceRefresh);
  }

  static const _cleanupRefreshInterval = Duration(seconds: 1);

  final ProjectModel project;

  @observable
  ProjectSizeModel? size;

  @observable
  bool cleaning = false;

  @action
  Future<void> loadSize({bool forceRefresh = false}) async {
    size = null;
    await _refreshSize(forceRefresh: forceRefresh);
  }

  @action
  Future<void> _refreshSize({bool forceRefresh = false}) async {
    final nextSize = await ProjectRepo()
        .getProjectSize(project.path, forceRefresh: forceRefresh);
    size = nextSize;
  }

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
    return ProjectRepo().openInEditor(project.path);
  }
}
