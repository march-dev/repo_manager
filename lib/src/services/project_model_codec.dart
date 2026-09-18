import '../../repo_manager.dart';

/// Hand-rolled (de)serialization for [ProjectModel]/[WorkspaceEntry] to
/// plain JSON-like Map/List data — used by ProjectScanner to cache a
/// monorepo's last-scanned member-package tree in Hive. No Hive adapters
/// here — everything else in this app's persistence goes through the same
/// hand-serialized-Map convention, so this follows it too rather than
/// introducing codegen just for this one model.
class ProjectModelCodec {
  const ProjectModelCodec();

  Map<String, dynamic> serializeWorkspaceEntry(WorkspaceEntry entry) {
    return switch (entry) {
      WorkspaceProjectEntry(:final project) => {
          'type': 'project',
          'project': serializeProjectModel(project),
        },
      WorkspaceFolderEntry(:final name, :final path, :final children) => {
          'type': 'folder',
          'name': name,
          'path': path,
          'children': [
            for (final child in children) serializeWorkspaceEntry(child),
          ],
        },
    };
  }

  WorkspaceEntry? deserializeWorkspaceEntry(Map data) {
    switch (data['type']) {
      case 'project':
        final project = deserializeProjectModel(data['project'] as Map?);
        return project == null ? null : WorkspaceProjectEntry(project);
      case 'folder':
        final name = data['name'];
        final path = data['path'];
        final rawChildren = data['children'];
        if (name is! String || path is! String || rawChildren is! List) {
          return null;
        }
        return WorkspaceFolderEntry(name, path, [
          for (final child in rawChildren)
            if (deserializeWorkspaceEntry(child as Map) case final c?) c,
        ]);
      default:
        return null;
    }
  }

  Map<String, dynamic> serializeProjectModel(ProjectModel project) {
    return {
      'name': project.name,
      'path': project.path,
      'iconPath': project.iconPath,
      'sourceDir': project.sourceDir,
      'favourite': project.favourite,
      'language': project.language.name,
      'framework': project.framework?.name,
      'isXcodeProject': project.isXcodeProject,
      'isAndroidProject': project.isAndroidProject,
      'monorepoTool': project.monorepoTool?.name,
      'subPackages': [
        for (final entry in project.subPackages) serializeWorkspaceEntry(entry),
      ],
      'subPackagesLoaded': project.subPackagesLoaded,
    };
  }

  ProjectModel? deserializeProjectModel(Map? data) {
    if (data == null) return null;

    final language =
        enumByName(ProjectLanguage.values, data['language'] as String?);
    final name = data['name'];
    final path = data['path'];
    final iconPath = data['iconPath'];
    final sourceDir = data['sourceDir'];
    final favourite = data['favourite'];
    final isXcodeProject = data['isXcodeProject'];
    final subPackagesLoaded = data['subPackagesLoaded'];
    final rawSubPackages = data['subPackages'];
    if (language == null ||
        name is! String ||
        path is! String ||
        iconPath is! String ||
        sourceDir is! String ||
        favourite is! bool ||
        isXcodeProject is! bool ||
        subPackagesLoaded is! bool ||
        rawSubPackages is! List) {
      return null;
    }

    return ProjectModel(
      name: name,
      path: path,
      iconPath: iconPath,
      sourceDir: sourceDir,
      favourite: favourite,
      language: language,
      framework:
          enumByName(ProjectFramework.values, data['framework'] as String?),
      isXcodeProject: isXcodeProject,
      // Optional, default false — a cache entry written before this field
      // existed just means "not known to be an Android project", same as
      // any other freshly-scanned non-Android java/kotlin project.
      isAndroidProject: (data['isAndroidProject'] as bool?) ?? false,
      monorepoTool:
          enumByName(MonorepoTool.values, data['monorepoTool'] as String?),
      subPackages: [
        for (final entry in rawSubPackages)
          if (deserializeWorkspaceEntry(entry as Map) case final e?) e,
      ],
      subPackagesLoaded: subPackagesLoaded,
    );
  }

  T? enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
