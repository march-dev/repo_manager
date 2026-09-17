import '../../repo_manager.dart';

/// Business logic for the user-configured search directories Explorer/
/// Storage scan for projects.
class ProjectDirectoryUseCases {
  const ProjectDirectoryUseCases(this._repo, this._l10n);

  final ProjectDirectoryRepo _repo;
  final AppLocalizations _l10n;

  List<String> getProjectDirs() => _repo.getProjectDirs();

  Future<bool> addDir(String path, {bool recursive = false}) async {
    try {
      if (recursive) {
        await _repo.addProjectDirsRecursively(path);
      } else {
        await _repo.addProjectDir(path);
      }
      return true;
    } on Object catch (error, stackTrace) {
      logError('Add directory $path', error, stackTrace);
      SnackbarManager.show(_l10n.errorAddDirectory);
      return false;
    }
  }

  Future<bool> removeDir(String path) async {
    try {
      await _repo.removeProjectDir(path);
      return true;
    } on Object catch (error, stackTrace) {
      logError('Remove directory $path', error, stackTrace);
      SnackbarManager.show(_l10n.errorRemoveDirectory);
      return false;
    }
  }
}
