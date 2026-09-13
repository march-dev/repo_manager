import 'ide.enum.dart';

/// A native platform project embedded inside a cross-platform project's own
/// platform subfolder (e.g. `ios/`, `android/`) — each opens in a different
/// IDE and, for the Xcode/Visual Studio ones, targets a specific project
/// file a level down rather than the subfolder itself.
///
/// [all] matches Flutter's and React Native's identical `ios/`/`android/`
/// (/`macos/`/`windows/`/`linux/` via their own community-maintained
/// desktop targets) folder convention.
///
/// TODO: Capacitor/Cordova/Ionic apps use this same ios/android convention
/// (via `npx cap add ios/android`) and could reuse [all] directly, but
/// aren't detected as their own ProjectFramework yet — and since they wrap
/// an existing web framework choice (Angular/React/Vue) rather than
/// replacing it, detecting them means layering a second signal on top of
/// the existing framework detection, not just adding another priority
/// branch to it.
///
/// TODO: NativeScript needs its own target list — same idea, but its
/// platform folders live nested under `platforms/` (`platforms/ios`,
/// `platforms/android`) rather than at the project root — and it isn't
/// detected as a ProjectFramework yet either.
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
    PlatformTarget(
      label: 'Linux',
      ide: Ide.visualStudio,
      relativeDir: 'linux',
      preferredExtensions: ['.sln'],
    ),
  ];
}
