import 'dart:io';

import '../../repo_manager.dart';

class DetectedProject {
  const DetectedProject(
    this.language, {
    this.framework,
    this.isXcodeProject = false,
    this.isAndroidProject = false,
  });

  final ProjectLanguage language;
  final ProjectFramework? framework;
  final bool isXcodeProject;

  // A plain (non-Flutter) Java/Kotlin project with its own Android app
  // module — see _androidFramework's own detection. A platform/OS target,
  // the same category as isXcodeProject, not a ProjectFramework — Android
  // isn't a framework layered on Java/Kotlin the way Flutter/React are,
  // it's what the whole project targets.
  final bool isAndroidProject;
}

/// Identifies whether a directory is a project of some recognized
/// language/framework — pure filesystem marker-file checks, no
/// persistence. Split out from ProjectScanner (which uses it to build the
/// full project tree) specifically so ProjectDirectoryRepo can also depend
/// on it directly for its own "is this a project" check, without the two
/// repos needing to depend on each other.
class ProjectLanguageDetector {
  const ProjectLanguageDetector();

  /// Whether [dir] looks like a project of any recognized kind.
  Future<bool> isProjectDir(Directory dir) async {
    return (await detectProject(dir)) != null;
  }

  /// The first top-level subfolder of [dir] that contains an Info.plist —
  /// the Runner/-style folder an Xcode-managed project (native or a
  /// Flutter host project's ios//macos/) keeps its actual source, asset
  /// catalog, and Info.plist in, rather than at the project root itself.
  Future<Directory?> findInfoPlistFolder(Directory dir) async {
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! Directory) continue;
        if (await File('${entity.path}/Info.plist').exists()) return entity;
      }
    } on FileSystemException catch (error, stackTrace) {
      logError('List directory ${dir.path}', error, stackTrace);
    }
    return null;
  }

  // Same conventional single-module `app/` layout project_icon_finder.dart
  // already checks for a plain (non-Flutter) Android app's own manifest —
  // distinguishes it from a backend/plain JVM project so LanguageGroup can
  // offer separate preferred-IDE defaults for the two. A multi-module
  // project with a differently-named app module won't be caught by this,
  // same limitation the icon finder already has.
  Future<bool> _isAndroidProject(Directory projectDir) =>
      File('${projectDir.path}/app/src/main/AndroidManifest.xml').exists();

  Future<Set<String>> _dirEntryNames(Directory dir) async {
    final names = <String>{};
    try {
      await for (final entity in dir.list(followLinks: false)) {
        names.add(entity.path.split(Platform.pathSeparator).last);
      }
    } on FileSystemException catch (error, stackTrace) {
      logError('List directory ${dir.path}', error, stackTrace);
    }
    return names;
  }

  /// Identifies a directory as a project of a specific language by looking
  /// for that ecosystem's own marker file(s) — the same idea as `pubspec.yaml`
  /// for Dart/Flutter, generalized to the other languages ProjectLanguage
  /// covers. Returns null if the directory doesn't look like any recognized
  /// kind of project — including when it can't actually be read (permission
  /// error, deleted mid-scan, ...), same as a genuine non-match, rather than
  /// letting that one directory's error abort the whole scan it's part of.
  Future<DetectedProject?> detectProject(Directory projectDir) async {
    try {
      return await _detectProject(projectDir);
    } on FileSystemException catch (error, stackTrace) {
      logError('Detect project type for ${projectDir.path}', error, stackTrace);
      return null;
    }
  }

  Future<DetectedProject?> _detectProject(Directory projectDir) async {
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
      return DetectedProject(
        ProjectLanguage.dart,
        framework: framework,
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
      return const DetectedProject(
        ProjectLanguage.csharp,
        framework: ProjectFramework.unity,
      );
    }

    // Unreal's own marker — same reasoning as Unity above, checked ahead
    // of the generic C++ (CMakeLists.txt/Makefile) detection, since
    // Unreal's own generated build files could otherwise be mistaken for
    // a plain CMake-based C++ project.
    if (hasExtension('.uproject')) {
      return const DetectedProject(
        ProjectLanguage.cpp,
        framework: ProjectFramework.unrealEngine,
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
        final infoPlistFolder = await findInfoPlistFolder(projectDir);
        if (infoPlistFolder != null) {
          sourceNames = await _dirEntryNames(infoPlistFolder);
        }
      }
      bool sourceHasExtension(String extension) =>
          sourceNames.any((name) => name.endsWith(extension));

      if (topLevelNames.contains('Package.swift') ||
          sourceHasExtension('.swift')) {
        return const DetectedProject(
          ProjectLanguage.swift,
          isXcodeProject: true,
        );
      }
      if (sourceHasExtension('.cpp') ||
          sourceHasExtension('.hpp') ||
          sourceHasExtension('.cc') ||
          sourceHasExtension('.cxx')) {
        return const DetectedProject(
          ProjectLanguage.cpp,
          isXcodeProject: true,
        );
      }
      return const DetectedProject(
        ProjectLanguage.objectiveC,
        isXcodeProject: true,
      );
    }

    // Gradle's Kotlin DSL (build.gradle.kts) or any top-level .kt/.kts file
    // is a strong enough signal to call the whole project Kotlin over Java.
    if (topLevelNames.contains('build.gradle.kts') ||
        hasExtension('.kt') ||
        hasExtension('.kts')) {
      return DetectedProject(
        ProjectLanguage.kotlin,
        isAndroidProject: await _isAndroidProject(projectDir),
      );
    }
    if (topLevelNames.contains('build.gradle') ||
        topLevelNames.contains('settings.gradle') ||
        topLevelNames.contains('pom.xml')) {
      return DetectedProject(
        ProjectLanguage.java,
        isAndroidProject: await _isAndroidProject(projectDir),
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
      return DetectedProject(
        ProjectLanguage.csharp,
        framework: hasXamarinMarker ? ProjectFramework.xamarin : null,
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
      //
      // Ionic/Capacitor/Cordova are the same kind of wrapper, one level up
      // again: an Ionic app is nearly always also a Capacitor app these
      // days (and both wrap Angular/React/Vue/vanilla), so Ionic's own
      // marker — the more informative label — is checked first, ahead of
      // Capacitor's, ahead of every underlying web-framework branch below.
      // Cordova has no single reliable package.json dependency name (its
      // CLI tooling varies), but every Cordova project has a root
      // config.xml, so that's checked instead.
      final ProjectFramework? framework;
      if (content.contains('"react-native"')) {
        framework = ProjectFramework.reactNative;
      } else if (content.contains('"@ionic/angular"') ||
          content.contains('"@ionic/react"') ||
          content.contains('"@ionic/vue"')) {
        framework = ProjectFramework.ionic;
      } else if (content.contains('"@capacitor/core"')) {
        framework = ProjectFramework.capacitor;
      } else if (topLevelNames.contains('config.xml')) {
        framework = ProjectFramework.cordova;
      } else if (content.contains('"@nativescript/core"')) {
        framework = ProjectFramework.nativeScript;
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

      return DetectedProject(
        language,
        framework: framework,
      );
    }

    if (topLevelNames.contains('go.mod')) {
      return const DetectedProject(ProjectLanguage.go);
    }

    if (topLevelNames.contains('Cargo.toml')) {
      return const DetectedProject(ProjectLanguage.rust);
    }

    if (topLevelNames.contains('composer.json')) {
      return const DetectedProject(ProjectLanguage.php);
    }

    // No single universal marker the way other ecosystems have one — these
    // are the common ones across the several packaging/dependency tools
    // Python projects use (pip/Poetry/Pipenv/plain setuptools).
    if (topLevelNames.contains('pyproject.toml') ||
        topLevelNames.contains('setup.py') ||
        topLevelNames.contains('Pipfile') ||
        topLevelNames.contains('requirements.txt')) {
      return const DetectedProject(ProjectLanguage.python);
    }

    if (topLevelNames.contains('CMakeLists.txt') ||
        topLevelNames.contains('Makefile')) {
      return const DetectedProject(ProjectLanguage.cpp);
    }

    return null;
  }
}
