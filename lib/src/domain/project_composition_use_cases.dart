import '../../repo_manager.dart';

/// Business logic for computing a project's language/framework composition
/// by bytes.
class ProjectCompositionUseCases {
  const ProjectCompositionUseCases(this._repo, this._l10n);

  final ProjectCompositionRepo _repo;
  final AppLocalizations _l10n;

  /// Returns null (rather than throwing) on failure — the caller keeps
  /// whatever composition it last showed rather than clearing it to
  /// nothing.
  Future<Map<ProjectLanguage, int>?> getLanguageComposition(
    String projectPath,
    String projectName, {
    bool forceRefresh = false,
    CancellationToken? cancellationToken,
  }) async {
    try {
      return await _repo.getLanguageComposition(
        projectPath,
        forceRefresh: forceRefresh,
        cancellationToken: cancellationToken,
      );
    } catch (error, stackTrace) {
      logError(
        'Get language composition for "$projectName"',
        error,
        stackTrace,
      );
      SnackbarManager.show(_l10n.errorGetLanguageComposition(projectName));
      return null;
    }
  }

  /// Same "returns null on failure" contract as [getLanguageComposition].
  Future<Map<ProjectFramework, int>?> getFrameworkComposition(
    ProjectModel project, {
    bool forceRefresh = false,
    CancellationToken? cancellationToken,
  }) async {
    try {
      return await _repo.getFrameworkComposition(
        project,
        forceRefresh: forceRefresh,
        cancellationToken: cancellationToken,
      );
    } catch (error, stackTrace) {
      logError(
        'Get framework composition for "${project.name}"',
        error,
        stackTrace,
      );
      SnackbarManager.show(_l10n.errorGetFrameworkComposition(project.name));
      return null;
    }
  }
}
