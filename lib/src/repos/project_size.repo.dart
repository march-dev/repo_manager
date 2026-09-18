import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import '../../repo_manager.dart';

/// A project's on-disk size (total, and how much of it is reclaimable
/// cache/build output), and cleaning that reclaimable part away.
class ProjectSizeRepo {
  const ProjectSizeRepo({required Box box}) : _box = box;

  final Box _box;

  // Covers the common cache/build-output directory for every language
  // ProjectLanguage detects, not just Dart/Flutter — a project only has
  // whichever of these actually apply to it, so scanning/deleting the full
  // list is harmless for the rest (they just won't exist).
  static const _cleanableRelativePaths = [
    // Dart / Flutter
    'build',
    '.dart_tool',
    'ios/Pods',
    'macos/Pods',
    // JavaScript / TypeScript / Vue.js / React
    'node_modules',
    'dist',
    // Java / Kotlin (Gradle, Maven) — also Rust's Cargo, which defaults to
    // the same 'target' name for its own build output.
    '.gradle',
    'target',
    // Objective-C / Swift (Xcode, Swift Package Manager, CocoaPods)
    'Pods',
    '.build',
    'DerivedData',
    // C++ (CMake's own default is 'build', already listed above; CLion's
    // default project settings use these instead)
    'cmake-build-debug',
    'cmake-build-release',
    // C# (.NET)
    'bin',
    'obj',
    // PHP (Composer) — also Go's own optional vendor/ directory, when a
    // project chooses to vendor its dependencies instead of relying on the
    // global module cache.
    'vendor',
    // Python (pip/venv, Poetry, pytest) — 'build'/'dist' (setuptools) and
    // '__pycache__' (compiled bytecode, though these usually nest one per
    // package rather than sitting at the project root) are already/also
    // covered above.
    'venv',
    '.venv',
    '__pycache__',
    '.pytest_cache',
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
    try {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        // Breaking out of an `await for` cancels its underlying
        // subscription, so a superseded scan actually stops listing the
        // filesystem instead of running to completion for a result nobody
        // will use.
        if (cancellationToken?.isCancelled ?? false) break;
        if (entity is! File) continue;
        try {
          size += await entity.length();
        } on FileSystemException {
          // Skip files we can't stat (e.g. broken symlinks, permission
          // issues).
        }
      }
    } on FileSystemException {
      // dir.list()'s stream itself — not just entity.length() — can throw
      // mid-scan: a subdirectory becoming permission-denied, or one of
      // this repo's own cleanable dirs (build/, node_modules/, etc.) being
      // deleted concurrently by cleanupProject while this scan is still
      // walking it. Return the partial total summed so far rather than
      // losing the whole project's size to one bad subdirectory.
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
}
