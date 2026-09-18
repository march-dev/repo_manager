import 'package:flutter/foundation.dart';

import '../../repo_manager.dart';

/// Business logic for the user-configured search directories Explorer/
/// Storage scan for projects.
class ProjectDirectoryUseCases {
  const ProjectDirectoryUseCases(this._repo, this._l10n);

  final ProjectDirectoryRepo _repo;
  final AppLocalizations _l10n;

  List<String> getProjectDirs() => _repo.getProjectDirs();

  /// Bumped on every successful add/remove — ExplorerState/StorageState
  /// each listen for this to reload their own independent project list,
  /// rather than only ever reflecting whatever the directories were at
  /// app launch.
  ValueListenable<int> get dirsVersion => _repo.dirsVersion;

  Future<bool> addDir(String path, {bool recursive = false}) async {
    try {
      if (recursive) {
        await _repo.addProjectDirsRecursively(path);
      } else {
        await _repo.addProjectDir(path);
      }
      return true;
    } catch (error, stackTrace) {
      logError('Add directory $path', error, stackTrace);
      SnackbarManager.show(_l10n.errorAddDirectory);
      return false;
    }
  }

  Future<bool> removeDir(String path) async {
    try {
      await _repo.removeProjectDir(path);
      return true;
    } catch (error, stackTrace) {
      logError('Remove directory $path', error, stackTrace);
      SnackbarManager.show(_l10n.errorRemoveDirectory);
      return false;
    }
  }
}
