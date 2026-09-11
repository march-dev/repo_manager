import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import '../../repo_manager.dart';

enum PreferredIde { vscode, androidStudio }

class ProjectRepo {
  const ProjectRepo._();
  static const instance = ProjectRepo._();
  factory ProjectRepo() => instance;

  static const _boxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static late final Box _box;

  static const _projectDirsKey = 'projectDirsKey';

  // Folders skipped while walking subdirectories for recursive discovery —
  // either not real project trees (dotfiles/IDE folders) or so large that
  // descending into them would be pure wasted work (dependency/build output).
  static const _skippedDirNames = {
    'node_modules',
    'build',
    '.dart_tool',
    'Pods',
    '.git',
    '.idea',
    '.vscode',
  };

  List<String> getProjectDirs() =>
      (_box.get(_projectDirsKey) as List?)?.cast<String>() ?? [];

  Future<void> addProjectDir(String path) async {
    final dirs = getProjectDirs();
    if (dirs.contains(path)) return;
    await _box.put(_projectDirsKey, [...dirs, path]);
  }

  Future<void> removeProjectDir(String path) async {
    final dirs = getProjectDirs()..remove(path);
    await _box.put(_projectDirsKey, dirs);
  }

  /// Walks the subtree under [rootPath] and adds every folder that directly
  /// contains at least one project (rather than just [rootPath] itself) as
  /// its own search directory. Once a folder qualifies, its own children are
  /// not descended into further — they're the project's own contents, not
  /// more containers to search.
  Future<int> addProjectDirsRecursively(String rootPath) async {
    final found = <String>[];
    await _collectProjectContainers(Directory(rootPath), found, isRoot: true);

    final dirs = getProjectDirs();
    var addedCount = 0;
    for (final path in found) {
      if (dirs.contains(path)) continue;
      dirs.add(path);
      addedCount++;
    }
    await _box.put(_projectDirsKey, dirs);

    return addedCount;
  }

  Future<void> _collectProjectContainers(
    Directory dir,
    List<String> found, {
    bool isRoot = false,
  }) async {
    if (!isRoot) {
      final name = dir.path.split(Platform.pathSeparator).last;
      if (name.startsWith('.') || _skippedDirNames.contains(name)) return;
    }
    if (!await dir.exists()) return;

    final childDirs = <Directory>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is Directory) childDirs.add(entity);
    }

    var hasDirectProject = false;
    final nonProjectChildren = <Directory>[];
    for (final child in childDirs) {
      if (await _isProjectDir(child)) {
        hasDirectProject = true;
      } else {
        nonProjectChildren.add(child);
      }
    }

    if (hasDirectProject) {
      found.add(dir.path);
      return;
    }

    for (final child in nonProjectChildren) {
      await _collectProjectContainers(child, found);
    }
  }

  Future<bool> _isProjectDir(Directory dir) {
    return File('${dir.path}/pubspec.yaml').exists();
  }

  Future<List<ProjectModel>> getProjects() async {
    final projects = <ProjectModel>[];
    final seenPaths = <String>{};

    for (final dirPath in getProjectDirs()) {
      for (final project in await _findProjectsIn(Directory(dirPath))) {
        if (seenPaths.add(project.path)) projects.add(project);
      }
    }

    return projects;
  }

  Future<List<ProjectModel>> _findProjectsIn(Directory dir) async {
    if (!await dir.exists()) return [];

    final favoritePaths = _getFavoriteProjectPaths();
    final projects = <ProjectModel>[];

    await for (final entity in dir.list()) {
      if (entity is! Directory) continue;
      if (!await _isProjectDir(entity)) continue;

      final iconFile = File(
        '${entity.path}/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      );

      projects.add(
        ProjectModel(
          name: entity.path.split(Platform.pathSeparator).last,
          path: entity.path,
          iconPath: await iconFile.exists() ? iconFile.path : '',
          sourceDir: dir.path,
          favourite: favoritePaths.contains(entity.path),
        ),
      );
    }

    return projects;
  }

  static const _favoriteProjectPathsKey = 'favoriteProjectPathsKey';

  List<String> _getFavoriteProjectPaths() =>
      (_box.get(_favoriteProjectPathsKey) as List?)?.cast<String>() ?? [];

  Future<void> toggleFavoriteProject(String projectPath) async {
    final favorites = _getFavoriteProjectPaths();
    if (!favorites.remove(projectPath)) favorites.add(projectPath);
    await _box.put(_favoriteProjectPathsKey, favorites);
  }

  static const _preferredIdeKey = 'preferredIdeKey';

  PreferredIde getPreferredIde() {
    final raw = _box.get(_preferredIdeKey) as String?;
    return PreferredIde.values.firstWhere(
      (ide) => ide.name == raw,
      orElse: () => PreferredIde.vscode,
    );
  }

  Future<void> setPreferredIde(PreferredIde ide) async {
    await _box.put(_preferredIdeKey, ide.name);
  }

  static const _cleanableRelativePaths = [
    'build',
    '.dart_tool',
    'ios/Pods',
    'macos/Pods',
    'node_modules',
  ];

  String _totalSizeCacheKey(String projectPath) =>
      'projectTotalSize:$projectPath';

  String _cleanableSizeCacheKey(String projectPath) =>
      'projectCleanableSize:$projectPath';

  Future<ProjectSizeModel> getProjectSize(
    String projectPath, {
    bool forceRefresh = false,
    CancellationToken? cancellationToken,
  }) async {
    if (!forceRefresh) {
      final cachedTotal = _box.get(_totalSizeCacheKey(projectPath)) as int?;
      final cachedCleanable =
          _box.get(_cleanableSizeCacheKey(projectPath)) as int?;
      if (cachedTotal != null && cachedCleanable != null) {
        return ProjectSizeModel(
            totalBytes: cachedTotal, cacheBytes: cachedCleanable);
      }
    }

    final total = await _dirSize(Directory(projectPath), cancellationToken);
    final cleanable =
        await _calculateCleanableSize(projectPath, cancellationToken);

    // A cancelled scan may have stopped partway through a directory, so its
    // totals don't reflect the real size — don't cache them.
    if (cancellationToken?.isCancelled ?? false) {
      return ProjectSizeModel(totalBytes: total, cacheBytes: cleanable);
    }

    await _box.put(_totalSizeCacheKey(projectPath), total);
    await _box.put(_cleanableSizeCacheKey(projectPath), cleanable);

    return ProjectSizeModel(totalBytes: total, cacheBytes: cleanable);
  }

  Future<int> _calculateCleanableSize(
    String projectPath,
    CancellationToken? cancellationToken,
  ) async {
    var size = 0;
    for (final relativePath in _cleanableRelativePaths) {
      if (cancellationToken?.isCancelled ?? false) break;
      size += await _dirSize(
        Directory('$projectPath/$relativePath'),
        cancellationToken,
      );
    }
    return size;
  }

  Future<int> _dirSize(
    Directory dir,
    CancellationToken? cancellationToken,
  ) async {
    if (!await dir.exists()) return 0;

    var size = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      // Breaking out of an `await for` cancels its underlying subscription,
      // so a superseded scan actually stops listing the filesystem instead
      // of running to completion for a result nobody will use.
      if (cancellationToken?.isCancelled ?? false) break;
      if (entity is! File) continue;
      try {
        size += await entity.length();
      } on FileSystemException {
        // Skip files we can't stat (e.g. broken symlinks, permission issues).
      }
    }
    return size;
  }

  Future<void> cleanupProject(String projectPath) async {
    try {
      await Process.run('flutter', ['clean'], workingDirectory: projectPath);
    } on ProcessException {
      // flutter not on PATH; fall through to manual cleanup below.
    }

    for (final relativePath in _cleanableRelativePaths) {
      final dir = Directory('$projectPath/$relativePath');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  }

  Future<void> openInEditor(String projectPath) async {
    try {
      switch (getPreferredIde()) {
        case PreferredIde.vscode:
          await Process.run('code', [projectPath]);
        case PreferredIde.androidStudio:
          await Process.run('open', ['-a', 'Android Studio', projectPath]);
      }
    } on ProcessException {
      // Preferred IDE's launcher isn't available on PATH; nothing we can do.
    }
  }

  Future<void> openInVsCode(String projectPath) async {
    try {
      await Process.run('code', [projectPath]);
    } on ProcessException {
      // VS Code CLI ("code") isn't on PATH; nothing we can do.
    }
  }
}
