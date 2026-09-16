import 'package:hive_flutter/hive_flutter.dart';

/// A project pinned as a favourite — a flat list of paths in the shared
/// Hive box, re-projected onto [ProjectModel.favourite] whenever projects
/// are (re)scanned (see ProjectScanner).
class FavouritesRepo {
  const FavouritesRepo({required Box box}) : _box = box;

  final Box _box;

  static const _favoriteProjectPathsKey = 'favoriteProjectPathsKey';

  List<String> getFavoriteProjectPaths() =>
      (_box.get(_favoriteProjectPathsKey) as List?)?.cast<String>() ?? [];

  Future<void> toggleFavoriteProject(String projectPath) async {
    final favorites = getFavoriteProjectPaths();
    if (!favorites.remove(projectPath)) favorites.add(projectPath);
    await _box.put(_favoriteProjectPathsKey, favorites);
  }
}
