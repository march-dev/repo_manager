import 'package:hive_flutter/hive_flutter.dart';

/// User-created collections and which projects belong to each — see
/// CollectionsUseCases/CollectionsState for the layer on top of this.
class CollectionsRepo {
  const CollectionsRepo({required Box box}) : _box = box;

  final Box _box;

  static const _collectionsKey = 'collectionsKey';

  // Collection name -> the (ordered) project paths in it. Names double as
  // ids — there's no separate Collection model — so creating one just
  // reserves an empty entry here, ready for addProjectToCollection to
  // fill in later.
  Map<String, List<String>> _getCollections() {
    final raw = _box.get(_collectionsKey) as Map?;
    if (raw == null) return {};
    return raw.map(
      (key, value) => MapEntry(key as String, (value as List).cast<String>()),
    );
  }

  Future<void> _putCollections(Map<String, List<String>> collections) async {
    await _box.put(_collectionsKey, collections);
  }

  List<String> getCollectionNames() => _getCollections().keys.toList();

  List<String> getProjectCollections(String projectPath) => [
        for (final entry in _getCollections().entries)
          if (entry.value.contains(projectPath)) entry.key,
      ];

  Future<void> createCollection(String name) async {
    final collections = _getCollections();
    collections.putIfAbsent(name, () => []);
    await _putCollections(collections);
  }

  Future<void> addProjectToCollection(String projectPath, String name) async {
    final collections = _getCollections();
    final members = collections.putIfAbsent(name, () => []);
    if (!members.contains(projectPath)) members.add(projectPath);
    await _putCollections(collections);
  }

  Future<void> removeProjectFromCollection(
    String projectPath,
    String name,
  ) async {
    final collections = _getCollections();
    collections[name]?.remove(projectPath);
    await _putCollections(collections);
  }

  // Merges into an existing collection sharing newName rather than
  // silently failing or overwriting it, so renaming to a name that
  // happens to already exist just folds the two together.
  Future<void> renameCollection(String oldName, String newName) async {
    if (oldName == newName) return;
    final collections = _getCollections();
    final members = collections.remove(oldName);
    if (members == null) return;
    final existing = collections[newName];
    collections[newName] =
        existing == null ? members : <String>{...existing, ...members}.toList();
    await _putCollections(collections);
  }

  // Only forgets the grouping — the member projects themselves are
  // untouched, they just stop being reported by getProjectCollections and
  // so fall back to Explorer's "Uncategorized" bucket.
  Future<void> deleteCollection(String name) async {
    final collections = _getCollections();
    collections.remove(name);
    await _putCollections(collections);
  }
}
