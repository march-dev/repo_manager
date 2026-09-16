import 'dart:io';

import '../../repo_manager.dart';

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

/// Finds the best available app icon for a detected project — pure
/// filesystem/image-header probing, no persistence of its own.
class ProjectIconFinder {
  const ProjectIconFinder();

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
  Future<String> findIconPath(
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

  /// The first top-level subfolder of [dir] that contains an Info.plist —
  /// the Runner/-style folder an Xcode-managed project (native or a
  /// Flutter host project's ios//macos/) keeps its actual source, asset
  /// catalog, and Info.plist in, rather than at the project root itself.
  Future<Directory?> _findInfoPlistFolder(Directory dir) async {
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
}
