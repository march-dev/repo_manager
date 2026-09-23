import 'ide.enum.dart';

/// A native platform project embedded inside a cross-platform project's own
/// platform subfolder (e.g. `ios/`, `android/`) — each opens in a different
/// IDE and, for the Xcode/Visual Studio ones, targets a specific project
/// file a level down rather than the subfolder itself.
///
/// [all] matches Flutter's and React Native's identical `ios/`/`android/`
/// (/`macos/`/`windows/`/`linux/` via their own community-maintained
/// desktop targets) folder convention — also reused as-is by Capacitor/
/// Cordova/Ionic (`npx cap add ios/android`), which keep the same bare
/// `ios/`/`android/` layout at the project root.
///
/// [nativeScript] is NativeScript's own separate list — its platform
/// folders live nested under `platforms/` (`platforms/ios`,
/// `platforms/android`) rather than at the project root, so it can't
/// share [all] directly.
class PlatformTarget {
  const PlatformTarget({
    required this.label,
    required this.ide,
    required this.relativeDir,
    this.preferredExtensions = const [],
  });

  final String label;
  final Ide ide;
  final String relativeDir;

  // Checked in order inside relativeDir for the actual project file its IDE
  // expects (e.g. Xcode's .xcworkspace over its .xcodeproj). Empty means the
  // subfolder itself is what the IDE should be pointed at (Android Studio
  // opens a Gradle project directory directly).
  final List<String> preferredExtensions;

  static const all = [
    PlatformTarget(
      label: 'Android',
      ide: Ide.androidStudio,
      relativeDir: 'android',
    ),
    PlatformTarget(
      label: 'iOS',
      ide: Ide.xcode,
      relativeDir: 'ios',
      preferredExtensions: ['.xcworkspace', '.xcodeproj'],
    ),
    PlatformTarget(
      label: 'macOS',
      ide: Ide.xcode,
      relativeDir: 'macos',
      preferredExtensions: ['.xcworkspace', '.xcodeproj'],
    ),
    PlatformTarget(
      label: 'Windows',
      ide: Ide.visualStudio,
      relativeDir: 'windows',
      preferredExtensions: ['.sln'],
    ),
    // Visual Studio doesn't exist on Linux at all — its own Linux desktop
    // target (typically CMake/GTK-based) has no equivalent single-project-
    // file IDE the way Windows'/macOS' targets do, so this just opens the
    // bare folder in VS Code, cross-platform-safe by construction.
    PlatformTarget(
      label: 'Linux',
      ide: Ide.vscode,
      relativeDir: 'linux',
    ),
  ];

  // NativeScript only ever targets mobile — no desktop platform folders
  // of its own, unlike Flutter/React Native/Capacitor/Cordova/Ionic.
  static const nativeScript = [
    PlatformTarget(
      label: 'Android',
      ide: Ide.androidStudio,
      relativeDir: 'platforms/android',
    ),
    PlatformTarget(
      label: 'iOS',
      ide: Ide.xcode,
      relativeDir: 'platforms/ios',
      preferredExtensions: ['.xcworkspace', '.xcodeproj'],
    ),
  ];

  // Unity/Unreal Engine projects have no ios/android-style subfolders —
  // the "target" is the project itself, so relativeDir is the project's
  // own root rather than a folder a level down. A single-entry list
  // still fits the same submenu mechanism Flutter/React Native use for
  // their (multiple) platform targets, just with one action instead of
  // several: "open the actual game engine editor", as an addition to,
  // not a replacement for, the project's normal C#/C++ preferred-IDE
  // default (see LanguageGroup's own doc).
  static const unity = [
    PlatformTarget(label: 'Unity', ide: Ide.unity, relativeDir: ''),
  ];

  // Unreal Editor needs to be pointed at the project's own .uproject
  // file, not its bare containing folder.
  static const unrealEngine = [
    PlatformTarget(
      label: 'Unreal Engine',
      ide: Ide.unrealEngine,
      relativeDir: '',
      preferredExtensions: ['.uproject'],
    ),
  ];
}
