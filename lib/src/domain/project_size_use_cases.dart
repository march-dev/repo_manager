import '../../repo_manager.dart';

/// Business logic for computing a project's on-disk size and cleaning up
/// its reclaimable cache/build output.
class ProjectSizeUseCases {
  const ProjectSizeUseCases(this._repo, this._l10n);

  final ProjectSizeRepo _repo;
  final AppLocalizations _l10n;

  /// Returns null (rather than throwing) on failure — the caller keeps
  /// whatever size it last showed rather than clearing it to nothing.
  Future<ProjectSizeModel?> getProjectSize(
    String projectPath,
    String projectName, {
    bool forceRefresh = false,
    CancellationToken? cancellationToken,
  }) async {
    try {
      return await _repo.getProjectSize(
        projectPath,
        forceRefresh: forceRefresh,
        cancellationToken: cancellationToken,
      );
    } catch (error, stackTrace) {
      logError('Get size for "$projectName"', error, stackTrace);
      SnackbarManager.show(_l10n.errorGetProjectSize(projectName));
      return null;
    }
  }

  Future<bool> cleanupProject(String projectPath, String projectName) async {
    try {
      await _repo.cleanupProject(projectPath);
      return true;
    } catch (error, stackTrace) {
      logError('Clean up "$projectName"', error, stackTrace);
      SnackbarManager.show(_l10n.errorCleanupProject(projectName));
      return false;
    }
  }
}
