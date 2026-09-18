import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/project_language_detector.dart';
import '../utils/error_logging.util.dart';

/// The user-configured search directories Explorer/Storage scan for
/// projects (see ProjectScanner.getProjects).
class ProjectDirectoryRepo {
  ProjectDirectoryRepo({
    required Box box,
    required ProjectLanguageDetector languageDetector,
  })  : _box = box,
        _languageDetector = languageDetector;

  final Box _box;
  final ProjectLanguageDetector _languageDetector;

  // Bumped on every successful add/remove so any interested store — see
  // ExplorerState/StorageState, which each own an independent scan/copy of
  // the project list rather than sharing one — knows to reload instead of
  // only ever reflecting whatever the directory list was at app launch.
  final dirsVersion = ValueNotifier<int>(0);

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
    dirsVersion.value++;
  }

  Future<void> removeProjectDir(String path) async {
    final dirs = getProjectDirs()..remove(path);
    await _box.put(_projectDirsKey, dirs);
    dirsVersion.value++;
  }

  /// Walks the subtree under [rootPath] and adds every folder that directly
  /// contains at least one project (rather than just [rootPath] itself) as
  /// its own search directory. A qualifying folder's own project-child
  /// subdirectories aren't descended into further — they're the project's
  /// own contents, not more containers to search — but its other,
  /// non-project children still are, since a folder having one project
  /// directly inside it says nothing about whether its siblings hide more
  /// containers several levels further down.
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
    if (addedCount > 0) dirsVersion.value++;

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
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is Directory) childDirs.add(entity);
      }
    } on FileSystemException catch (error, stackTrace) {
      // Unreadable directory (permissions, broken symlink, ...) — treat as
      // having no children rather than aborting the whole recursive walk.
      logError('List directory ${dir.path}', error, stackTrace);
      return;
    }

    var hasDirectProject = false;
    final nonProjectChildren = <Directory>[];
    for (final child in childDirs) {
      if (await _languageDetector.isProjectDir(child)) {
        hasDirectProject = true;
      } else {
        nonProjectChildren.add(child);
      }
    }

    if (hasDirectProject) {
      found.add(dir.path);
    }

    // A directory can be both a container (it has a direct-child project)
    // and hold plain, non-project sibling folders that themselves wrap
    // deeper containers further down — e.g. ~/Projects having one project
    // directly inside it doesn't mean every OTHER child is empty of them.
    // Only the children that qualified as projects above are skipped
    // (that's the project's own contents, not more containers to search);
    // everything else is still worth descending into regardless of
    // whether this level already found something.
    for (final child in nonProjectChildren) {
      await _collectProjectContainers(child, found);
    }
  }
}
