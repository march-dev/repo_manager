import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:yaml/yaml.dart';

import '../../repo_manager.dart';

class _DetectedProject {
  const _DetectedProject(
    this.language, {
    this.framework,
    required this.isXcodeProject,
  });

  final ProjectLanguage language;
  final ProjectFramework? framework;
  final bool isXcodeProject;
}

/// A detected monorepo/workspace root: which tool manages it, and the
/// (unresolved) glob patterns its config declares for member packages —
/// e.g. Melos's `packages:` list, or npm/yarn/pnpm's `workspaces` field.
class _MonorepoInfo {
  const _MonorepoInfo(this.tool, this.packageGlobs);

  final MonorepoTool tool;
  final List<String> packageGlobs;
}

/// A directory to search for an icon image in, optionally restricted to
/// files named exactly [onlyBaseName] (before the extension) — used for
/// Android's mipmap folders once AndroidManifest.xml resolves the actual
/// icon resource name, so e.g. ic_launcher_round or a notification icon
/// sitting in the same folder isn't picked by mistake.
class _IconSearchLocation {
  const _IconSearchLocation(this.dir, {this.onlyBaseName});

  final Directory dir;
  final String? onlyBaseName;
}

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

  Future<bool> _isProjectDir(Directory dir) async {
    return (await _detectProject(dir)) != null;
  }

  /// The first top-level subfolder of [dir] that contains an Info.plist —
  /// the Runner/-style folder an Xcode-managed project (native or a
  /// Flutter host project's ios//macos/) keeps its actual source, asset
  /// catalog, and Info.plist in, rather than at the project root itself.
  Future<Directory?> _findInfoPlistFolder(Directory dir) async {
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! Directory) continue;
      if (await File('${entity.path}/Info.plist').exists()) return entity;
    }
    return null;
  }

  Future<Set<String>> _dirEntryNames(Directory dir) async {
    final names = <String>{};
    await for (final entity in dir.list(followLinks: false)) {
      names.add(entity.path.split(Platform.pathSeparator).last);
    }
    return names;
  }

  /// Identifies a directory as a project of a specific language by looking
  /// for that ecosystem's own marker file(s) — the same idea as `pubspec.yaml`
  /// for Dart/Flutter, generalized to the other languages ProjectLanguage
  /// covers. Returns null if the directory doesn't look like any recognized
  /// kind of project.
  Future<_DetectedProject?> _detectProject(Directory projectDir) async {
    // A Flutter project's pubspec.yaml always declares a dependency on the
    // Flutter SDK itself (`dependencies: flutter: sdk: flutter`); a plain
    // Dart package's doesn't. That's a more reliable signal than the
    // presence of a `flutter:` top-level section, which is optional even
    // for Flutter apps. Either way the language is Dart — Flutter is a
    // framework built on top of it, not a language of its own.
    final pubspec = File('${projectDir.path}/pubspec.yaml');
    if (await pubspec.exists()) {
      final content = await pubspec.readAsString();
      final framework =
          content.contains('sdk: flutter') ? ProjectFramework.flutter : null;
      return _DetectedProject(
        ProjectLanguage.dart,
        framework: framework,
        isXcodeProject: false,
      );
    }

    final topLevelEntities = await projectDir.list(followLinks: false).toList();
    final topLevelNames = {
      for (final entity in topLevelEntities)
        entity.path.split(Platform.pathSeparator).last,
    };
    bool hasExtension(String extension) =>
        topLevelNames.any((name) => name.endsWith(extension));

    // Unity's own marker — checked ahead of the generic C# (.sln/.csproj)
    // detection below, since Unity generates those itself once the
    // project's been opened in an IDE; they'd otherwise misclassify it as
    // a plain C# project rather than a game project that happens to
    // script in C#. ProjectVersion.txt is Unity-specific (just an editor
    // version string) and always sits at this exact nested path, unlike
    // Assets/ or ProjectSettings/ alone, which aren't distinctive enough
    // on their own.
    if (await File(
      '${projectDir.path}/ProjectSettings/ProjectVersion.txt',
    ).exists()) {
      return const _DetectedProject(
        ProjectLanguage.csharp,
        framework: ProjectFramework.unity,
        isXcodeProject: false,
      );
    }

    // Unreal's own marker — same reasoning as Unity above, checked ahead
    // of the generic C++ (CMakeLists.txt/Makefile) detection, since
    // Unreal's own generated build files could otherwise be mistaken for
    // a plain CMake-based C++ project.
    if (hasExtension('.uproject')) {
      return const _DetectedProject(
        ProjectLanguage.cpp,
        framework: ProjectFramework.unrealEngine,
        isXcodeProject: false,
      );
    }

    // An Xcode-managed project: Swift if it has any .swift source (or is a
    // Swift package outright), otherwise C++ if it looks like a C++
    // codebase wired up with an Xcode project, otherwise Objective-C.
    final isXcodeProject = topLevelNames.contains('Package.swift') ||
        hasExtension('.xcodeproj') ||
        hasExtension('.xcworkspace');
    if (isXcodeProject) {
      // Flutter's iOS/macOS host projects keep their actual source (and
      // Info.plist) inside a Runner/-style subfolder rather than scattered
      // at the project root, so a plain top-level extension scan always
      // misses it and falls through to the Objective-C default. A
      // top-level Flutter/ folder marks this layout — when present, look
      // inside whichever subfolder holds Info.plist instead.
      var sourceNames = topLevelNames;
      final hasFlutterFolder = topLevelEntities.any((entity) =>
          entity is Directory &&
          entity.path.split(Platform.pathSeparator).last == 'Flutter');
      if (hasFlutterFolder) {
        final infoPlistFolder = await _findInfoPlistFolder(projectDir);
        if (infoPlistFolder != null) {
          sourceNames = await _dirEntryNames(infoPlistFolder);
        }
      }
      bool sourceHasExtension(String extension) =>
          sourceNames.any((name) => name.endsWith(extension));

      if (topLevelNames.contains('Package.swift') ||
          sourceHasExtension('.swift')) {
        return const _DetectedProject(
          ProjectLanguage.swift,
          isXcodeProject: true,
        );
      }
      if (sourceHasExtension('.cpp') ||
          sourceHasExtension('.hpp') ||
          sourceHasExtension('.cc') ||
          sourceHasExtension('.cxx')) {
        return const _DetectedProject(
          ProjectLanguage.cpp,
          isXcodeProject: true,
        );
      }
      return const _DetectedProject(
        ProjectLanguage.objectiveC,
        isXcodeProject: true,
      );
    }

    // Gradle's Kotlin DSL (build.gradle.kts) or any top-level .kt/.kts file
    // is a strong enough signal to call the whole project Kotlin over Java.
    if (topLevelNames.contains('build.gradle.kts') ||
        hasExtension('.kt') ||
        hasExtension('.kts')) {
      return const _DetectedProject(
        ProjectLanguage.kotlin,
        isXcodeProject: false,
      );
    }
    if (topLevelNames.contains('build.gradle') ||
        topLevelNames.contains('settings.gradle') ||
        topLevelNames.contains('pom.xml')) {
      return const _DetectedProject(
        ProjectLanguage.java,
        isXcodeProject: false,
      );
    }

    if (hasExtension('.sln') || hasExtension('.csproj')) {
      // Xamarin.Android/MAUI's Android head keeps its manifest at
      // Properties/AndroidManifest.xml (Xamarin) or under Platforms/
      // (MAUI's single-project layout); Xamarin.iOS/MAUI's iOS head keeps
      // an Info.plist at the project root the way a plain Xcode project
      // would, but as a C# project (no .xcodeproj/.xcworkspace) it never
      // reaches the isXcodeProject branch above.
      final hasXamarinMarker = topLevelNames.contains('Platforms') ||
          await File('${projectDir.path}/Properties/AndroidManifest.xml')
              .exists() ||
          await File('${projectDir.path}/Info.plist').exists();
      return _DetectedProject(
        ProjectLanguage.csharp,
        framework: hasXamarinMarker ? ProjectFramework.xamarin : null,
        isXcodeProject: false,
      );
    }

    if (topLevelNames.contains('package.json')) {
      final content =
          await File('${projectDir.path}/package.json').readAsString();

      // Checked in priority order — a meta-framework's own package.json
      // commonly also lists the base library/framework it's built on (a
      // React Native, Next.js, or Astro-with-the-React-integration project
      // all depend on "react" too; Nuxt depends on "vue"; SvelteKit
      // depends on "svelte"; NestJS depends on "express"/"fastify" via its
      // platform adapters), so the more specific signal has to be checked
      // before the more generic one it would otherwise be mistaken for.
      final ProjectFramework? framework;
      if (content.contains('"react-native"')) {
        framework = ProjectFramework.reactNative;
      } else if (content.contains('"astro"')) {
        framework = ProjectFramework.astro;
      } else if (content.contains('"next"')) {
        framework = ProjectFramework.nextJs;
      } else if (content.contains('"nuxt"')) {
        framework = ProjectFramework.nuxt;
      } else if (content.contains('"@nestjs/core"')) {
        framework = ProjectFramework.nestJs;
      } else if (content.contains('"@angular/core"')) {
        framework = ProjectFramework.angular;
      } else if (content.contains('"vue"')) {
        framework = ProjectFramework.vueJs;
      } else if (content.contains('"svelte"')) {
        framework = ProjectFramework.svelte;
      } else if (content.contains('"react"')) {
        framework = ProjectFramework.reactJs;
      } else if (content.contains('"express"')) {
        framework = ProjectFramework.express;
      } else if (content.contains('"fastify"')) {
        framework = ProjectFramework.fastify;
      } else {
        framework = ProjectFramework.nodeJs;
      }

      final language = topLevelNames.contains('tsconfig.json') ||
              content.contains('"typescript"')
          ? ProjectLanguage.typescript
          : ProjectLanguage.javascript;

      return _DetectedProject(
        language,
        framework: framework,
        isXcodeProject: false,
      );
    }

    if (topLevelNames.contains('go.mod')) {
      return const _DetectedProject(ProjectLanguage.go, isXcodeProject: false);
    }

    if (topLevelNames.contains('Cargo.toml')) {
      return const _DetectedProject(
        ProjectLanguage.rust,
        isXcodeProject: false,
      );
    }

    if (topLevelNames.contains('composer.json')) {
      return const _DetectedProject(ProjectLanguage.php, isXcodeProject: false);
    }

    // No single universal marker the way other ecosystems have one — these
    // are the common ones across the several packaging/dependency tools
    // Python projects use (pip/Poetry/Pipenv/plain setuptools).
    if (topLevelNames.contains('pyproject.toml') ||
        topLevelNames.contains('setup.py') ||
        topLevelNames.contains('Pipfile') ||
        topLevelNames.contains('requirements.txt')) {
      return const _DetectedProject(
        ProjectLanguage.python,
        isXcodeProject: false,
      );
    }

    if (topLevelNames.contains('CMakeLists.txt') ||
        topLevelNames.contains('Makefile')) {
      return const _DetectedProject(ProjectLanguage.cpp, isXcodeProject: false);
    }

    return null;
  }

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

    final detected = await _detectProject(dir);
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
          iconPath: await _findIconPath(
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
          monorepoTool: nestedMonorepo?.tool,
          subPackages: nestedSubPackages,
        ),
      ),
    ];
  }

  Future<List<ProjectModel>> getProjects() async {
    final projects = <ProjectModel>[];
    final seenPaths = <String>{};

    for (final dirPath in getProjectDirs()) {
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

    final favoritePaths = _getFavoriteProjectPaths().toSet();

    final entities = <Directory>[];
    await for (final entity in dir.list()) {
      if (entity is Directory) entities.add(entity);
    }

    final projects = <ProjectModel>[];
    await runWithConcurrency(
      [
        for (final entity in entities)
          () async {
            final detected = await _detectProject(entity);
            if (detected == null) return;

            final monorepoInfo = await _detectMonorepo(entity);

            projects.add(
              ProjectModel(
                name: entity.path.split(Platform.pathSeparator).last,
                path: entity.path,
                iconPath: await _findIconPath(
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

    final favoritePaths = _getFavoriteProjectPaths().toSet();
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
          if (_deserializeWorkspaceEntry(entry as Map) case final e?) e,
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
      [for (final entry in subPackages) _serializeWorkspaceEntry(entry)],
    );
  }

  Map<String, dynamic> _serializeWorkspaceEntry(WorkspaceEntry entry) {
    return switch (entry) {
      WorkspaceProjectEntry(:final project) => {
          'type': 'project',
          'project': _serializeProjectModel(project),
        },
      WorkspaceFolderEntry(:final name, :final path, :final children) => {
          'type': 'folder',
          'name': name,
          'path': path,
          'children': [
            for (final child in children) _serializeWorkspaceEntry(child),
          ],
        },
    };
  }

  WorkspaceEntry? _deserializeWorkspaceEntry(Map data) {
    switch (data['type']) {
      case 'project':
        final project = _deserializeProjectModel(data['project'] as Map?);
        return project == null ? null : WorkspaceProjectEntry(project);
      case 'folder':
        final name = data['name'];
        final path = data['path'];
        final rawChildren = data['children'];
        if (name is! String || path is! String || rawChildren is! List) {
          return null;
        }
        return WorkspaceFolderEntry(name, path, [
          for (final child in rawChildren)
            if (_deserializeWorkspaceEntry(child as Map) case final c?) c,
        ]);
      default:
        return null;
    }
  }

  Map<String, dynamic> _serializeProjectModel(ProjectModel project) {
    return {
      'name': project.name,
      'path': project.path,
      'iconPath': project.iconPath,
      'sourceDir': project.sourceDir,
      'favourite': project.favourite,
      'language': project.language.name,
      'framework': project.framework?.name,
      'isXcodeProject': project.isXcodeProject,
      'monorepoTool': project.monorepoTool?.name,
      'subPackages': [
        for (final entry in project.subPackages)
          _serializeWorkspaceEntry(entry),
      ],
      'subPackagesLoaded': project.subPackagesLoaded,
    };
  }

  ProjectModel? _deserializeProjectModel(Map? data) {
    if (data == null) return null;

    final language =
        _enumByName(ProjectLanguage.values, data['language'] as String?);
    final name = data['name'];
    final path = data['path'];
    final iconPath = data['iconPath'];
    final sourceDir = data['sourceDir'];
    final favourite = data['favourite'];
    final isXcodeProject = data['isXcodeProject'];
    final subPackagesLoaded = data['subPackagesLoaded'];
    final rawSubPackages = data['subPackages'];
    if (language == null ||
        name is! String ||
        path is! String ||
        iconPath is! String ||
        sourceDir is! String ||
        favourite is! bool ||
        isXcodeProject is! bool ||
        subPackagesLoaded is! bool ||
        rawSubPackages is! List) {
      return null;
    }

    return ProjectModel(
      name: name,
      path: path,
      iconPath: iconPath,
      sourceDir: sourceDir,
      favourite: favourite,
      language: language,
      framework:
          _enumByName(ProjectFramework.values, data['framework'] as String?),
      isXcodeProject: isXcodeProject,
      monorepoTool:
          _enumByName(MonorepoTool.values, data['monorepoTool'] as String?),
      subPackages: [
        for (final entry in rawSubPackages)
          if (_deserializeWorkspaceEntry(entry as Map) case final e?) e,
      ],
      subPackagesLoaded: subPackagesLoaded,
    );
  }

  T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  static const _webLanguages = {
    ProjectLanguage.javascript,
    ProjectLanguage.typescript,
  };

  // A real launcher/app icon is worth using at, so a plain small favicon
  // doesn't win out over a much sharper one sitting right next to it.
  static const _minIconDimension = 120;

  static const _iconExtensions = ['.png', '.webp', '.jpg', '.jpeg'];

  /// Finds the best available icon for a project of [language], searching
  /// each ecosystem's conventional icon *locations* for any image file at
  /// least [_minIconDimension]px on its shorter side — rather than matching
  /// one specific filename — and returning the largest qualifying one
  /// found. Falls back to a favicon of any size for a web project with
  /// nothing that large, since a small icon still beats none. Returns ''
  /// (ProjectIcon's own signal for "no icon found") if nothing qualifies.
  Future<String> _findIconPath(
    Directory projectDir,
    ProjectLanguage language, {
    ProjectFramework? framework,
    required bool isXcodeProject,
  }) async {
    final searchLocations = <_IconSearchLocation>[];

    if (isXcodeProject) {
      final sourceDir = await _findInfoPlistFolder(projectDir) ?? projectDir;
      searchLocations.add(
        _IconSearchLocation(
          Directory('${sourceDir.path}/Assets.xcassets/AppIcon.appiconset'),
        ),
      );
    }

    if (framework == ProjectFramework.flutter) {
      searchLocations.addAll([
        _IconSearchLocation(Directory(
          '${projectDir.path}/ios/Runner/Assets.xcassets/AppIcon.appiconset',
        )),
        _IconSearchLocation(Directory(
          '${projectDir.path}/macos/Runner/Assets.xcassets/AppIcon.appiconset',
        )),
        _IconSearchLocation(Directory('${projectDir.path}/web/icons')),
        ...await _androidMipmapSearchLocations(
          resDir: Directory('${projectDir.path}/android/app/src/main/res'),
          manifestDir: Directory('${projectDir.path}/android/app/src/main'),
        ),
      ]);
    }

    if (language == ProjectLanguage.java ||
        language == ProjectLanguage.kotlin) {
      searchLocations.addAll(
        await _androidMipmapSearchLocations(
          resDir: Directory('${projectDir.path}/app/src/main/res'),
          manifestDir: Directory('${projectDir.path}/app/src/main'),
        ),
      );
    }

    if (language == ProjectLanguage.csharp) {
      searchLocations.addAll(await _csharpIconSearchLocations(projectDir));
    }

    if (_webLanguages.contains(language)) {
      searchLocations.addAll([
        _IconSearchLocation(Directory('${projectDir.path}/public')),
        _IconSearchLocation(Directory('${projectDir.path}/public/icons')),
        _IconSearchLocation(Directory('${projectDir.path}/static')),
        _IconSearchLocation(Directory('${projectDir.path}/static/icons')),
      ]);
    }

    String? best;
    var bestDimension = 0;
    for (final location in searchLocations) {
      final dir = location.dir;
      if (!await dir.exists()) continue;
      try {
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is! File) continue;
          final fileName = entity.path.split(Platform.pathSeparator).last;
          final dotIndex = fileName.lastIndexOf('.');
          if (dotIndex == -1) continue;
          final baseName = fileName.substring(0, dotIndex);
          final extension = fileName.substring(dotIndex).toLowerCase();
          if (!_iconExtensions.contains(extension)) continue;
          if (location.onlyBaseName != null &&
              baseName != location.onlyBaseName) {
            continue;
          }

          final dimensions = await _readImageDimensions(entity);
          if (dimensions == null) continue;
          final (width, height) = dimensions;
          final shortSide = width < height ? width : height;
          if (shortSide < _minIconDimension || shortSide <= bestDimension) {
            continue;
          }
          best = entity.path;
          bestDimension = shortSide;
        }
      } on FileSystemException {
        // Unreadable directory (permissions, broken symlink, ...) — skip
        // it and keep searching the rest instead of aborting discovery.
      }
    }

    if (best != null) return best;

    // Unlike every other location above, a favicon is worth pointing at
    // regardless of size — most web projects have nothing bigger than a
    // 16x16/32x32 one, and that still reads better than no icon at all.
    return _webLanguages.contains(language) ? _findFavicon(projectDir) : '';
  }

  /// The mipmap-density folders under [resDir], paired with the app icon's
  /// resource name from [manifestDir]'s AndroidManifest.xml (if declared) —
  /// so the search only considers files that are actually *that* icon
  /// (whatever it's called, e.g. "launcher_icon") rather than any image
  /// sitting in those folders (round variants, notification icons, ...).
  /// Falls back to no name filter (any qualifying image) if the manifest
  /// can't be read or doesn't declare a `@mipmap/...` icon.
  Future<List<_IconSearchLocation>> _androidMipmapSearchLocations({
    required Directory resDir,
    required Directory manifestDir,
  }) async {
    final iconName = await _androidManifestIconName(manifestDir);
    return [
      for (final dir in await _mipmapDirs(resDir))
        _IconSearchLocation(dir, onlyBaseName: iconName),
    ];
  }

  /// The resource name in AndroidManifest.xml's
  /// `<application android:icon="@mipmap/NAME">`, if declared — the actual
  /// name is project-specific (e.g. "launcher_icon"), not always
  /// "ic_launcher", so this reads the real declaration instead of assuming.
  Future<String?> _androidManifestIconName(Directory manifestDir) async {
    final manifestFile = File('${manifestDir.path}/AndroidManifest.xml');
    if (!await manifestFile.exists()) return null;

    String content;
    try {
      content = await manifestFile.readAsString();
    } on FileSystemException {
      return null;
    }

    final applicationTag =
        RegExp('<application[^>]*>').firstMatch(content)?.group(0);
    if (applicationTag == null) return null;

    return RegExp(r'android:icon="@mipmap/([\w.]+)"')
        .firstMatch(applicationTag)
        ?.group(1);
  }

  /// Covers .NET desktop (WPF/WinForms), Xamarin.iOS/Xamarin.Android, and
  /// .NET MAUI's single-project layout — each keeps its icon(s) at its own
  /// conventional location(s), checked here the same "search the place,
  /// not a filename" way as everything else. Doesn't cover a legacy
  /// Xamarin.Forms *solution* whose separate platform-head projects sit in
  /// arbitrarily-named sibling folders (e.g. "MyApp.Droid") — there's no
  /// fixed name to look for there.
  Future<List<_IconSearchLocation>> _csharpIconSearchLocations(
    Directory projectDir,
  ) async {
    final locations = <_IconSearchLocation>[
      // .NET desktop apps keep their .ico wherever the .csproj's
      // <ApplicationIcon> points, but these are the conventional spots.
      _IconSearchLocation(Directory('${projectDir.path}/Properties')),
      _IconSearchLocation(Directory('${projectDir.path}/Resources')),
      _IconSearchLocation(Directory('${projectDir.path}/Assets')),
      _IconSearchLocation(projectDir),
      // .NET MAUI's single-project icon folder — usually a vector-only
      // appicon.svg (which ProjectIcon can't render), but some projects
      // also commit a raster fallback here.
      _IconSearchLocation(Directory('${projectDir.path}/Resources/AppIcon')),
    ];

    // Xamarin.Android (native) and MAUI's Android head both keep the same
    // manifest+mipmap convention plain Android does, just under
    // Xamarin/MAUI's own folder names rather than Gradle's.
    for (final manifestRelativePath in const [
      'Properties/AndroidManifest.xml',
      'Platforms/Android/AndroidManifest.xml',
    ]) {
      final manifestFile = File('${projectDir.path}/$manifestRelativePath');
      if (!await manifestFile.exists()) continue;
      locations.addAll(
        await _androidMipmapSearchLocations(
          resDir: Directory('${projectDir.path}/Resources'),
          manifestDir: manifestFile.parent,
        ),
      );
    }

    // Xamarin.iOS (native) and MAUI's iOS head both keep the same
    // Assets.xcassets convention plain iOS does.
    for (final infoPlistDir in [
      projectDir,
      Directory('${projectDir.path}/Platforms/iOS'),
    ]) {
      if (!await File('${infoPlistDir.path}/Info.plist').exists()) continue;
      locations.add(
        _IconSearchLocation(
          Directory('${infoPlistDir.path}/Assets.xcassets/AppIcon.appiconset'),
        ),
      );
    }

    return locations;
  }

  Future<String> _findFavicon(Directory projectDir) async {
    const relativePaths = [
      'public/favicon.png',
      'static/favicon.png',
      'src/favicon.png',
      'favicon.png',
      'public/favicon.ico',
      'static/favicon.ico',
      'favicon.ico',
    ];
    for (final relativePath in relativePaths) {
      final file = File('${projectDir.path}/$relativePath');
      try {
        if (await file.exists()) return file.path;
      } on FileSystemException {
        // Try the next candidate instead of letting one bad path abort
        // discovery for the whole project.
      }
    }
    return '';
  }

  /// Every top-level subfolder of [resDir] whose name starts with
  /// "mipmap" — Android's per-density launcher-icon folders (mipmap-mdpi,
  /// -hdpi, -xhdpi, ...), found by pattern rather than enumerating the
  /// fixed set of density names Google could add to at any point.
  Future<List<Directory>> _mipmapDirs(Directory resDir) async {
    if (!await resDir.exists()) return [];
    final dirs = <Directory>[];
    try {
      await for (final entity in resDir.list(followLinks: false)) {
        if (entity is Directory &&
            entity.path
                .split(Platform.pathSeparator)
                .last
                .startsWith('mipmap')) {
          dirs.add(entity);
        }
      }
    } on FileSystemException {
      // Unreadable res/ directory — treat as "no mipmap folders found".
    }
    return dirs;
  }

  /// Reads an image file's pixel width/height straight from its header,
  /// without decoding the whole image — this runs against every image in
  /// a handful of candidate folders per project, so it has to stay cheap.
  /// Supports PNG and WEBP (the formats these icon locations actually
  /// use); anything else returns null (excluded, since its size can't be
  /// verified).
  Future<(int, int)?> _readImageDimensions(File file) async {
    RandomAccessFile? handle;
    try {
      handle = await file.open();
      final header = await handle.read(32);
      return _pngDimensions(header) ?? _webpDimensions(header);
    } on FileSystemException {
      return null;
    } finally {
      await handle?.close();
    }
  }

  (int, int)? _pngDimensions(List<int> bytes) {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 24) return null;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return null;
    }
    int u32(int offset) =>
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    return (u32(16), u32(20));
  }

  (int, int)? _webpDimensions(List<int> bytes) {
    if (bytes.length < 30) return null;
    if (String.fromCharCodes(bytes.getRange(0, 4)) != 'RIFF') return null;
    if (String.fromCharCodes(bytes.getRange(8, 12)) != 'WEBP') return null;

    int u16le(int offset) => bytes[offset] | (bytes[offset + 1] << 8);
    int u24le(int offset) =>
        bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);

    switch (String.fromCharCodes(bytes.getRange(12, 16))) {
      case 'VP8 ':
        // Lossy: 3-byte frame tag, then a 3-byte start code, then
        // width/height as 14 bits each (top 2 bits are a scale factor).
        return (u16le(26) & 0x3FFF, u16le(28) & 0x3FFF);
      case 'VP8L':
        // Lossless: a 1-byte signature, then 14 bits width-1 and 14 bits
        // height-1 packed little-endian across the next 4 bytes.
        final bits = bytes[21] |
            (bytes[22] << 8) |
            (bytes[23] << 16) |
            (bytes[24] << 24);
        return ((bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1);
      case 'VP8X':
        // Extended format: 1 flags byte, 3 reserved, then 24-bit
        // width-1/height-1, little-endian.
        return (u24le(24) + 1, u24le(27) + 1);
      default:
        return null;
    }
  }

  static const _favoriteProjectPathsKey = 'favoriteProjectPathsKey';

  List<String> _getFavoriteProjectPaths() =>
      (_box.get(_favoriteProjectPathsKey) as List?)?.cast<String>() ?? [];

  Future<void> toggleFavoriteProject(String projectPath) async {
    final favorites = _getFavoriteProjectPaths();
    if (!favorites.remove(projectPath)) favorites.add(projectPath);
    await _box.put(_favoriteProjectPathsKey, favorites);
  }

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
  // so fall back to Explorer's "Uncollected" bucket.
  Future<void> deleteCollection(String name) async {
    final collections = _getCollections();
    collections.remove(name);
    await _putCollections(collections);
  }

  String _preferredIdeKey(LanguageGroup group) => 'preferredIde:${group.name}';

  Ide getPreferredIde(LanguageGroup group) {
    final raw = _box.get(_preferredIdeKey(group)) as String?;
    for (final ide in group.candidateIdes) {
      if (ide.name == raw) return ide;
    }
    return group.defaultIde;
  }

  Future<void> setPreferredIde(LanguageGroup group, Ide ide) async {
    await _box.put(_preferredIdeKey(group), ide.name);
  }

  static const _explorerPinFavouritesKey = 'explorerPinFavouritesKey';

  bool getExplorerPinFavourites() =>
      (_box.get(_explorerPinFavouritesKey) as bool?) ?? true;

  Future<void> setExplorerPinFavourites(bool value) async {
    await _box.put(_explorerPinFavouritesKey, value);
  }

  static const _explorerGroupingKey = 'explorerGroupingKey';

  ExplorerGrouping getExplorerGrouping() {
    final raw = _box.get(_explorerGroupingKey) as String?;
    return ExplorerGrouping.values.firstWhere(
      (grouping) => grouping.name == raw,
      orElse: () => ExplorerGrouping.none,
    );
  }

  Future<void> setExplorerGrouping(ExplorerGrouping grouping) async {
    await _box.put(_explorerGroupingKey, grouping.name);
  }

  static const _storageSortByKey = 'storageSortByKey';

  ProjectSortBy getStorageSortBy() {
    final raw = _box.get(_storageSortByKey) as String?;
    return ProjectSortBy.values.firstWhere(
      (sortBy) => sortBy.name == raw,
      orElse: () => ProjectSortBy.name,
    );
  }

  Future<void> setStorageSortBy(ProjectSortBy sortBy) async {
    await _box.put(_storageSortByKey, sortBy.name);
  }

  static const _storageSortAscendingKey = 'storageSortAscendingKey';

  bool getStorageSortAscending() =>
      (_box.get(_storageSortAscendingKey) as bool?) ?? true;

  Future<void> setStorageSortAscending(bool value) async {
    await _box.put(_storageSortAscendingKey, value);
  }

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

  /// Which IDE a project would actually open in. A C++ project that's
  /// already an Xcode project (has its own .xcodeproj/.xcworkspace) always
  /// resolves to Xcode, regardless of the C++ & C# group's configured
  /// preference — no other editor can build/run it the way Xcode can.
  /// Otherwise falls back to VS Code for languages with no dedicated
  /// preferred-IDE setting (see LanguageGroup) — it's the one IDE that shows
  /// up as a candidate for every group currently defined.
  Ide resolveIde(ProjectModel project) {
    if (project.language == ProjectLanguage.cpp && project.isXcodeProject) {
      return Ide.xcode;
    }
    final group = LanguageGroup.forLanguage(project.language);
    return group != null ? getPreferredIde(group) : Ide.vscode;
  }

  static const _recentlyOpenedProjectPathsKey = 'recentlyOpenedProjectPathsKey';
  static const _recentlyOpenedLimit = 8;

  /// Bumped every time [recordProjectOpened] runs. DashboardScreen's
  /// Recently Opened section listens to this directly (ValueListenableBuilder)
  /// rather than through a Provider-backed store, since it needs to work
  /// from contexts a Provider can't reach — a project-details dialog route
  /// or a context-menu overlay, both pushed onto the app's Navigator/Overlay
  /// as siblings of wherever ExplorerStore's own Provider is scoped, not
  /// descendants of it.
  static final recentlyOpenedVersion = ValueNotifier<int>(0);

  /// Project paths, most-recently-opened first — see [recordProjectOpened].
  /// Dashboard cross-references these against an already-loaded project
  /// list rather than this repo re-scanning the filesystem itself, so a
  /// path here that no longer resolves to a known project (deleted, moved,
  /// or its search directory removed in Settings) is just left for the
  /// caller to skip rather than validated here.
  List<String> getRecentlyOpenedProjectPaths() =>
      (_box.get(_recentlyOpenedProjectPathsKey) as List?)?.cast<String>() ?? [];

  /// Records `projectPath` as just opened, moving it to the front if it
  /// was already recorded. Called from every place that actually launches
  /// a project in an editor — openInEditor below, and (since they reach an
  /// IDE without going through it) the context menu's "Open With"/"Open
  /// <platform target>" entries.
  Future<void> recordProjectOpened(String projectPath) async {
    final recent = getRecentlyOpenedProjectPaths()..remove(projectPath);
    recent.insert(0, projectPath);
    await _box.put(
      _recentlyOpenedProjectPathsKey,
      recent.take(_recentlyOpenedLimit).toList(),
    );
    recentlyOpenedVersion.value++;
  }

  Future<void> openInEditor(ProjectModel project) {
    unawaited(recordProjectOpened(project.path));
    return openPathInIde(project.path, resolveIde(project));
  }

  Future<void> openPathInIde(String path, Ide ide) async {
    try {
      switch (ide) {
        case Ide.vscode:
          await Process.run('code', [path]);
        case Ide.androidStudio:
          await Process.run('open', ['-a', 'Android Studio', path]);
        case Ide.xcode:
          await Process.run('open', ['-a', 'Xcode', path]);
        case Ide.visualStudio:
          await Process.run('open', ['-a', 'Visual Studio', path]);
      }
    } on ProcessException {
      // Preferred IDE's launcher isn't available on PATH; nothing we can do.
    }
  }

  // Flutter and React Native both keep their native platform projects in
  // the same ios/android(/macos/windows/linux) subfolders — see
  // PlatformTarget's own TODOs for Capacitor/Cordova/Ionic and
  // NativeScript, which could extend this set once they're detected.
  static const _platformTargetFrameworks = {
    ProjectFramework.flutter,
    ProjectFramework.reactNative,
  };

  /// Which of [PlatformTarget.all]'s native platform subfolders (ios/,
  /// android/, ...) this project actually has. Empty for a project whose
  /// framework doesn't use this convention, or one with none of them
  /// checked out (e.g. a `flutter create --platforms` that omitted some).
  Future<List<PlatformTarget>> availablePlatformTargets(
    ProjectModel project,
  ) async {
    if (!_platformTargetFrameworks.contains(project.framework)) return [];

    final available = <PlatformTarget>[];
    for (final target in PlatformTarget.all) {
      if (await Directory('${project.path}/${target.relativeDir}').exists()) {
        available.add(target);
      }
    }
    return available;
  }

  /// Opens a project's native platform subfolder in its target's IDE. For
  /// Xcode/Visual Studio targets, points it at the actual project file a
  /// level down (e.g. Runner.xcworkspace) rather than the bare subfolder,
  /// since that's what those IDEs expect to be opened with.
  Future<void> openPlatformTarget(
    ProjectModel project,
    PlatformTarget target,
  ) async {
    final dir = Directory('${project.path}/${target.relativeDir}');
    var path = dir.path;

    for (final extension in target.preferredExtensions) {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity.path.endsWith(extension)) {
          path = entity.path;
          break;
        }
      }
      if (path != dir.path) break;
    }

    await openPathInIde(path, target.ide);
  }
}
