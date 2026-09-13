import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

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
        ),
      );
    }

    return projects;
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
