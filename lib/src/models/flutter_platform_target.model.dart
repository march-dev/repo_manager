import 'ide.enum.dart';

/// A native platform project embedded inside a Flutter project's own
/// platform subfolder (e.g. `ios/`, `android/`) — each opens in a different
/// IDE and, for the Xcode/Visual Studio ones, targets a specific project
/// file a level down rather than the subfolder itself.
class FlutterPlatformTarget {
  const FlutterPlatformTarget({
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
    FlutterPlatformTarget(
      label: 'Android',
      ide: Ide.androidStudio,
      relativeDir: 'android',
    ),
    FlutterPlatformTarget(
      label: 'iOS',
      ide: Ide.xcode,
      relativeDir: 'ios',
      preferredExtensions: ['.xcworkspace', '.xcodeproj'],
    ),
    FlutterPlatformTarget(
      label: 'macOS',
      ide: Ide.xcode,
      relativeDir: 'macos',
      preferredExtensions: ['.xcworkspace', '.xcodeproj'],
    ),
    FlutterPlatformTarget(
      label: 'Windows',
      ide: Ide.visualStudio,
      relativeDir: 'windows',
      preferredExtensions: ['.sln'],
    ),
    FlutterPlatformTarget(
      label: 'Linux',
      ide: Ide.visualStudio,
      relativeDir: 'linux',
      preferredExtensions: ['.sln'],
    ),
  ];
}
