import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../repo_manager.dart';

/// Resolving which IDE a project opens in, actually launching it (or one
/// of its native platform-target subfolders) there, and tracking recently
/// opened projects.
class IdeLauncherRepo {
  IdeLauncherRepo({
    required Box box,
    required AppSettingsRepo appSettingsRepo,
  })  : _box = box,
        _appSettingsRepo = appSettingsRepo;

  final Box _box;
  final AppSettingsRepo _appSettingsRepo;

  /// Which IDE a project would actually open in. A C++ project that's
  /// already an Xcode project (has its own .xcodeproj/.xcworkspace) always
  /// resolves to Xcode on a macOS host, regardless of the C++ group's
  /// configured preference — no other editor can build/run it the way
  /// Xcode can. On any other host, Xcode can't run at all (isIdeAvailableOnHost),
  /// so this falls through to the group's own (host-aware) preference
  /// instead of resolving to an IDE that could never actually launch.
  /// Otherwise falls back to VS Code for languages with no dedicated
  /// preferred-IDE setting (see LanguageGroup) — it's the one IDE that shows
  /// up as a candidate for every group currently defined.
  Ide resolveIde(ProjectModel project) {
    if (project.language == ProjectLanguage.cpp &&
        project.isXcodeProject &&
        Platform.isMacOS) {
      return Ide.xcode;
    }
    final group = LanguageGroup.forLanguage(
      project.language,
      isAndroidProject: project.isAndroidProject,
    );
    return group != null ? _appSettingsRepo.getPreferredIde(group) : Ide.vscode;
  }

  static const _recentlyOpenedProjectPathsKey = 'recentlyOpenedProjectPathsKey';
  static const _recentlyOpenedLimit = 8;

  /// Bumped every time [recordProjectOpened] runs. IdeLauncherUseCases
  /// exposes this straight through to the UI (see its own doc).
  final recentlyOpenedVersion = ValueNotifier<int>(0);

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
        // Cross-platform CLI, identical everywhere — VS Code proactively
        // prompts to install this on first launch on every OS, making it
        // the one command here safe to assume without any OS branching.
        case Ide.vscode:
          await Process.run('code', [path]);
        // macOS-only per isIdeAvailableOnHost — xed is Xcode's own
        // bundled CLI launcher (ships with the Command Line Tools).
        case Ide.xcode:
          await Process.run('xed', [path]);
        // Windows-only per isIdeAvailableOnHost — devenv is Visual
        // Studio's own documented CLI launcher (needs VS's own tools
        // directory on PATH, e.g. via a Developer Command Prompt).
        case Ide.visualStudio:
          await Process.run('devenv', [path]);
        // Everything else is JetBrains-family (Android Studio included —
        // it's JetBrains-based) and reachable the same way on every OS:
        // via the lowercase launcher script JetBrains Toolbox's "Generate
        // Shell Scripts" creates (a .cmd wrapper on Windows, a plain
        // shell script on macOS/Linux) — but that's an opt-in feature
        // most users haven't turned on, unlike VS Code's `code` prompt,
        // so macOS specifically still prefers `open -a` (works purely
        // from the app being installed, no separate CLI setup needed);
        // Windows/Linux have no such fallback, so they rely on that
        // launcher script actually existing.
        case Ide.androidStudio:
          await _openGuiApp(path,
              macAppName: 'Android Studio', cliCommand: 'studio');
        case Ide.webStorm:
          await _openGuiApp(path,
              macAppName: 'WebStorm', cliCommand: 'webstorm');
        case Ide.pyCharm:
          await _openGuiApp(path, macAppName: 'PyCharm', cliCommand: 'pycharm');
        case Ide.goLand:
          await _openGuiApp(path, macAppName: 'GoLand', cliCommand: 'goland');
        case Ide.rustRover:
          await _openGuiApp(path,
              macAppName: 'RustRover', cliCommand: 'rustrover');
        case Ide.phpStorm:
          await _openGuiApp(path,
              macAppName: 'PhpStorm', cliCommand: 'phpstorm');
        // JetBrains' own CLI command for IntelliJ IDEA is `idea`, not
        // `intellijidea` — its Toolbox-generated script keeps the
        // product's traditional short name.
        case Ide.intellijIdea:
          await _openGuiApp(path,
              macAppName: 'IntelliJ IDEA', cliCommand: 'idea');
        case Ide.clion:
          await _openGuiApp(path, macAppName: 'CLion', cliCommand: 'clion');
        case Ide.rider:
          await _openGuiApp(path, macAppName: 'Rider', cliCommand: 'rider');
      }
    } on ProcessException {
      // Preferred IDE's launcher isn't available on PATH; nothing we can do.
    }
  }

  Future<void> _openGuiApp(
    String path, {
    required String macAppName,
    required String cliCommand,
  }) {
    return Platform.isMacOS
        ? Process.run('open', ['-a', macAppName, path])
        : Process.run(cliCommand, [path]);
  }

  // Flutter, React Native, Capacitor, Cordova, and Ionic all keep their
  // native platform projects in the same ios/android(/macos/windows/
  // linux) subfolders (PlatformTarget.all); NativeScript uses its own
  // nested platforms/ios, platforms/android layout instead
  // (PlatformTarget.nativeScript) — see _targetsFor.
  static const _platformTargetFrameworks = {
    ProjectFramework.flutter,
    ProjectFramework.reactNative,
    ProjectFramework.capacitor,
    ProjectFramework.cordova,
    ProjectFramework.ionic,
    ProjectFramework.nativeScript,
  };

  static List<PlatformTarget> _targetsFor(ProjectFramework? framework) =>
      framework == ProjectFramework.nativeScript
          ? PlatformTarget.nativeScript
          : PlatformTarget.all;

  /// Which of this project's native platform subfolders (ios/, android/,
  /// ... — see [_targetsFor]) it actually has. Empty for a project whose
  /// framework doesn't use this convention, or one with none of them
  /// checked out (e.g. a `flutter create --platforms` that omitted some).
  Future<List<PlatformTarget>> availablePlatformTargets(
    ProjectModel project,
  ) async {
    if (!_platformTargetFrameworks.contains(project.framework)) return [];

    final available = <PlatformTarget>[];
    for (final target in _targetsFor(project.framework)) {
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

    try {
      for (final extension in target.preferredExtensions) {
        await for (final entity in dir.list(followLinks: false)) {
          if (entity.path.endsWith(extension)) {
            path = entity.path;
            break;
          }
        }
        if (path != dir.path) break;
      }
    } on FileSystemException catch (error, stackTrace) {
      // Falls back to opening the bare target folder — same as when none
      // of preferredExtensions matched anything inside it.
      logError('List directory ${dir.path}', error, stackTrace);
    }

    await openPathInIde(path, target.ide);
  }

  /// Opens [path] (a project's own folder) in the OS's native file
  /// manager — Finder, Explorer, or whichever handles `xdg-open` on Linux
  /// — rather than in an editor.
  Future<void> revealInFileManager(String path) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer.exe', [path]);
      } else {
        await Process.run('xdg-open', [path]);
      }
    } on ProcessException {
      // No native file manager launcher available on PATH; nothing we
      // can do.
    }
  }
}
