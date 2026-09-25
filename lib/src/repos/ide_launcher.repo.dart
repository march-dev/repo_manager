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

  // The GUI-app name (for macOS's `open -a`) and CLI launcher command (for
  // openPathInIde's own non-macOS fallback, and isIdeInstalled's PATH
  // check below) for every IDE reachable through _openGuiApp — every Ide
  // value except vscode/xcode/visualStudio/unity/unrealEngine, each of
  // which either has its own dedicated CLI (xed, devenv) or its own
  // bespoke launch logic in openPathInIde's switch above this map.
  static const _guiAppInfo = <Ide, ({String macAppName, String cliCommand})>{
    Ide.androidStudio: (macAppName: 'Android Studio', cliCommand: 'studio'),
    Ide.webStorm: (macAppName: 'WebStorm', cliCommand: 'webstorm'),
    Ide.pyCharm: (macAppName: 'PyCharm', cliCommand: 'pycharm'),
    Ide.goLand: (macAppName: 'GoLand', cliCommand: 'goland'),
    Ide.rustRover: (macAppName: 'RustRover', cliCommand: 'rustrover'),
    Ide.phpStorm: (macAppName: 'PhpStorm', cliCommand: 'phpstorm'),
    // JetBrains' own CLI command for IntelliJ IDEA is `idea`, not
    // `intellijidea` — its Toolbox-generated script keeps the product's
    // traditional short name.
    Ide.intellijIdea: (macAppName: 'IntelliJ IDEA', cliCommand: 'idea'),
    Ide.clion: (macAppName: 'CLion', cliCommand: 'clion'),
    Ide.rider: (macAppName: 'Rider', cliCommand: 'rider'),
  };

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

  /// Whether [ide] is actually installed on this machine — a narrower
  /// check than [isIdeAvailableOnHost] (which only asks whether this OS
  /// could ever run it at all, e.g. ruling out Visual Studio on macOS).
  /// The one primitive [notInstalledIdes] caches results from; callers
  /// needing a project- or target-specific answer go through
  /// [resolveInstalledIde]/[resolveIdeForTarget] instead of calling this
  /// directly.
  Future<bool> isIdeInstalled(Ide ide) async {
    if (!isIdeAvailableOnHost(ide)) return false;

    switch (ide) {
      // Checked the same way openPathInIde actually launches it — via the
      // `code` CLI, identically on every OS (see its own case's doc) —
      // rather than an app-bundle check, since having the app installed
      // doesn't by itself guarantee its CLI was ever added to PATH (a
      // one-time, opt-in step in VS Code itself).
      case Ide.vscode:
        return _commandExists('code');
      case Ide.xcode:
        return Directory('/Applications/Xcode.app').exists();
      case Ide.visualStudio:
        return _commandExists('devenv');
      // Unity Hub, not any particular Editor version, is what openPathInIde
      // actually launches (see its own doc) — same app/command checked
      // here.
      case Ide.unity:
        return Platform.isMacOS
            ? Directory('/Applications/Unity Hub.app').exists()
            : _commandExists('unityhub');
      // No single reliable install marker exists: Epic Games Launcher can
      // install any number of engine versions under a folder the user
      // picked themselves, and openPathInIde launches Unreal purely
      // through the OS's own file association for .uproject rather than a
      // known app/CLI of its own (see its own doc). Left permanently
      // "installed" rather than guessing wrong in either direction.
      case Ide.unrealEngine:
        return true;
      default:
        final info = _guiAppInfo[ide]!;
        return Platform.isMacOS
            ? Directory('/Applications/${info.macAppName}.app').exists()
            : _commandExists(info.cliCommand);
    }
  }

  Future<bool> _commandExists(String command) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        [command],
      );
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  Future<Set<Ide>>? _notInstalledIdesCache;

  /// Every [Ide] value [isIdeInstalled] returns false for, checked once and
  /// cached until [refreshNotInstalledIdes] explicitly reruns it — an IDE
  /// showing up/disappearing mid-session is rare enough not to be worth
  /// re-scanning the filesystem/PATH for on every call. The single source
  /// every "which IDEs can this project actually open in" surface reads
  /// from — Settings' preferred-IDE picker, the context menu's "Open"/
  /// "Open With"/platform-target entries, and Explorer/project details'
  /// hover hint + tap-to-open all resolve through this same cached set
  /// (via [resolveInstalledIde]/[resolveIdeForTarget] below) rather than
  /// each re-deriving their own.
  Future<Set<Ide>> notInstalledIdes() {
    return _notInstalledIdesCache ??= _computeNotInstalledIdes();
  }

  /// Forces a fresh scan, replacing whatever [notInstalledIdes] had cached —
  /// every screen's own manual refresh (a header button, F5) reruns this
  /// alongside its own refresh, on the same reasoning: a stale project list/
  /// size figure is exactly what a manual refresh exists to fix, and an
  /// IDE installed/removed mid-session is the same kind of staleness.
  Future<Set<Ide>> refreshNotInstalledIdes() {
    return _notInstalledIdesCache = _computeNotInstalledIdes();
  }

  Future<Set<Ide>> _computeNotInstalledIdes() async {
    final checks = await Future.wait([
      for (final ide in Ide.values)
        isIdeInstalled(ide)
            .then((installed) => (ide: ide, installed: installed)),
    ]);
    return {
      for (final check in checks)
        if (!check.installed) check.ide,
    };
  }

  /// [resolveIde]'s own result, moved off a [notInstalledIdes] entry onto
  /// the next candidate in that project's [LanguageGroup] preference order
  /// that isn't — the same fallback [SettingsState] itself persists (see
  /// its own _reselectNotInstalledPreferences), just resolved fresh here
  /// rather than assuming whatever's in Hive already reflects it (nothing
  /// forces Settings to have been opened this session). Null only when
  /// every one of that group's own candidates (including its universal
  /// [Ide.vscode] fallback) turns out not installed — e.g. resolveIde's own
  /// bare vscode default for a language with no [LanguageGroup] at all,
  /// with vscode itself missing.
  Ide? resolveInstalledIde(ProjectModel project, Set<Ide> notInstalledIdes) {
    final resolved = resolveIde(project);
    if (!notInstalledIdes.contains(resolved)) return resolved;

    final group = LanguageGroup.forLanguage(
      project.language,
      isAndroidProject: project.isAndroidProject,
    );
    if (group == null) return null;

    for (final candidate in group.candidatesOnHost) {
      if (!notInstalledIdes.contains(candidate)) return candidate;
    }
    return null;
  }

  /// [target]'s own IDE if installed, else [Ide.vscode] on the bare
  /// subfolder (see [openPlatformTarget]'s own doc for why that's a
  /// sensible substitute here specifically) — null only when neither is
  /// installed, meaning nothing on this machine can open this target at
  /// all.
  Ide? resolveIdeForTarget(PlatformTarget target, Set<Ide> notInstalledIdes) {
    if (!notInstalledIdes.contains(target.ide)) return target.ide;
    if (!notInstalledIdes.contains(Ide.vscode)) return Ide.vscode;
    return null;
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
        case Ide.webStorm:
        case Ide.pyCharm:
        case Ide.goLand:
        case Ide.rustRover:
        case Ide.phpStorm:
        case Ide.intellijIdea:
        case Ide.clion:
        case Ide.rider:
          final info = _guiAppInfo[ide]!;
          await _openGuiApp(path,
              macAppName: info.macAppName, cliCommand: info.cliCommand);
        // Unity Hub, not Unity's own Editor binary, is what actually opens
        // an existing project — it resolves the project's own Editor
        // version from ProjectSettings/ProjectVersion.txt and launches
        // that, rather than this needing to guess which installed Editor
        // version/executable to invoke directly.
        case Ide.unity:
          Platform.isMacOS
              ? await Process.run(
                  'open',
                  ['-a', 'Unity Hub', '--args', '-projectPath', path],
                )
              : await Process.run(
                  'unityhub',
                  ['--', '--projectPath', path],
                );
        // By the time this runs, path already points at the project's own
        // .uproject file (openPlatformTarget resolved it via
        // PlatformTarget.unrealEngine's preferredExtensions) — opening it
        // through the OS's own file association is what actually launches
        // Unreal Editor, the same way double-clicking it would.
        case Ide.unrealEngine:
          Platform.isMacOS
              ? await Process.run('open', [path])
              : Platform.isWindows
                  ? await Process.run('cmd', ['/c', 'start', '', path])
                  : await Process.run('xdg-open', [path]);
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
  // (PlatformTarget.nativeScript); Unity/Unreal Engine each get a single
  // action pointed at the project's own root instead of a subfolder
  // (PlatformTarget.unity/PlatformTarget.unrealEngine) — see _targetsFor.
  static const _platformTargetFrameworks = {
    ProjectFramework.flutter,
    ProjectFramework.reactNative,
    ProjectFramework.capacitor,
    ProjectFramework.cordova,
    ProjectFramework.ionic,
    ProjectFramework.nativeScript,
    ProjectFramework.unity,
    ProjectFramework.unrealEngine,
  };

  static List<PlatformTarget> _targetsFor(ProjectFramework? framework) {
    switch (framework) {
      case ProjectFramework.nativeScript:
        return PlatformTarget.nativeScript;
      case ProjectFramework.unity:
        return PlatformTarget.unity;
      case ProjectFramework.unrealEngine:
        return PlatformTarget.unrealEngine;
      default:
        return PlatformTarget.all;
    }
  }

  /// Which of this project's native platform subfolders (ios/, android/,
  /// ... — see [_targetsFor]) it actually has. Empty for a project whose
  /// framework doesn't use this convention, or one with none of them
  /// checked out (e.g. a `flutter create --platforms` that omitted some).
  /// Also drops a checked-out target whose own IDE can't run on this host
  /// at all (e.g. a Windows subfolder's Visual Studio, on a macOS/Linux
  /// host) — otherwise "Open Windows" would still show up as a clickable
  /// menu entry that's guaranteed to silently fail the moment it's tapped.
  Future<List<PlatformTarget>> availablePlatformTargets(
    ProjectModel project,
  ) async {
    if (!_platformTargetFrameworks.contains(project.framework)) return [];

    final available = <PlatformTarget>[];
    for (final target in _targetsFor(project.framework)) {
      if (!isIdeAvailableOnHost(target.ide)) continue;
      if (await Directory('${project.path}/${target.relativeDir}').exists()) {
        available.add(target);
      }
    }
    return available;
  }

  /// Opens a project's native platform subfolder in [ide] — resolved by the
  /// caller via [resolveIdeForTarget], not re-derived here, so what's
  /// actually launched always matches whatever a menu already showed for
  /// it. For Xcode/Visual Studio targets (i.e. [ide] == target.ide), points
  /// it at the actual project file a level down (e.g. Runner.xcworkspace)
  /// rather than the bare subfolder, since that's what those IDEs expect to
  /// be opened with; skips that search entirely when [ide] is
  /// [resolveIdeForTarget]'s own VS Code fallback instead — preferredExtensions
  /// only mean anything to target's own IDE, not to a fallback that never
  /// asked for one.
  Future<void> openPlatformTarget(
    ProjectModel project,
    PlatformTarget target,
    Ide ide,
  ) async {
    final dir = Directory('${project.path}/${target.relativeDir}');

    if (ide != target.ide) {
      await openPathInIde(dir.path, ide);
      return;
    }

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

    await openPathInIde(path, ide);
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
