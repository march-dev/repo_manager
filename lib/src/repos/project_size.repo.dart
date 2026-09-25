import 'dart:io';
import 'dart:isolate';

import 'package:hive_flutter/hive_flutter.dart';

import '../../repo_manager.dart';

// Covers the common cache/build-output directory for every language
// ProjectLanguage detects, not just Dart/Flutter — a project only has
// whichever of these actually apply to it, so scanning/deleting the full
// list is harmless for the rest (they just won't exist). Top-level (not a
// class member) so _computeCleanableSize below — which runs on its own
// isolate, see its own doc — can reference it directly without needing it
// passed in as a parameter.
const _cleanableRelativePaths = [
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

/// A project's on-disk size (total, and how much of it is reclaimable
/// cache/build output), and cleaning that reclaimable part away.
///
/// The two real recursive walks behind [getProjectSize] (the whole
/// project, and each of [_cleanableRelativePaths] under it) each run on
/// their own isolate (see [_isolateDirSize]/[_isolateCleanableSize]'s own
/// docs) — a big project's own walk (deep node_modules/DerivedData/...)
/// is real, possibly-slow Dart-side iteration that would otherwise jank
/// this app's own UI isolate while it runs, the same reasoning
/// SystemCleanerRepo's own per-entry walk does this.
///
/// [cancellationToken] can no longer stop a walk *mid-flight* the way it
/// used to before this moved to isolates — isolates share no memory, so a
/// walk already handed off to one has no way to observe `.cancel()` being
/// called back on the caller's own isolate afterward. It still guards the
/// same thing it always has, though: [getProjectSize] itself checks it
/// once the walk (however long that took) resolves, and simply never
/// caches/returns a result for a scan that's already been superseded by a
/// newer one, the same as before. The one behavior actually lost is the
/// superseded walk no longer freeing up its own `runWithConcurrency` slot
/// early — it now keeps running (harmlessly, off the UI isolate) until it
/// finishes on its own.
class ProjectSizeRepo {
  const ProjectSizeRepo({required Box box}) : _box = box;

  final Box _box;

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

    // Sequential, not concurrent — StorageState's own runWithConcurrency
    // already bounds how many *projects* are being sized at once to
    // Platform.numberOfProcessors; also running both of a single
    // project's own walks at once would let that cap double in practice.
    final total = await _isolateDirSize(projectPath);
    final cleanable = await _isolateCleanableSize(projectPath);

    // A cancelled scan's own walks above already ran to completion
    // regardless (see this repo's own doc) — this is what still keeps a
    // superseded result from ever overwriting one a newer scan already
    // wrote.
    if (cancellationToken?.isCancelled ?? false) {
      return ProjectSizeModel(totalBytes: total, cacheBytes: cleanable);
    }

    await _box.put(_totalSizeCacheKey(projectPath), total);
    await _box.put(_cleanableSizeCacheKey(projectPath), cleanable);

    return ProjectSizeModel(totalBytes: total, cacheBytes: cleanable);
  }

  // Isolate.run spawns a fresh isolate, runs the given (necessarily
  // top-level — see _computeDirSize's own doc) computation on it, and
  // shuts it back down once the result comes back.
  Future<int> _isolateDirSize(String path) =>
      Isolate.run(() => _computeDirSize(path));

  Future<int> _isolateCleanableSize(String projectPath) =>
      Isolate.run(() => _computeCleanableSize(projectPath));

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

// Top-level (not an instance method of ProjectSizeRepo) — Isolate.run's
// own computation closure can only capture plain, sendable values (a path
// string), never `this`/a Box/anything else instance-held, which is why
// _isolateCleanableSize above hands this a bare String rather than
// calling an instance method directly.
Future<int> _computeCleanableSize(String projectPath) async {
  var size = 0;
  for (final relativePath in _cleanableRelativePaths) {
    size += await _computeDirSize('$projectPath/$relativePath');
  }
  return size;
}

// Same shape as this repo's own _dirSize used to be, minus the
// CancellationToken checks — no longer meaningful once handed off to a
// separate isolate (see ProjectSizeRepo's own doc) — sums real file bytes
// recursively, tolerating permission errors on individual files or the
// directory listing itself rather than losing the whole total to one bad
// subdirectory.
Future<int> _computeDirSize(String path) async {
  final dir = Directory(path);
  if (!await dir.exists()) return 0;

  var size = 0;
  try {
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
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
