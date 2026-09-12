import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import '../../repo_manager.dart';

class _DetectedProject {
  const _DetectedProject(this.language, {required this.isXcodeProject});

  final ProjectLanguage language;
  final bool isXcodeProject;
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
    // for Flutter apps.
    final pubspec = File('${projectDir.path}/pubspec.yaml');
    if (await pubspec.exists()) {
      final content = await pubspec.readAsString();
      final language = content.contains('sdk: flutter')
          ? ProjectLanguage.flutter
          : ProjectLanguage.dart;
      return _DetectedProject(language, isXcodeProject: false);
    }

    final topLevelEntities = await projectDir.list(followLinks: false).toList();
    final topLevelNames = {
      for (final entity in topLevelEntities)
        entity.path.split(Platform.pathSeparator).last,
    };
    bool hasExtension(String extension) =>
        topLevelNames.any((name) => name.endsWith(extension));

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
        for (final entity in topLevelEntities) {
          if (entity is! Directory) continue;
          if (await File('${entity.path}/Info.plist').exists()) {
            sourceNames = <String>{
              await for (final child in entity.list(followLinks: false))
                child.path.split(Platform.pathSeparator).last,
            };
            break;
          }
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
      return const _DetectedProject(
        ProjectLanguage.csharp,
        isXcodeProject: false,
      );
    }

    if (topLevelNames.contains('package.json')) {
      final content =
          await File('${projectDir.path}/package.json').readAsString();
      // TODO: React Native (and Expo's "bare" workflow) projects also match
      // `"react"` here but, like Flutter, embed native ios/ and android/
      // subprojects that should be openable in Xcode/Android Studio — see
      // FlutterPlatformTarget. Disambiguate via `"react-native"` in
      // package.json and add a dedicated ProjectLanguage/handling for it.
      if (content.contains('"react"')) {
        return const _DetectedProject(
          ProjectLanguage.reactJs,
          isXcodeProject: false,
        );
      }
      if (content.contains('"vue"')) {
        return const _DetectedProject(
          ProjectLanguage.vueJs,
          isXcodeProject: false,
        );
      }
      if (topLevelNames.contains('tsconfig.json') ||
          content.contains('"typescript"')) {
        return const _DetectedProject(
          ProjectLanguage.typescript,
          isXcodeProject: false,
        );
      }
      return const _DetectedProject(
        ProjectLanguage.javascript,
        isXcodeProject: false,
      );
    }

    if (topLevelNames.contains('CMakeLists.txt') ||
        topLevelNames.contains('Makefile')) {
      return const _DetectedProject(ProjectLanguage.cpp, isXcodeProject: false);
    }

    return null;
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
      final detected = await _detectProject(entity);
      if (detected == null) continue;

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
          language: detected.language,
          isXcodeProject: detected.isXcodeProject,
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
    // Java / Kotlin (Gradle, Maven)
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

  Future<void> openInEditor(ProjectModel project) {
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

  /// Which of Flutter's platform subfolders (ios/, android/, ...) this
  /// project actually has, in [FlutterPlatformTarget.all] order. Empty for
  /// non-Flutter projects, or a Flutter project with none of them checked
  /// out (e.g. a `flutter create --platforms` that omitted some).
  Future<List<FlutterPlatformTarget>> availableFlutterPlatformTargets(
    ProjectModel project,
  ) async {
    if (project.language != ProjectLanguage.flutter) return [];

    final available = <FlutterPlatformTarget>[];
    for (final target in FlutterPlatformTarget.all) {
      if (await Directory('${project.path}/${target.relativeDir}').exists()) {
        available.add(target);
      }
    }
    return available;
  }

  /// Opens a Flutter project's platform subfolder in its target's IDE. For
  /// Xcode/Visual Studio targets, points it at the actual project file a
  /// level down (e.g. Runner.xcworkspace) rather than the bare subfolder,
  /// since that's what those IDEs expect to be opened with.
  Future<void> openFlutterPlatformTarget(
    ProjectModel project,
    FlutterPlatformTarget target,
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
