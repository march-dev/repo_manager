import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:yaml/yaml.dart';

import '../../repo_manager.dart';

/// A detected monorepo/workspace root: which tool manages it, and the
/// (unresolved) glob patterns its config declares for member packages —
/// e.g. Melos's `packages:` list, or npm/yarn/pnpm's `workspaces` field.
class _MonorepoInfo {
  const _MonorepoInfo(this.tool, this.packageGlobs);

  final MonorepoTool tool;
  final List<String> packageGlobs;
}

/// Builds a project (and its monorepo member-package tree, if any) by
/// walking the filesystem — language/framework detection itself lives in
/// [ProjectLanguageDetector] (a separate, no-dependency class both this and
/// ProjectDirectoryRepo depend on), so the two repos don't have to depend
/// on each other.
class ProjectScanner {
  ProjectScanner({
    required Box box,
    required ProjectLanguageDetector languageDetector,
    required ProjectDirectoryRepo directoryRepo,
    required ProjectIconFinder iconFinder,
    required ProjectModelCodec codec,
    required FavouritesRepo favouritesRepo,
  })  : _box = box,
        _languageDetector = languageDetector,
        _directoryRepo = directoryRepo,
        _iconFinder = iconFinder,
        _codec = codec,
        _favouritesRepo = favouritesRepo;

  final Box _box;
  final ProjectLanguageDetector _languageDetector;
  final ProjectDirectoryRepo _directoryRepo;
  final ProjectIconFinder _iconFinder;
  final ProjectModelCodec _codec;
  final FavouritesRepo _favouritesRepo;

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

  /// Identifies [dir] as a monorepo/workspace root by looking for each
  /// tool's own config file, in the order most likely to give a precise
  /// member-package list first. Turborepo/Nx don't list packages
  /// themselves — they layer on top of npm/yarn/pnpm workspaces (or, for
  /// Nx, a conventional apps//libs//packages/ layout) — so those two fall
  /// through to [_readNodeWorkspaceGlobs] for the actual glob list.
  Future<_MonorepoInfo?> _detectMonorepo(Directory dir) async {
    final melosFile = File('${dir.path}/melos.yaml');
    if (await melosFile.exists()) {
      return _MonorepoInfo(
        MonorepoTool.melos,
        await _readMelosPackageGlobs(melosFile),
      );
    }

    final lernaFile = File('${dir.path}/lerna.json');
    if (await lernaFile.exists()) {
      return _MonorepoInfo(
        MonorepoTool.lerna,
        await _readLernaPackageGlobs(lernaFile),
      );
    }

    if (await File('${dir.path}/turbo.json').exists()) {
      return _MonorepoInfo(
        MonorepoTool.turborepo,
        await _readNodeWorkspaceGlobs(dir) ?? const ['*'],
      );
    }

    if (await File('${dir.path}/nx.json').exists()) {
      return _MonorepoInfo(
        MonorepoTool.nx,
        await _readNodeWorkspaceGlobs(dir) ??
            const ['apps/*', 'libs/*', 'packages/*'],
      );
    }

    return null;
  }

  /// Melos's own `packages:` list in melos.yaml — a list of glob patterns
  /// (e.g. `packages/*`), not a fixed folder name, so member packages can
  /// live wherever a given repo actually keeps them.
  Future<List<String>> _readMelosPackageGlobs(File file) async {
    try {
      final doc = loadYaml(await file.readAsString());
      final packages = doc is Map ? doc['packages'] : null;
      if (packages is List) return packages.map((e) => '$e').toList();
    } on Object {
      // Malformed YAML — fall through to the conventional default below
      // rather than treating this as "not a monorepo at all".
    }
    return const ['packages/*'];
  }

  /// Lerna's own `packages` list in lerna.json (JSON, unlike Melos's YAML),
  /// defaulting to Lerna's own conventional layout when the key is missing
  /// (a bare `{}` lerna.json is valid and common).
  Future<List<String>> _readLernaPackageGlobs(File file) async {
    try {
      final json = jsonDecode(await file.readAsString());
      final packages = json is Map ? json['packages'] : null;
      if (packages is List) return packages.map((e) => '$e').toList();
    } on Object {
      // Malformed JSON — fall through to the conventional default.
    }
    return const ['packages/*'];
  }

  /// npm/yarn/pnpm's own workspace glob list — pnpm keeps it in a separate
  /// pnpm-workspace.yaml, while npm/yarn put it in package.json's own
  /// `workspaces` field (either a plain array, or `{ "packages": [...] }`
  /// for yarn's older object form). Returns null (rather than a default)
  /// when neither is found, so callers can tell "not configured" apart
  /// from "configured with an empty list".
  Future<List<String>?> _readNodeWorkspaceGlobs(Directory dir) async {
    final pnpmFile = File('${dir.path}/pnpm-workspace.yaml');
    if (await pnpmFile.exists()) {
      try {
        final doc = loadYaml(await pnpmFile.readAsString());
        final packages = doc is Map ? doc['packages'] : null;
        if (packages is List) return packages.map((e) => '$e').toList();
      } on Object {
        // Malformed YAML — fall through to package.json below.
      }
    }

    final packageJsonFile = File('${dir.path}/package.json');
    if (!await packageJsonFile.exists()) return null;
    try {
      final json = jsonDecode(await packageJsonFile.readAsString());
      final workspaces = json is Map ? json['workspaces'] : null;
      if (workspaces is List) return workspaces.map((e) => '$e').toList();
      if (workspaces is Map && workspaces['packages'] is List) {
        return (workspaces['packages'] as List).map((e) => '$e').toList();
      }
    } on Object {
      // Malformed JSON — nothing more to try.
    }
    return null;
  }

  /// Resolves workspace glob patterns to actual member directories. Only
  /// supports the trailing-wildcard form every one of these tools' own
  /// docs lead with (`packages/*`, `apps/**`) — listing whatever's
  /// directly inside the glob's parent segment — plus a bare path with no
  /// wildcard at all (a single named package). More exotic glob syntax
  /// (nested `**`, brace expansion, negation) isn't worth the complexity
  /// this scan only needs "good enough to find the packages" for.
  /// [exactPaths] (a subset of the returned paths) names every resolved
  /// directory that came from a literal, non-wildcard glob entry — e.g.
  /// `app_packages/app_design_system` — as opposed to one resolved by
  /// listing a wildcard's matching children (`packages/*`). Only the
  /// former are candidates for sibling-scanning (see [_findSubPackages]):
  /// a wildcard entry already covers every sibling by construction, so
  /// there'd be nothing more to find by also checking its parent.
  Future<({List<Directory> dirs, Set<String> exactPaths})>
      _resolveWorkspaceGlobs(
    Directory root,
    List<String> globs,
  ) async {
    final resolved = <String, Directory>{};
    final exactPaths = <String>{};

    for (final rawGlob in globs) {
      // A trailing slash (valid, and not uncommon, in a workspaces/packages
      // list — e.g. "packages/foo/") would otherwise survive into the
      // resolved Directory's own path, and from there into the project's
      // *name* (split-on-separator's last segment of a trailing-slash path
      // is '') — an empty-named row rather than an error, so it's easy to
      // miss the cause of. Stripped once here so it can't leak downstream.
      final glob = rawGlob.trim().replaceAll(RegExp(r'/+$'), '');
      if (glob.isEmpty || glob.startsWith('!')) continue;

      final starIndex = glob.indexOf('*');
      if (starIndex == -1) {
        final candidate = Directory('${root.path}/$glob');
        if (await candidate.exists()) {
          resolved[candidate.path] = candidate;
          exactPaths.add(candidate.path);
        }
        continue;
      }

      final prefix = glob.substring(0, starIndex).replaceAll(
            RegExp(r'/+$'),
            '',
          );
      final parent = prefix.isEmpty ? root : Directory('${root.path}/$prefix');
      if (!await parent.exists()) continue;
      try {
        await for (final entity in parent.list(followLinks: false)) {
          if (entity is Directory) resolved[entity.path] = entity;
        }
      } on FileSystemException {
        // Unreadable directory — skip it and keep resolving the rest of
        // the glob list instead of aborting the whole scan.
      }
    }

    return (dirs: resolved.values.toList(), exactPaths: exactPaths);
  }

  /// The directories sitting alongside [dir] (its parent's other
  /// children) — used to check for member packages an exact/literal path
  /// entry's config never mentioned, since naming one specific package
  /// says nothing about whether its neighbors are also real packages.
  Future<Set<Directory>> _siblingDirs(Directory dir) async {
    final parent = dir.parent;
    final siblings = <Directory>{};
    if (!await parent.exists()) return siblings;
    try {
      await for (final entity in parent.list(followLinks: false)) {
        if (entity is Directory && entity.path != dir.path) {
          siblings.add(entity);
        }
      }
    } on FileSystemException {
      // Unreadable parent — no siblings to add.
    }
    return siblings;
  }

  /// This monorepo root's member packages — found by resolving its own
  /// workspace globs and then recursively descending into whatever they
  /// point at (see [_scanForProjects]). A glob commonly resolves one level
  /// higher than the actual packages (a grouping folder that isn't a
  /// project itself), and a resolved package can itself be another
  /// monorepo root nested inside this one — both keep being explored
  /// until real projects are found, so a whole tree of nested workspaces
  /// surfaces instead of just whatever the glob directly points at.
  Future<List<WorkspaceEntry>> _findSubPackages(
    Directory monorepoRoot,
    _MonorepoInfo info,
    Set<String> favoritePaths,
  ) async {
    final resolvedGlobs = await _resolveWorkspaceGlobs(
      monorepoRoot,
      info.packageGlobs,
    );

    final visited = <String>{monorepoRoot.path};
    final subPackages = <WorkspaceEntry>[];
    for (final memberDir in resolvedGlobs.dirs) {
      subPackages.addAll(
        await _scanForProjects(memberDir, favoritePaths, visited),
      );
    }

    // Every exact (non-wildcard) path found anywhere in this workspace —
    // seeded from the glob list's own literal entries, and grown as path
    // dependencies (below) turn up more. Used for sibling-scanning: an
    // exact path names one specific package but says nothing about
    // whether its neighbors are also real, undeclared ones.
    final exactPaths = Set<String>.of(resolvedGlobs.exactPaths);

    // A workspace's own packages:/workspace: config can drift out of date
    // (a package added to disk but never added to the list) — path
    // dependencies are a second, independent signal for member packages,
    // and one pub itself requires to stay accurate for `pub get` to work
    // at all. Seed from the root's own pubspec.yaml, then keep following
    // each newly found package's own path dependencies in turn, so a
    // package only reachable through another package (not the root
    // directly) still turns up.
    final pending = await _pathDependencyDirs(
      File('${monorepoRoot.path}/pubspec.yaml'),
    );
    exactPaths.addAll(pending);
    while (pending.isNotEmpty) {
      final dirPath = pending.first;
      pending.remove(dirPath);

      final found = await _scanForProjects(
        Directory(dirPath),
        favoritePaths,
        visited,
      );
      if (found.isEmpty) continue;
      subPackages.addAll(found);

      for (final entry in found) {
        if (entry is WorkspaceProjectEntry) {
          final deps = await _pathDependencyDirs(
            File('${entry.project.path}/pubspec.yaml'),
          );
          pending.addAll(deps);
          exactPaths.addAll(deps);
        }
      }
    }

    // Sibling scan: neither the workspace config nor the dependency graph
    // says anything about a package nobody references and whose folder
    // was never explicitly listed (e.g. a standalone example/showcase
    // app) — checking the neighbors of every exact path found above is
    // what actually surfaces one of those.
    for (final exactPath in exactPaths) {
      for (final sibling in await _siblingDirs(Directory(exactPath))) {
        subPackages.addAll(
          await _scanForProjects(sibling, favoritePaths, visited),
        );
      }
    }

    subPackages.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return subPackages;
  }

  /// Every directory a pubspec.yaml's own `dependencies`/`dev_dependencies`
  /// point at via a `path:` entry, resolved relative to that pubspec's own
  /// location. Returns an empty set for a missing or unparsable file
  /// rather than throwing — this is a supplementary signal, not something
  /// that should abort discovery if one package's pubspec is malformed.
  Future<Set<String>> _pathDependencyDirs(File pubspecFile) async {
    if (!await pubspecFile.exists()) return const {};

    try {
      final doc = loadYaml(await pubspecFile.readAsString());
      if (doc is! Map) return const {};

      final dirs = <String>{};
      for (final section in const ['dependencies', 'dev_dependencies']) {
        final deps = doc[section];
        if (deps is! Map) continue;
        for (final value in deps.values) {
          if (value is! Map) continue;
          final relativePath = value['path'];
          if (relativePath is! String) continue;
          // A directory-style Uri (trailing slash, common in these path
          // entries) round-trips through toFilePath() with that trailing
          // slash intact — stripped here so it can't reintroduce the
          // empty-project-name bug a trailing separator caused elsewhere
          // (see _resolveWorkspaceGlobs).
          final resolved = Uri.file('${pubspecFile.parent.path}/$relativePath')
              .normalizePath()
              .toFilePath()
              .replaceAll(RegExp(r'/+$'), '');
          if (resolved.isNotEmpty) dirs.add(resolved);
        }
      }
      return dirs;
    } on Object {
      // Malformed YAML — nothing more to try for this pubspec.
      return const {};
    }
  }

  /// Recursively finds every project under [dir]. If [dir] is itself a
  /// project, that's the (only) result for this branch — after also
  /// checking whether it's a monorepo root in its own right, so a nested
  /// workspace-within-a-workspace still surfaces its own member packages
  /// instead of being treated as an opaque leaf. If [dir] isn't a project
  /// (a plain intermediate container — the common case for a glob that
  /// resolves one level above the real packages, or a folder just used to
  /// group several of them), it becomes a [WorkspaceFolderEntry] wrapping
  /// whatever its children resolve to instead of being silently skipped —
  /// so the tree stays honest about where packages actually live, rather
  /// than flattening every non-project directory away. [visited] guards
  /// against re-walking a directory already covered elsewhere in the same
  /// scan.
  Future<List<WorkspaceEntry>> _scanForProjects(
    Directory dir,
    Set<String> favoritePaths,
    Set<String> visited,
  ) async {
    if (!visited.add(dir.path)) return const [];
    if (!await dir.exists()) return const [];

    final dirName = dir.path.split(Platform.pathSeparator).last;

    final detected = await _languageDetector.detectProject(dir);
    if (detected == null) {
      if (dirName.startsWith('.') || _skippedDirNames.contains(dirName)) {
        return const [];
      }

      final children = <WorkspaceEntry>[];
      try {
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is Directory) {
            children.addAll(
              await _scanForProjects(entity, favoritePaths, visited),
            );
          }
        }
      } on FileSystemException {
        // Unreadable directory — skip it, keeping whatever else was found.
      }
      // A container with nothing worth showing inside isn't worth a row of
      // its own either — same "no real content" reasoning as returning
      // null for a directory that isn't a project.
      if (children.isEmpty) return const [];

      children.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return [WorkspaceFolderEntry(dirName, dir.path, children)];
    }

    final nestedMonorepo = await _detectMonorepo(dir);
    final nestedSubPackages = nestedMonorepo == null
        ? const <WorkspaceEntry>[]
        : await _findSubPackages(dir, nestedMonorepo, favoritePaths);

    return [
      WorkspaceProjectEntry(
        ProjectModel(
          name: dirName,
          path: dir.path,
          iconPath: await _iconFinder.findIconPath(
            dir,
            detected.language,
            framework: detected.framework,
            isXcodeProject: detected.isXcodeProject,
          ),
          sourceDir: dir.parent.path,
          favourite: favoritePaths.contains(dir.path),
          language: detected.language,
          framework: detected.framework,
          isXcodeProject: detected.isXcodeProject,
          isAndroidProject: detected.isAndroidProject,
          monorepoTool: nestedMonorepo?.tool,
          subPackages: nestedSubPackages,
        ),
      ),
    ];
  }

  Future<List<ProjectModel>> getProjects() async {
    final projects = <ProjectModel>[];
    final seenPaths = <String>{};

    for (final dirPath in _directoryRepo.getProjectDirs()) {
      for (final project in await _findProjectsIn(Directory(dirPath))) {
        if (!seenPaths.add(project.path)) continue;
        projects.add(project);
        // A monorepo's member packages (and, for a nested workspace, their
        // own member packages in turn) are only ever reachable through
        // their parent here — registering their paths too keeps them from
        // also showing up as unrelated top-level duplicates if their
        // folder happens to be (separately) registered as a search dir.
        _markSubPackagesSeen(project, seenPaths);
      }
    }

    return projects;
  }

  void _markSubPackagesSeen(ProjectModel project, Set<String> seenPaths) {
    _markEntriesSeen(project.subPackages, seenPaths);
  }

  void _markEntriesSeen(List<WorkspaceEntry> entries, Set<String> seenPaths) {
    for (final entry in entries) {
      seenPaths.add(entry.path);
      switch (entry) {
        case WorkspaceProjectEntry(:final project):
          _markSubPackagesSeen(project, seenPaths);
        case WorkspaceFolderEntry(:final children):
          _markEntriesSeen(children, seenPaths);
      }
    }
  }

  /// Detects every project directly inside [dir], throttled the same way
  /// size calculation/cleanup are elsewhere in the app — detection +
  /// icon lookup is real filesystem work per candidate, run concurrently
  /// instead of one entity at a time so a directory with many projects
  /// isn't paid for sequentially. Deliberately does *not* build a
  /// monorepo's member-package tree here (see [loadSubPackages]) — that's
  /// the genuinely expensive part (recursive scan, sibling-scan,
  /// path-dependency traversal, a full icon lookup per member package),
  /// and doing it eagerly for every monorepo on every call would block
  /// this "quick, show-something-immediately" listing behind it, even for
  /// a screen (Storage) that never displays the tree itself.
  Future<List<ProjectModel>> _findProjectsIn(Directory dir) async {
    if (!await dir.exists()) return [];

    final favoritePaths = _favouritesRepo.getFavoriteProjectPaths().toSet();

    final entities = <Directory>[];
    try {
      await for (final entity in dir.list()) {
        if (entity is Directory) entities.add(entity);
      }
    } on FileSystemException catch (error, stackTrace) {
      // Unreadable search directory — nothing found here, but let every
      // other configured search directory still get scanned.
      logError('List directory ${dir.path}', error, stackTrace);
      return [];
    }

    final projects = <ProjectModel>[];
    await runWithConcurrency(
      [
        for (final entity in entities)
          () async {
            final detected = await _languageDetector.detectProject(entity);
            if (detected == null) return;

            final monorepoInfo = await _detectMonorepo(entity);

            projects.add(
              ProjectModel(
                name: entity.path.split(Platform.pathSeparator).last,
                path: entity.path,
                iconPath: await _iconFinder.findIconPath(
                  entity,
                  detected.language,
                  framework: detected.framework,
                  isXcodeProject: detected.isXcodeProject,
                ),
                sourceDir: dir.path,
                favourite: favoritePaths.contains(entity.path),
                language: detected.language,
                framework: detected.framework,
                isXcodeProject: detected.isXcodeProject,
                isAndroidProject: detected.isAndroidProject,
                monorepoTool: monorepoInfo?.tool,
                // Left unloaded here regardless of monorepoTool — see
                // loadSubPackages.
                subPackagesLoaded: monorepoInfo == null,
              ),
            );
          },
      ],
      concurrency: Platform.numberOfProcessors,
    );

    return projects;
  }

  /// Fetches [project]'s own monorepo member-package tree — the expensive
  /// part [_findProjectsIn] deliberately defers. Returns [project]
  /// unchanged if it isn't a monorepo root at all (nothing to load).
  /// Re-reads the workspace config (melos.yaml/nx.json/...) rather than
  /// caching it on the model, since that's cheap next to the scan itself
  /// and keeps [ProjectModel] from having to carry an internal type.
  Future<ProjectModel> loadSubPackages(
    ProjectModel project, {
    bool forceRefresh = false,
  }) async {
    if (project.monorepoTool == null) return project;

    if (!forceRefresh) {
      final cached = _readCachedSubPackages(project.path);
      if (cached != null) {
        return project.copyWith(subPackages: cached, subPackagesLoaded: true);
      }
    }

    final monorepoInfo = await _detectMonorepo(Directory(project.path));
    if (monorepoInfo == null) {
      // The workspace config disappeared since the last full scan (e.g.
      // melos.yaml was deleted) — nothing to load, but still mark done so
      // the badge stops showing a perpetual loading state.
      return project.copyWith(subPackagesLoaded: true);
    }

    final favoritePaths = _favouritesRepo.getFavoriteProjectPaths().toSet();
    final subPackages = await _findSubPackages(
      Directory(project.path),
      monorepoInfo,
      favoritePaths,
    );

    await _writeCachedSubPackages(project.path, subPackages);

    return project.copyWith(
      subPackages: subPackages,
      subPackagesLoaded: true,
    );
  }

  String _subPackagesCacheKey(String projectPath) =>
      'monorepoSubPackages:$projectPath';

  /// Reads a monorepo's last-scanned member-package tree back from Hive,
  /// so it can show up instantly instead of every app launch (or store
  /// reload) paying for a fresh recursive/sibling/path-dependency scan —
  /// the same "show the cached number immediately" idea project sizes
  /// already use. Returns null (rather than throwing) for anything
  /// missing or that fails to deserialize — e.g. an older cache written
  /// before a field was added — so a stale/corrupt entry just means a
  /// fresh scan runs instead of the whole load failing.
  List<WorkspaceEntry>? _readCachedSubPackages(String projectPath) {
    final raw = _box.get(_subPackagesCacheKey(projectPath));
    if (raw is! List) return null;

    try {
      return [
        for (final entry in raw)
          if (_codec.deserializeWorkspaceEntry(entry as Map) case final e?) e,
      ];
    } on Object {
      return null;
    }
  }

  Future<void> _writeCachedSubPackages(
    String projectPath,
    List<WorkspaceEntry> subPackages,
  ) {
    return _box.put(
      _subPackagesCacheKey(projectPath),
      [for (final entry in subPackages) _codec.serializeWorkspaceEntry(entry)],
    );
  }
}
