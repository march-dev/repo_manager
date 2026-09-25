import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import '../../repo_manager.dart';

/// A project's composition by on-disk bytes — how many bytes of source
/// code under a project's own directory (recursively — for a monorepo
/// this already covers every member package's files too, same as
/// [ProjectSizeRepo.getProjectSize]) belong to each [ProjectLanguage] (by
/// file extension) and each [ProjectFramework] (by which project, of
/// every one in the tree, actually contains that file). The same approach
/// GitHub's own repo language bar uses for language — bytes of recognised
/// source, not file/project count — extended to framework: a project's
/// framework isn't a per-*file* signal the way its language is (a file
/// extension says "this is a TypeScript file", never "this is the React
/// one"), but every file still belongs to exactly one project in the
/// tree, and that project has (at most) one framework, so weighting by
/// that owning project's own share of the tree's bytes gives the same
/// "how much of this tree, by actual size" reading language composition
/// already has — rather than a plain "one project in this tree, one
/// vote" tally, which treats a single huge package and a tiny one-file
/// one as equally significant.
///
/// Only extensions this app can actually map to a [ProjectLanguage] count
/// at all — config, docs, assets, lockfiles, ... are ignored entirely
/// rather than lumped into some catch-all "other" bucket nobody asked for.
class ProjectCompositionRepo {
  const ProjectCompositionRepo({required Box box}) : _box = box;

  final Box _box;

  // The same "generated/vendored, not authored" directories
  // ProjectScanner itself skips while discovering projects (see
  // ProjectScanner._skippedDirNames) plus the language-specific build/
  // dependency dirs project_size.repo.dart's own _cleanableRelativePaths
  // already knows to leave out of a project's own size — walking into
  // either would count someone else's vendored code (a whole node_modules
  // tree, a Pods checkout, ...) as if it were this project's own
  // composition.
  static const _excludedDirNames = {
    'node_modules', 'build', '.dart_tool', 'Pods', '.git', '.idea',
    '.vscode', //
    'dist',
    '.gradle', 'target',
    '.build', 'DerivedData',
    'cmake-build-debug', 'cmake-build-release',
    'bin', 'obj',
    'vendor',
    'venv', '.venv', '__pycache__', '.pytest_cache',
  };

  // A file extension has to be unambiguous on its own (no per-file content
  // sniffing, unlike ProjectLanguageDetector's own whole-project marker
  // files) to be worth mapping here — '.h' is genuinely ambiguous between
  // C/C++/Objective-C, but this app doesn't recognise plain C as its own
  // language, so it's counted as C++ (the more common of the two this app
  // does distinguish) rather than left out entirely.
  static const Map<String, ProjectLanguage> _extensionLanguages = {
    'dart': ProjectLanguage.dart,
    'java': ProjectLanguage.java,
    'kt': ProjectLanguage.kotlin,
    'kts': ProjectLanguage.kotlin,
    'm': ProjectLanguage.objectiveC,
    'mm': ProjectLanguage.objectiveC,
    'swift': ProjectLanguage.swift,
    'cpp': ProjectLanguage.cpp,
    'cc': ProjectLanguage.cpp,
    'cxx': ProjectLanguage.cpp,
    'hpp': ProjectLanguage.cpp,
    'hh': ProjectLanguage.cpp,
    'hxx': ProjectLanguage.cpp,
    'h': ProjectLanguage.cpp,
    'cs': ProjectLanguage.csharp,
    'js': ProjectLanguage.javascript,
    'jsx': ProjectLanguage.javascript,
    'mjs': ProjectLanguage.javascript,
    'cjs': ProjectLanguage.javascript,
    'ts': ProjectLanguage.typescript,
    'tsx': ProjectLanguage.typescript,
    'mts': ProjectLanguage.typescript,
    'cts': ProjectLanguage.typescript,
    'go': ProjectLanguage.go,
    'rs': ProjectLanguage.rust,
    'php': ProjectLanguage.php,
    'py': ProjectLanguage.python,
  };

  String _languageCacheKey(String projectPath) =>
      'languageComposition:$projectPath';

  String _frameworkCacheKey(String projectPath) =>
      'frameworkComposition:$projectPath';

  Future<Map<ProjectLanguage, int>> getLanguageComposition(
    String projectPath, {
    bool forceRefresh = false,
    CancellationToken? cancellationToken,
  }) async {
    if (!forceRefresh) {
      final cached = _box.get(_languageCacheKey(projectPath)) as Map?;
      if (cached != null) return _decode(cached, ProjectLanguage.values);
    }

    final composition = await _scanLanguages(projectPath, cancellationToken);

    // A cancelled scan may have stopped partway through the tree, so it
    // doesn't reflect the real composition — don't cache it (same
    // reasoning as ProjectSizeRepo.getProjectSize).
    if (cancellationToken?.isCancelled ?? false) return composition;

    await _box.put(_languageCacheKey(projectPath), _encode(composition));
    return composition;
  }

  /// [project] and its whole subPackages tree together define which parts
  /// of the on-disk tree belong to which framework — this needs the whole
  /// [ProjectModel], not just a path, so it knows where each member
  /// project's own directory starts (see [_frameworkOwners]).
  Future<Map<ProjectFramework, int>> getFrameworkComposition(
    ProjectModel project, {
    bool forceRefresh = false,
    CancellationToken? cancellationToken,
  }) async {
    if (!forceRefresh) {
      final cached = _box.get(_frameworkCacheKey(project.path)) as Map?;
      if (cached != null) return _decode(cached, ProjectFramework.values);
    }

    final composition = await _scanFrameworks(project, cancellationToken);

    if (cancellationToken?.isCancelled ?? false) return composition;

    await _box.put(_frameworkCacheKey(project.path), _encode(composition));
    return composition;
  }

  Map<T, int> _decode<T extends Enum>(Map cached, List<T> values) {
    final byName = values.asNameMap();
    return {
      for (final entry in cached.entries)
        if (byName[entry.key as String] case final value?)
          value: entry.value as int,
    };
  }

  Map<String, int> _encode<T extends Enum>(Map<T, int> composition) => {
        for (final entry in composition.entries) entry.key.name: entry.value,
      };

  Future<Map<ProjectLanguage, int>> _scanLanguages(
    String projectPath,
    CancellationToken? cancellationToken,
  ) async {
    final composition = <ProjectLanguage, int>{};
    await _walkSourceFiles(
      projectPath,
      cancellationToken,
      onFile: (entity, bytes) {
        final language = _extensionLanguages[_extensionOf(entity.path)];
        if (language == null) return;
        composition[language] = (composition[language] ?? 0) + bytes;
      },
    );
    return composition;
  }

  Future<Map<ProjectFramework, int>> _scanFrameworks(
    ProjectModel project,
    CancellationToken? cancellationToken,
  ) async {
    final composition = <ProjectFramework, int>{};
    final owners = _frameworkOwners(project);
    if (owners.isEmpty) return composition;

    await _walkSourceFiles(
      project.path,
      cancellationToken,
      onFile: (entity, bytes) {
        if (_extensionLanguages[_extensionOf(entity.path)] == null) return;

        for (final owner in owners) {
          if (!entity.path.startsWith(owner.path)) continue;
          composition[owner.framework!] =
              (composition[owner.framework!] ?? 0) + bytes;
          return;
        }
      },
    );
    return composition;
  }

  /// Every project in the tree that actually has a framework, longest
  /// [ProjectModel.path] first — a file under a nested member's own
  /// directory should count toward *that member's* framework, not its
  /// (necessarily shorter-pathed) parent's, so the first path prefix
  /// match in this order is always the most specific one.
  List<ProjectModel> _frameworkOwners(ProjectModel project) {
    final owners = [project, ...project.subPackages.flatProjects]
        .where((p) => p.framework != null)
        .toList()
      ..sort((a, b) => b.path.length.compareTo(a.path.length));
    return owners;
  }

  Future<void> _walkSourceFiles(
    String projectPath,
    CancellationToken? cancellationToken, {
    required void Function(File entity, int bytes) onFile,
  }) async {
    final dir = Directory(projectPath);
    if (!await dir.exists()) return;

    try {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        // Breaking out of an `await for` cancels its underlying
        // subscription, so a superseded scan actually stops listing the
        // filesystem instead of running to completion for a result
        // nobody will use — this repo's own walk still runs on the
        // caller's isolate (unlike ProjectSizeRepo's, see its own doc for
        // why that one moved and lost this same mid-flight check).
        if (cancellationToken?.isCancelled ?? false) break;
        if (entity is! File) continue;
        if (_isExcluded(entity.path, projectPath)) continue;

        try {
          onFile(entity, await entity.length());
        } on FileSystemException {
          // Skip files we can't stat (e.g. broken symlinks, permission
          // issues).
        }
      }
    } on FileSystemException {
      // dir.list()'s stream itself can throw mid-scan (e.g. a
      // permission-denied subdirectory) — partial composition kept
      // rather than losing it all to one bad subdirectory.
    }
  }

  bool _isExcluded(String path, String projectPath) {
    final relative = path.substring(projectPath.length);
    return relative
        .split(Platform.pathSeparator)
        .any(_excludedDirNames.contains);
  }

  String? _extensionOf(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dotIndex = name.lastIndexOf('.');
    // dotIndex <= 0 covers both "no dot at all" and a dotfile like
    // ".gitignore" (a leading dot isn't a "<name>.<ext>" split) — neither
    // has a real extension to map.
    if (dotIndex <= 0) return null;
    return name.substring(dotIndex + 1).toLowerCase();
  }
}
