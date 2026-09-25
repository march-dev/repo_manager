import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:repo_manager/repo_manager.dart';

// Exercises system_cleaner.screen.dart's rendering against realistic
// category/entry data. SystemCleanerState's own scan doesn't produce
// anything yet (no real per-platform filesystem walk exists — see its own
// doc), so this seeds the live state directly with the same shape a real
// scan will eventually return, moved here once the screen's schematic UI
// had been reviewed against it.
List<CleanerCategory> _mockCategories() => [
      const CleanerCategory(
        id: 'system',
        icon: Icons.storage_outlined,
        title: 'System',
        pinned: true,
        entries: [
          CleanerEntry(
            name: 'User Caches',
            path: '~/Library/Caches',
            sizeBytes: 2400000000,
          ),
          CleanerEntry(
            name: 'Temporary Files',
            path: '/tmp',
            sizeBytes: 340000000,
          ),
        ],
      ),
      const CleanerCategory(
        id: 'npm',
        icon: Icons.javascript_outlined,
        language: ProjectLanguage.javascript,
        title: 'npm',
        entries: [
          CleanerEntry(
            name: 'npm cache',
            path: '~/.npm',
            sizeBytes: 1800000000,
          ),
          CleanerEntry(
            name: 'Yarn cache',
            path: '~/Library/Caches/Yarn',
            sizeBytes: 620000000,
          ),
          CleanerEntry(
            name: 'pnpm store',
            path: '~/Library/pnpm/store',
            sizeBytes: 2500000000,
          ),
        ],
      ),
      // Not const — ProjectFramework.flutter.iconAsset (on the "Flutter
      // engine cache" entry below) isn't a compile-time constant
      // expression, same reason the Xcode Related group below isn't.
      CleanerCategory(
        id: 'dart_flutter',
        icon: Icons.flutter_dash_outlined,
        language: ProjectLanguage.dart,
        title: 'Dart Related',
        entries: [
          const CleanerEntry(
            name: 'Pub cache',
            path: '~/.pub-cache',
            sizeBytes: 3100000000,
          ),
          CleanerEntry(
            name: 'Flutter engine cache',
            path: '~/flutter/bin/cache',
            sizeBytes: 4700000000,
            iconAssetPath: ProjectFramework.flutter.iconAsset,
          ),
        ],
      ),
      // Not const — Ide.xcode.iconAsset isn't a compile-time constant
      // expression (a plain field read off an enum instance), unlike
      // every other entry here which only reads ProjectLanguage's own
      // fields the same way.
      CleanerCategory(
        id: 'apple',
        icon: Icons.apple,
        iconAssetPath: Ide.xcode.iconAsset,
        title: 'Xcode Related',
        entries: [
          const CleanerEntry(
            name: 'Xcode DerivedData',
            path: '~/Library/Developer/Xcode/DerivedData',
            sizeBytes: 8900000000,
          ),
          const CleanerEntry(
            name: 'CocoaPods cache',
            path: '~/Library/Caches/CocoaPods',
            sizeBytes: 950000000,
          ),
          const CleanerEntry(
            name: 'Swift Package Manager cache',
            path: '~/Library/Caches/org.swift.swiftpm',
            sizeBytes: 680000000,
            extraPaths: ['~/Library/org.swift.swiftpm/security'],
          ),
          const CleanerEntry(
            name: 'iOS Simulator caches',
            path: '~/Library/Developer/CoreSimulator/Caches',
            sizeBytes: 1200000000,
          ),
          const CleanerEntry(
            name: 'Xcode Archives',
            path: '~/Library/Developer/Xcode/Archives',
            sizeBytes: 6000000000,
            // Not a cache — real release archives a user made on
            // purpose. Shown for visibility (they can be sizeable)
            // but never pre-checked; see CleanerEntry.defaultSelected.
            defaultSelected: false,
          ),
        ],
      ),
      const CleanerCategory(
        id: 'android',
        icon: Icons.android,
        language: ProjectLanguage.kotlin,
        title: 'Gradle Related',
        entries: [
          CleanerEntry(
            name: 'Gradle caches',
            path: '~/.gradle/caches',
            sizeBytes: 5200000000,
          ),
          CleanerEntry(
            name: 'Gradle wrapper distributions',
            path: '~/.gradle/wrapper/dists',
            sizeBytes: 1800000000,
          ),
          CleanerEntry(
            name: 'Android build cache',
            path: '~/.android/build-cache',
            sizeBytes: 780000000,
            icon: Icons.android,
          ),
        ],
      ),
      const CleanerCategory(
        id: 'csharp',
        icon: Icons.developer_board_outlined,
        language: ProjectLanguage.csharp,
        title: 'C#',
        entries: [
          CleanerEntry(
            name: 'NuGet cache',
            path: '~/.nuget/packages',
            sizeBytes: 1100000000,
          ),
        ],
      ),
      const CleanerCategory(
        id: 'cpp',
        icon: Icons.memory_outlined,
        language: ProjectLanguage.cpp,
        title: 'C++',
        entries: [
          CleanerEntry(
            name: 'ccache',
            path: '~/.cache/ccache',
            sizeBytes: 900000000,
          ),
          CleanerEntry(
            name: 'Conan cache',
            path: '~/.conan2/p',
            sizeBytes: 1400000000,
          ),
          CleanerEntry(
            name: 'vcpkg cache',
            path: '~/.cache/vcpkg',
            sizeBytes: 610000000,
          ),
        ],
      ),
      const CleanerCategory(
        id: 'go',
        icon: Icons.golf_course_outlined,
        language: ProjectLanguage.go,
        title: 'Go',
        entries: [
          CleanerEntry(
            name: 'Go build cache',
            path: '~/Library/Caches/go-build',
            sizeBytes: 890000000,
          ),
          CleanerEntry(
            name: 'Go module cache',
            path: '~/go/pkg/mod/cache',
            sizeBytes: 1500000000,
          ),
        ],
      ),
      const CleanerCategory(
        id: 'php',
        icon: Icons.php_outlined,
        language: ProjectLanguage.php,
        title: 'PHP',
        entries: [
          CleanerEntry(
            name: 'Composer cache',
            path: '~/.composer/cache',
            sizeBytes: 340000000,
          ),
        ],
      ),
      const CleanerCategory(
        id: 'rust',
        icon: Icons.settings_outlined,
        language: ProjectLanguage.rust,
        title: 'Rust',
        entries: [
          CleanerEntry(
            name: 'Cargo registry cache',
            path: '~/.cargo/registry',
            sizeBytes: 2200000000,
          ),
          CleanerEntry(
            name: 'Cargo target caches',
            path: '~/.cache/sccache',
            sizeBytes: 560000000,
          ),
        ],
      ),
      const CleanerCategory(
        id: 'python',
        icon: Icons.code_outlined,
        language: ProjectLanguage.python,
        title: 'Python',
        entries: [
          CleanerEntry(
            name: 'pip cache',
            path: '~/Library/Caches/pip',
            sizeBytes: 480000000,
          ),
          CleanerEntry(
            name: 'pyenv build cache',
            path: '~/.pyenv/cache',
            sizeBytes: 150000000,
          ),
          CleanerEntry(
            name: 'Conda package cache',
            path: '~/.conda/pkgs',
            sizeBytes: 3500000000,
          ),
        ],
      ),
      // Not const — Ide.unrealEngine.iconAsset/Ide.unity.iconAsset (on
      // the entries below) aren't compile-time constant expressions,
      // same reason the Xcode/Dart Related groups above aren't. No
      // unifying language/tool icon at the category level either (two
      // distinct engines, not one), so this one falls back to a plain
      // glyph the same way System does.
      CleanerCategory(
        id: 'game_engines',
        icon: Icons.videogame_asset_outlined,
        title: 'Game Engines Related',
        entries: [
          CleanerEntry(
            name: 'Unreal Engine Derived Data Cache',
            path:
                '~/Library/Application Support/Epic/UnrealEngine/Common/DerivedDataCache',
            sizeBytes: 15000000000,
            iconAssetPath: Ide.unrealEngine.iconAsset,
          ),
          CleanerEntry(
            name: 'Unity global cache',
            path: '~/Library/Unity/cache',
            sizeBytes: 2200000000,
            iconAssetPath: Ide.unity.iconAsset,
          ),
        ],
      ),
      // Language-agnostic like System — Docker isn't tied to any one
      // language/framework this app tracks, so there's no per-language
      // icon to reach for; falls back to a plain glyph the same way.
      const CleanerCategory(
        id: 'docker',
        icon: Icons.widgets_outlined,
        title: 'Docker Related',
        entries: [
          CleanerEntry(
            name: 'Docker Desktop disk image',
            path:
                '~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw',
            sizeBytes: 40000000000,
          ),
          CleanerEntry(
            name: 'Docker build cache',
            path: '~/.docker/buildx/cache',
            sizeBytes: 8000000000,
          ),
        ],
      ),
    ];

// A test-only SystemCleanerRepo standing in for the real one — its scan()
// resolves instantly with [result] rather than doing a genuine per-
// platform filesystem walk. The real repo's scan can legitimately take
// tens of seconds (it's summing real file bytes across real caches), and
// testWidgets' fake-async zone has no way to let that progress: it
// fast-forwards Timers/animations, but a real dart:io Future scheduled
// inside that zone never resolves within it, and runAsync() can't rescue
// a Future that was already kicked off in the wrong zone before it ran.
class _FakeSystemCleanerRepo extends SystemCleanerRepo {
  const _FakeSystemCleanerRepo(this.result, {required super.box});

  final List<CleanerCategory> result;

  // forceRefresh is ignored — this never touches the real per-path size
  // cache SystemCleanerRepo's own scan() reads/writes, so there's nothing
  // for the two calls SystemCleanerState now makes (forceRefresh: false,
  // then true — see its own doc) to actually differ on here.
  @override
  Future<List<CleanerCategory>> scan({bool forceRefresh = false}) async =>
      result;
}

SystemCleanerUseCases _fakeUseCases(Box box) {
  final found = _mockCategories().where((c) => c.entries.isNotEmpty).toList();
  return SystemCleanerUseCases(
    _FakeSystemCleanerRepo(found, box: box),
    lookupAppLocalizations(const Locale('en')),
  );
}

void main() {
  // SystemCleanerRepo now takes a Box (see its own doc for the per-path
  // size cache) — _FakeSystemCleanerRepo overrides scan() entirely and
  // never touches it, but still needs a real one to satisfy the
  // superclass constructor. Plain Hive (not Hive.initFlutter, which needs
  // a path_provider platform channel this test has none of) works fine
  // under `flutter test` — it's just local file I/O.
  late Directory tempDir;
  late Box cacheBox;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('system_cleaner_test');
    Hive.init(tempDir.path);
    cacheBox = await Hive.openBox('test_cache');
  });

  tearDownAll(() async {
    await cacheBox.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('renders every seeded category, largest-first after System',
      (tester) async {
    // Desktop-sized surface — the default 800x600 test surface overflows
    // this screen's header row, same as it would in a genuinely too-
    // narrow window.
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Provider<SystemCleanerState>(
          create: (_) => SystemCleanerState(useCases: _fakeUseCases(cacheBox)),
          child: const SystemCleanerScreen(selected: true),
        ),
      ),
    );
    // SystemCleanerState now runs two chained scans on construction (a
    // cache-first load, then a forced background refresh — see its own
    // doc), each needing a pump to resolve its Future plus another for
    // the resulting state change to propagate through to the widget tree.
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('System'), findsOneWidget);
    expect(find.text('Docker Related'), findsOneWidget);
    expect(find.text('Xcode Archives'), findsOneWidget);

    // System is pinned first regardless of size; Docker Related has the
    // largest total of everything else, so it should immediately follow.
    final titles = tester
        .widgetList<Text>(find.descendant(
          of: find.byType(SystemCleanerScreen),
          matching: find.byType(Text),
        ))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    final systemIndex = titles.indexOf('System');
    final dockerIndex = titles.indexOf('Docker Related');
    expect(systemIndex, lessThan(dockerIndex));
  });

  testWidgets('Xcode Archives is shown but not pre-selected', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Provider<SystemCleanerState>(
          create: (_) => SystemCleanerState(useCases: _fakeUseCases(cacheBox)),
          child: const SystemCleanerScreen(selected: true),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final state = Provider.of<SystemCleanerState>(
      tester.element(find.byType(AppScaffold)),
      listen: false,
    );

    final archivesEntry = state.categories
        .firstWhere((c) => c.id == 'apple')
        .entries
        .firstWhere((e) => e.name == 'Xcode Archives');
    expect(state.isEntrySelected(archivesEntry), isFalse);

    state.toggleEntry(archivesEntry);
    expect(state.isEntrySelected(archivesEntry), isTrue);
  });
}
