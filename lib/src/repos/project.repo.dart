import 'dart:io';

import '../../repo_manager.dart';

class ProjectRepo {
  const ProjectRepo._();
  static const instance = ProjectRepo._();
  factory ProjectRepo() => instance;

  static Future<void> init() async {
    final prefs = await LocalStorage.getInstance();
    _prefs = prefs!;
  }

  static late final LocalStorageInterface _prefs;

  static const _projectsDirPathKey = 'projectsDirPathKey';

  String getProjectsDirPath() {
    final cached = _prefs.getString(_projectsDirPathKey);
    return cached ?? '';
  }

  Future<void> setProjectsDirPath(String path) async {
    await _prefs.setString(_projectsDirPathKey, path);
  }

  Future<List<ProjectModel>> getProjects() async {
    final projectsDirPath = getProjectsDirPath();
    final projectsDir = Directory(projectsDirPath);

    if (!await projectsDir.exists()) {
      return [];
    }

    final projects = <ProjectModel>[];

    await for (final entity in projectsDir.list()) {
      if (entity is! Directory) continue;

      final pubspecFile = File('${entity.path}/pubspec.yaml');
      if (!await pubspecFile.exists()) continue;

      final iconFile = File(
        '${entity.path}/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
      );

      projects.add(
        ProjectModel(
          name: entity.path.split(Platform.pathSeparator).last,
          path: entity.path,
          iconPath: await iconFile.exists() ? iconFile.path : '',
        ),
      );
    }

    return projects;
  }

  static const _cleanableRelativePaths = [
    'build',
    '.dart_tool',
    'ios/Pods',
    'macos/Pods',
    'node_modules',
  ];

  String _totalSizeCacheKey(String projectPath) =>
      'projectTotalSize:$projectPath';

  String _cleanableSizeCacheKey(String projectPath) =>
      'projectCleanableSize:$projectPath';

  Future<ProjectSizeModel> getProjectSize(
    String projectPath, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedTotal = _prefs.getInt(_totalSizeCacheKey(projectPath));
      final cachedCleanable =
          _prefs.getInt(_cleanableSizeCacheKey(projectPath));
      if (cachedTotal != null && cachedCleanable != null) {
        return ProjectSizeModel(
            totalBytes: cachedTotal, cacheBytes: cachedCleanable);
      }
    }

    final total = await _dirSize(Directory(projectPath));
    final cleanable = await _calculateCleanableSize(projectPath);

    await _prefs.setInt(_totalSizeCacheKey(projectPath), total);
    await _prefs.setInt(_cleanableSizeCacheKey(projectPath), cleanable);

    return ProjectSizeModel(totalBytes: total, cacheBytes: cleanable);
  }

  Future<int> _calculateCleanableSize(String projectPath) async {
    var size = 0;
    for (final relativePath in _cleanableRelativePaths) {
      size += await _dirSize(Directory('$projectPath/$relativePath'));
    }
    return size;
  }

  Future<int> _dirSize(Directory dir) async {
    if (!await dir.exists()) return 0;

    var size = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
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

  Future<void> openInEditor(String projectPath) async {
    try {
      await Process.run('code', [projectPath]);
    } on ProcessException {
      // VS Code CLI ("code") isn't on PATH; nothing we can do.
    }
  }
}
