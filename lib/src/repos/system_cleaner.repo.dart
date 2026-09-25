import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../repo_manager.dart';

/// Finds and deletes reclaimable dev-tool caches on the current machine —
/// System Cleaner's real per-platform filesystem walk (see
/// SystemCleanerState's own doc for how this replaced its earlier mock
/// data).
///
/// Each known cache is declared once as an [_EntryDef] below, with a
/// resolver per relevant OS (mac/Linux/Windows) rather than one fixed
/// path — many of these tools also let a user override their cache
/// location via an environment variable, which [_EntryDef.envVar], when
/// set and non-empty, always takes over the OS default for. A resolver
/// returning null means "not applicable on this OS" (e.g. every entry
/// under Xcode Related, which only ever resolves anything on macOS) —
/// [scan] silently drops it, the same as a resolved path that turns out
/// not to exist on disk.
///
/// [scan] itself only resolves *structure* — which entries currently
/// exist — cheaply (existence checks, no directory walk); each entry's
/// own size is a separate, heavier concern: [computeEntrySize] walks it
/// (each of [CleanerEntry.path]/[CleanerEntry.extraPaths] on its own
/// isolate — see [_isolatePathSize]'s own doc) and persists the result by
/// path in [_box], the same forceRefresh-gated shape as ProjectSizeRepo's
/// own per-project size. SystemCleanerState calls this once per entry,
/// concurrently, and applies each one's result the moment it's ready
/// (see its own doc) — not scan() itself — so a huge cache's own walk
/// never blocks every other entry's row from showing its number, or
/// blocks this app's own UI isolate while it runs.
class SystemCleanerRepo {
  const SystemCleanerRepo({required Box box}) : _box = box;

  final Box _box;

  String _entrySizeCacheKey(String path) => 'systemCleanerEntrySize:$path';

  /// Which entries currently exist, with [CleanerEntry.sizeBytes] filled
  /// in from the cache where available and [forceRefresh] is false, or
  /// left null otherwise — null means "not known yet", which is what
  /// tells SystemCleanerState which entries still need a fresh
  /// [computeEntrySize] call (see its own doc).
  Future<List<CleanerCategory>> scan({bool forceRefresh = false}) async {
    final defs = _categoryDefs();
    final resultsByCategoryId = {
      for (final def in defs) def.id: <CleanerEntry>[]
    };

    final tasks = <Future<void> Function()>[];
    for (final categoryDef in defs) {
      for (final entryDef in categoryDef.entries) {
        tasks.add(() async {
          final entry =
              await _resolveEntry(entryDef, forceRefresh: forceRefresh);
          if (entry != null) resultsByCategoryId[categoryDef.id]!.add(entry);
        });
      }
    }

    await runWithConcurrency(tasks, concurrency: Platform.numberOfProcessors);

    return [
      for (final categoryDef in defs)
        if (resultsByCategoryId[categoryDef.id]!.isNotEmpty)
          CleanerCategory(
            id: categoryDef.id,
            icon: categoryDef.icon,
            language: categoryDef.language,
            iconAssetPath: categoryDef.iconAssetPath,
            title: categoryDef.title,
            pinned: categoryDef.pinned,
            entries: resultsByCategoryId[categoryDef.id]!,
          ),
    ];
  }

  /// Recomputes [entry]'s real, current size from scratch — always a
  /// fresh walk, never the cache (that's [scan]'s own job) — and persists
  /// it as this path's new cached size before returning it. A result of
  /// 0 means this path turned out completely empty (e.g. the iOS
  /// Simulator recreating its own now-unused Caches directory) — the
  /// caller drops the entry entirely rather than showing a "0 B" row with
  /// a checkbox that would delete literally nothing, the same as [scan]
  /// silently dropping a path that doesn't exist at all.
  Future<int> computeEntrySize(CleanerEntry entry) async {
    var total = await _isolatePathSize(entry.path);
    for (final extraPath in entry.extraPaths) {
      total += await _isolatePathSize(extraPath);
    }
    await _box.put(_entrySizeCacheKey(entry.path), total);
    return total;
  }

  Future<void> deleteEntry(CleanerEntry entry) async {
    for (final path in [entry.path, ...entry.extraPaths]) {
      await _delete(path);
      // Otherwise a later forceRefresh: false scan would keep reporting
      // this now-deleted path's old size until the next forced rescan
      // happened to overwrite it.
      await _box.delete(_entrySizeCacheKey(path));
    }
  }

  Future<CleanerEntry?> _resolveEntry(
    _EntryDef def, {
    required bool forceRefresh,
  }) async {
    final path = await _resolveOverridablePath(def);
    if (path == null || !await _exists(path)) return null;

    final extraPaths = <String>[];
    for (final resolver in def.extraPathResolvers) {
      final extraPath = await resolver();
      if (extraPath != null && await _exists(extraPath)) {
        extraPaths.add(extraPath);
      }
    }

    // forceRefresh always leaves this null — SystemCleanerState's own
    // background refresh (see its own doc) then recomputes every entry
    // fresh via computeEntrySize, showing a shimmer per row in the
    // meantime rather than this scan itself blocking on every entry's
    // walk the way a single combined scan+size call used to.
    final cachedSize =
        forceRefresh ? null : _box.get(_entrySizeCacheKey(path)) as int?;

    // A cached size of exactly 0 means this was already known empty last
    // time — not worth showing a visible (about to shimmer/recompute) row
    // for in the meantime.
    if (cachedSize == 0) return null;

    return CleanerEntry(
      name: def.name,
      path: path,
      sizeBytes: cachedSize,
      extraPaths: extraPaths,
      icon: def.icon,
      iconAssetPath: def.iconAssetPath,
      defaultSelected: def.defaultSelected,
      safetyLevel: def.safetyLevel,
      safetyReason: def.safetyReason,
    );
  }

  Future<String?> _resolveOverridablePath(_EntryDef def) async {
    final envVar = def.envVar;
    if (envVar != null) {
      final overridden = _env(envVar);
      if (overridden != null) return overridden;
    }
    return def.pathResolver();
  }

  // Follows links (the default) — a top-level cache path is sometimes
  // itself a symlink (e.g. macOS's own /tmp, really
  // /private/tmp) — followLinks: false here would misreport it as
  // "not found"/a plain link rather than the real directory it points
  // to, undercounting its size to 0.
  Future<bool> _exists(String path) async =>
      await FileSystemEntity.type(path) != FileSystemEntityType.notFound;

  // Isolate.run spawns a fresh isolate, runs the given (necessarily
  // top-level/static — see _isolatePathSize's own doc) computation on it,
  // and shuts it back down once the result comes back — so this path's
  // own recursive walk/byte-summing runs entirely off this app's own UI
  // isolate, however big it turns out to be.
  Future<int> _isolatePathSize(String path) => Isolate.run(
        () => _computePathSize(path),
      );

  Future<void> _delete(String path) async {
    final type = await FileSystemEntity.type(path);
    switch (type) {
      case FileSystemEntityType.directory:
        // Empties the directory's own contents rather than deleting the
        // directory itself — every one of these tools recreates its own
        // cache folder the next time it runs anyway, and this is what
        // keeps deleting a symlinked entry (e.g. macOS's own /tmp, a
        // link to /private/tmp) safe: only what's really inside the
        // real target gets removed, never the shared link/mount node
        // other running processes may still be holding open.
        await for (final child in Directory(path).list(followLinks: false)) {
          await child.delete(recursive: true);
        }
      case FileSystemEntityType.file:
        await File(path).delete();
      default:
      // Already gone, or a link/pipe this repo doesn't touch.
    }
  }

  List<_CategoryDef> _categoryDefs() => [
        _CategoryDef(
          id: 'system',
          icon: Icons.storage_outlined,
          title: 'System',
          pinned: true,
          entries: [
            _EntryDef(
              name: 'User Caches',
              // Broad, shared with every other app on the machine, not
              // just dev tools — clearing it is generally safe (that's
              // what a caches directory is for) but sweeps up things a
              // user might not expect to lose right along with it.
              safetyLevel: CleanerSafetyLevel.caution,
              safetyReason: 'This clears cache directories for every app on '
                  'this machine, not just dev tools — some non-dev apps may '
                  'briefly need to rebuild their own caches after this.',
              pathResolver: () async {
                if (Platform.isMacOS) return _joinHome('Library/Caches');
                if (Platform.isLinux) return _joinHome('.cache');
                if (Platform.isWindows) return _env('LOCALAPPDATA');
                return null;
              },
            ),
            _EntryDef(
              name: 'Temporary Files',
              // A currently-running process can have a file open here
              // right now — usually harmless to clear, but not as
              // unconditionally safe as a tool's own dedicated cache.
              safetyLevel: CleanerSafetyLevel.caution,
              safetyReason: 'A currently-running process could have a file '
                  'open here right now.',
              pathResolver: () async {
                if (Platform.isWindows) return _env('TEMP');
                return '/tmp';
              },
            ),
          ],
        ),
        _CategoryDef(
          id: 'npm',
          icon: Icons.javascript_outlined,
          iconAssetPath: 'assets/images/tool/npm.png',
          title: 'npm',
          entries: [
            _EntryDef(
              name: 'npm cache',
              envVar: 'NPM_CONFIG_CACHE',
              pathResolver: () async {
                if (Platform.isWindows) {
                  return _envJoin('LOCALAPPDATA', 'npm-cache');
                }
                return _joinHome('.npm');
              },
            ),
            _EntryDef(
              name: 'Yarn cache',
              pathResolver: () async {
                if (Platform.isMacOS) return _joinHome('Library/Caches/Yarn');
                if (Platform.isLinux) return _joinHome('.cache/yarn');
                if (Platform.isWindows) {
                  return _envJoin('LOCALAPPDATA', 'Yarn/Cache');
                }
                return null;
              },
            ),
            _EntryDef(
              name: 'pnpm store',
              // pnpm hard-links/symlinks every project's node_modules
              // straight into this content-addressed store — clearing it
              // can leave other, already-installed projects with broken
              // links until they're reinstalled.
              safetyLevel: CleanerSafetyLevel.risky,
              defaultSelected: false,
              safetyReason: "Other projects' node_modules are hard-linked/"
                  'symlinked directly into this store — clearing it can '
                  'leave them broken until reinstalled.',
              pathResolver: () async {
                if (Platform.isMacOS) return _joinHome('Library/pnpm/store');
                if (Platform.isLinux) {
                  return _joinHome('.local/share/pnpm/store');
                }
                if (Platform.isWindows) {
                  return _envJoin('LOCALAPPDATA', 'pnpm/store');
                }
                return null;
              },
            ),
          ],
        ),
        _CategoryDef(
          id: 'dart_flutter',
          icon: Icons.flutter_dash_outlined,
          language: ProjectLanguage.dart,
          title: 'Dart Related',
          entries: [
            _EntryDef(
              name: 'Pub cache',
              envVar: 'PUB_CACHE',
              pathResolver: () async {
                if (Platform.isWindows) {
                  return _envJoin('LOCALAPPDATA', 'Pub/Cache');
                }
                return _joinHome('.pub-cache');
              },
            ),
            _EntryDef(
              name: 'Flutter engine cache',
              // Part of the SDK itself, not disposable project output —
              // every `flutter`/`dart` command stops working immediately
              // (not just "might", the way an ordinary rebuild-on-next-
              // use cache like npm's/Gradle's does) until this is
              // re-precached, which needs network access and can take a
              // while — not something to sweep up in a "select all"
              // clean without a deliberate opt-in.
              safetyLevel: CleanerSafetyLevel.risky,
              defaultSelected: false,
              safetyReason: 'This is part of the Flutter SDK itself, not '
                  'project output — every `flutter`/`dart` command fails '
                  "until it's re-downloaded, which needs network access.",
              iconAssetPath: ProjectFramework.flutter.iconAsset,
              pathResolver: () async {
                final root = _env('FLUTTER_ROOT');
                if (root != null) return joinPath(root, 'bin/cache');
                for (final candidate in [
                  _joinHome('flutter/bin/cache'),
                  '/opt/flutter/bin/cache',
                  '/usr/local/flutter/bin/cache',
                ]) {
                  if (candidate != null && await _exists(candidate)) {
                    return candidate;
                  }
                }
                return null;
              },
            ),
          ],
        ),
        // Every entry below only ever resolves anything on macOS — Xcode,
        // CocoaPods and the iOS Simulator are all macOS-only tooling —
        // so this category naturally never appears on Linux/Windows.
        _CategoryDef(
          id: 'apple',
          icon: Icons.apple,
          iconAssetPath: Ide.xcode.iconAsset,
          title: 'Xcode Related',
          entries: [
            _EntryDef(
              name: 'Xcode DerivedData',
              pathResolver: () async => Platform.isMacOS
                  ? _joinHome('Library/Developer/Xcode/DerivedData')
                  : null,
            ),
            _EntryDef(
              name: 'CocoaPods cache',
              pathResolver: () async => Platform.isMacOS
                  ? _joinHome('Library/Caches/CocoaPods')
                  : null,
            ),
            _EntryDef(
              name: 'Swift Package Manager cache',
              pathResolver: () async => Platform.isMacOS
                  ? _joinHome('Library/Caches/org.swift.swiftpm')
                  : null,
              extraPathResolvers: [
                () async => Platform.isMacOS
                    ? _joinHome('Library/org.swift.swiftpm/security')
                    : null,
              ],
            ),
            _EntryDef(
              name: 'iOS Simulator caches',
              pathResolver: () async => Platform.isMacOS
                  ? _joinHome('Library/Developer/CoreSimulator/Caches')
                  : null,
            ),
            _EntryDef(
              name: 'Xcode Archives',
              // Not a cache — real release archives a user made on
              // purpose. Shown for visibility (they can be sizeable) but
              // never pre-checked; see CleanerEntry.defaultSelected.
              defaultSelected: false,
              safetyLevel: CleanerSafetyLevel.risky,
              safetyReason: 'These are your own real release builds, not a '
                  'cache — deleting one is permanent.',
              pathResolver: () async => Platform.isMacOS
                  ? _joinHome('Library/Developer/Xcode/Archives')
                  : null,
            ),
          ],
        ),
        _CategoryDef(
          id: 'android',
          icon: Icons.android,
          iconAssetPath: 'assets/images/tool/gradle-dark.png',
          title: 'Gradle Related',
          entries: [
            _EntryDef(
              name: 'Gradle caches',
              pathResolver: () async {
                final gradleHome = _env('GRADLE_USER_HOME');
                if (gradleHome != null) return joinPath(gradleHome, 'caches');
                return _joinHome('.gradle/caches');
              },
            ),
            _EntryDef(
              name: 'Gradle wrapper distributions',
              pathResolver: () async {
                final gradleHome = _env('GRADLE_USER_HOME');
                if (gradleHome != null) {
                  return joinPath(gradleHome, 'wrapper/dists');
                }
                return _joinHome('.gradle/wrapper/dists');
              },
            ),
            _EntryDef(
              name: 'Android build cache',
              icon: Icons.android,
              iconAssetPath: 'assets/images/tool/android.png',
              pathResolver: () async => _joinHome('.android/build-cache'),
            ),
          ],
        ),
        _CategoryDef(
          id: 'csharp',
          icon: Icons.developer_board_outlined,
          language: ProjectLanguage.csharp,
          title: 'C#',
          entries: [
            _EntryDef(
              name: 'NuGet cache',
              envVar: 'NUGET_PACKAGES',
              pathResolver: () async => _joinHome('.nuget/packages'),
            ),
          ],
        ),
        _CategoryDef(
          id: 'cpp',
          icon: Icons.memory_outlined,
          language: ProjectLanguage.cpp,
          title: 'C++',
          entries: [
            _EntryDef(
              name: 'ccache',
              envVar: 'CCACHE_DIR',
              pathResolver: () async {
                if (Platform.isWindows) {
                  return _envJoin('LOCALAPPDATA', 'ccache');
                }
                return _joinHome('.cache/ccache');
              },
            ),
            _EntryDef(
              name: 'Conan cache',
              // Holds already-built packages — clearing it means every
              // dependency has to be rebuilt (or refetched, if a source
              // isn't still available) from scratch.
              safetyLevel: CleanerSafetyLevel.caution,
              safetyReason: 'Holds already-built packages — clearing it '
                  'means every dependency has to be rebuilt (or refetched) '
                  'from scratch.',
              pathResolver: () async {
                final conanHome = _env('CONAN_HOME');
                if (conanHome != null) return joinPath(conanHome, 'p');
                return _joinHome('.conan2/p');
              },
            ),
            _EntryDef(
              name: 'vcpkg cache',
              envVar: 'VCPKG_DEFAULT_BINARY_CACHE',
              pathResolver: () async {
                if (Platform.isWindows) {
                  return _envJoin('LOCALAPPDATA', 'vcpkg/archives');
                }
                return _joinHome('.cache/vcpkg');
              },
            ),
          ],
        ),
        _CategoryDef(
          id: 'go',
          icon: Icons.golf_course_outlined,
          language: ProjectLanguage.go,
          title: 'Go',
          entries: [
            _EntryDef(
              name: 'Go build cache',
              envVar: 'GOCACHE',
              pathResolver: () async {
                if (Platform.isMacOS) {
                  return _joinHome('Library/Caches/go-build');
                }
                if (Platform.isLinux) return _joinHome('.cache/go-build');
                if (Platform.isWindows) {
                  return _envJoin('LOCALAPPDATA', 'go-build');
                }
                return null;
              },
            ),
            _EntryDef(
              name: 'Go module cache',
              // Holds downloaded module sources — clearing it means every
              // dependency needs a network connection to fetch again.
              safetyLevel: CleanerSafetyLevel.caution,
              safetyReason: 'Holds downloaded module sources — clearing it '
                  'means every dependency needs a network connection to '
                  'fetch again.',
              envVar: 'GOMODCACHE',
              pathResolver: () async => _joinHome('go/pkg/mod/cache'),
            ),
          ],
        ),
        _CategoryDef(
          id: 'php',
          icon: Icons.php_outlined,
          language: ProjectLanguage.php,
          title: 'PHP',
          entries: [
            _EntryDef(
              name: 'Composer cache',
              envVar: 'COMPOSER_CACHE_DIR',
              pathResolver: () async {
                if (Platform.isMacOS) {
                  return _joinHome('Library/Caches/composer');
                }
                if (Platform.isLinux) return _joinHome('.cache/composer');
                if (Platform.isWindows) {
                  return _envJoin('LOCALAPPDATA', 'Composer');
                }
                return null;
              },
            ),
          ],
        ),
        _CategoryDef(
          id: 'rust',
          icon: Icons.settings_outlined,
          language: ProjectLanguage.rust,
          title: 'Rust',
          entries: [
            _EntryDef(
              name: 'Cargo registry cache',
              // Holds downloaded crate sources — clearing it means every
              // dependency needs a network connection to fetch again.
              safetyLevel: CleanerSafetyLevel.caution,
              safetyReason: 'Holds downloaded crate sources — clearing it '
                  'means every dependency needs a network connection to '
                  'fetch again.',
              pathResolver: () async {
                final cargoHome = _env('CARGO_HOME');
                if (cargoHome != null) return joinPath(cargoHome, 'registry');
                return _joinHome('.cargo/registry');
              },
            ),
            _EntryDef(
              name: 'Cargo target caches',
              envVar: 'SCCACHE_DIR',
              pathResolver: () async {
                if (Platform.isMacOS) {
                  return _joinHome('Library/Caches/Mozilla.sccache');
                }
                if (Platform.isLinux) return _joinHome('.cache/sccache');
                if (Platform.isWindows) {
                  return _envJoin('LOCALAPPDATA', 'Mozilla.sccache');
                }
                return null;
              },
            ),
          ],
        ),
        _CategoryDef(
          id: 'python',
          icon: Icons.code_outlined,
          language: ProjectLanguage.python,
          title: 'Python',
          entries: [
            _EntryDef(
              name: 'pip cache',
              envVar: 'PIP_CACHE_DIR',
              pathResolver: () async {
                if (Platform.isMacOS) return _joinHome('Library/Caches/pip');
                if (Platform.isLinux) return _joinHome('.cache/pip');
                if (Platform.isWindows) {
                  return _envJoin('LOCALAPPDATA', 'pip/Cache');
                }
                return null;
              },
            ),
            _EntryDef(
              name: 'pyenv build cache',
              pathResolver: () async {
                final pyenvRoot = _env('PYENV_ROOT');
                if (pyenvRoot != null) return joinPath(pyenvRoot, 'cache');
                if (Platform.isMacOS || Platform.isLinux) {
                  return _joinHome('.pyenv/cache');
                }
                return null;
              },
            ),
            _EntryDef(
              name: 'Conda package cache',
              // Holds downloaded package sources — clearing it means
              // every dependency needs a network connection to fetch
              // again.
              safetyLevel: CleanerSafetyLevel.caution,
              safetyReason: 'Holds downloaded package sources — clearing it '
                  'means every dependency needs a network connection to '
                  'fetch again.',
              pathResolver: () async => _joinHome('.conda/pkgs'),
            ),
          ],
        ),
        // No unifying language/tool icon at the category level (two
        // distinct engines, not one), so this one falls back to a plain
        // glyph the same way System does.
        _CategoryDef(
          id: 'game_engines',
          icon: Icons.videogame_asset_outlined,
          title: 'Game Engines Related',
          entries: [
            _EntryDef(
              name: 'Unreal Engine Derived Data Cache',
              iconAssetPath: Ide.unrealEngine.iconAsset,
              pathResolver: () async {
                if (Platform.isMacOS) {
                  return _joinHome(
                    'Library/Application Support/Epic/UnrealEngine/Common/DerivedDataCache',
                  );
                }
                if (Platform.isWindows) {
                  return _envJoin(
                    'LOCALAPPDATA',
                    'UnrealEngine/Common/DerivedDataCache',
                  );
                }
                if (Platform.isLinux) {
                  return _joinHome(
                      '.cache/UnrealEngine/Common/DerivedDataCache');
                }
                return null;
              },
            ),
            _EntryDef(
              name: 'Unity global cache',
              iconAssetPath: Ide.unity.iconAsset,
              pathResolver: () async {
                if (Platform.isMacOS) return _joinHome('Library/Unity/cache');
                if (Platform.isWindows) {
                  return _envJoin('LOCALAPPDATA', 'Unity/cache');
                }
                if (Platform.isLinux) return _joinHome('.cache/unity3d');
                return null;
              },
            ),
          ],
        ),
        _CategoryDef(
          id: 'docker',
          icon: Icons.widgets_outlined,
          iconAssetPath: 'assets/images/tool/docker.png',
          title: 'Docker Related',
          entries: [
            _EntryDef(
              name: 'Docker Desktop disk image',
              // Not a cache at all — the single VM disk backing every
              // container, image and volume Docker Desktop knows about.
              // Deleting it destroys all of them.
              safetyLevel: CleanerSafetyLevel.risky,
              defaultSelected: false,
              safetyReason: 'This is the single VM disk backing every '
                  'container, image and volume Docker Desktop knows about — '
                  'deleting it destroys all of them.',
              pathResolver: () async {
                if (Platform.isMacOS) {
                  return _joinHome(
                    'Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw',
                  );
                }
                if (Platform.isWindows) {
                  return _envJoin('LOCALAPPDATA', 'Docker/wsl/data/ext4.vhdx');
                }
                // Native Linux Docker Engine has no single VM disk image
                // the way Docker Desktop does — nothing to point at here.
                return null;
              },
            ),
            _EntryDef(
              name: 'Docker build cache',
              pathResolver: () async => _joinHome('.docker/buildx/cache'),
            ),
          ],
        ),
      ];
}

// Top-level (not an instance method of SystemCleanerRepo) — Isolate.run's
// own computation closure can only capture plain, sendable values (a path
// string), never `this`/a Box/anything else instance-held, which is why
// _isolatePathSize above hands this a bare String rather than calling an
// instance method directly.
Future<int> _computePathSize(String path) async {
  final type = await FileSystemEntity.type(path);
  switch (type) {
    case FileSystemEntityType.file:
      try {
        return await File(path).length();
      } on FileSystemException {
        return 0;
      }
    case FileSystemEntityType.directory:
      return _computeDirSize(Directory(path));
    default:
      return 0;
  }
}

// Same shape as ProjectSizeRepo's own _computeDirSize — sums real file
// bytes recursively, tolerating permission errors on individual files or
// the directory listing itself rather than losing the whole entry's size
// to one bad subdirectory.
Future<int> _computeDirSize(Directory dir) async {
  var size = 0;
  try {
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      try {
        size += await entity.length();
      } on FileSystemException {
        // Skip files we can't stat (broken symlinks, permission issues).
      }
    }
  } on FileSystemException {
    // dir.list()'s stream itself can throw mid-scan (e.g. a permission-
    // denied subdirectory) — return the partial total summed so far.
  }
  return size;
}

String? _joinHome(String relative) {
  final home = homeDir();
  return home == null ? null : joinPath(home, relative);
}

String? _env(String name) {
  final value = Platform.environment[name];
  return (value == null || value.isEmpty) ? null : value;
}

String? _envJoin(String envVarName, String subPath) {
  final base = _env(envVarName);
  return base == null ? null : joinPath(base, subPath);
}

/// One reclaimable-cache group's definition — mirrors [CleanerCategory]'s
/// own fields, minus [CleanerCategory.entries] (built from [entries]'
/// own resolved results instead of being fixed data).
class _CategoryDef {
  const _CategoryDef({
    required this.id,
    required this.icon,
    this.language,
    this.iconAssetPath,
    required this.title,
    required this.entries,
    this.pinned = false,
  });

  final String id;
  final IconData icon;
  final ProjectLanguage? language;
  final String? iconAssetPath;
  final String title;
  final List<_EntryDef> entries;
  final bool pinned;
}

/// One reclaimable cache's definition — everything [CleanerEntry] needs
/// except [CleanerEntry.path]/[CleanerEntry.sizeBytes]/
/// [CleanerEntry.extraPaths], which only exist once [pathResolver] (and
/// [extraPathResolvers]) has actually found something real on disk.
class _EntryDef {
  const _EntryDef({
    required this.name,
    required this.pathResolver,
    this.envVar,
    this.extraPathResolvers = const [],
    this.icon,
    this.iconAssetPath,
    this.defaultSelected = true,
    this.safetyLevel = CleanerSafetyLevel.safe,
    this.safetyReason,
  });

  final String name;

  /// Resolves this entry's own default path for the current OS — not
  /// necessarily existing yet; [SystemCleanerRepo._resolveEntry] checks
  /// that separately. Returning null means this entry doesn't apply to
  /// the current OS at all.
  final Future<String?> Function() pathResolver;

  /// When set and the named environment variable is non-empty, its value
  /// is used verbatim instead of [pathResolver] — most of these tools
  /// let a user relocate their cache this way (e.g. Cargo's own
  /// `CARGO_HOME`), and an overridden location is exactly as real as the
  /// default one.
  final String? envVar;

  final List<Future<String?> Function()> extraPathResolvers;
  final IconData? icon;
  final String? iconAssetPath;
  final bool defaultSelected;
  final CleanerSafetyLevel safetyLevel;
  final String? safetyReason;
}
