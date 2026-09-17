import '../../repo_manager.dart';

/// Business logic for pinning/unpinning a project as a favourite.
class FavouritesUseCases {
  const FavouritesUseCases(this._repo, this._l10n);

  final FavouritesRepo _repo;
  final AppLocalizations _l10n;

  Future<bool> toggleFavourite(ProjectModel project) async {
    try {
      await _repo.toggleFavoriteProject(project.path);
      return true;
    } on Object catch (error, stackTrace) {
      logError('Toggle favourite for "${project.name}"', error, stackTrace);
      SnackbarManager.show(_l10n.errorToggleFavourite(project.name));
      return false;
    }
  }
}
