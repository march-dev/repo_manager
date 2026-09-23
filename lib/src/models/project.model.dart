import 'monorepo_tool.enum.dart';
import 'project_framework.enum.dart';
import 'project_language.enum.dart';
import 'workspace_entry.model.dart';

class ProjectModel {
  const ProjectModel({
    required this.name,
    required this.path,
    required this.iconPath,
    required this.sourceDir,
    required this.favourite,
    required this.language,
    this.framework,
    this.isXcodeProject = false,
    this.isAndroidProject = false,
    this.monorepoTool,
    this.subPackages = const [],
    this.subPackagesLoaded = true,
  });

  final String name;
  final String path;
  final String iconPath;

  // The search directory (from Settings) this project was discovered under —
  // used to group projects in the Explorer's tree/tiles views.
  final String sourceDir;

  final bool favourite;
  final ProjectLanguage language;

  // A framework built on top of language (Flutter on Dart, React on
  // JS/TS, ...), if one was detected. Null just means "no recognized
  // framework" — the project is still valid, e.g. a plain Dart package.
  final ProjectFramework? framework;

  // Whether this project has its own .xcodeproj/.xcworkspace (or
  // Package.swift). Only meaningful for ProjectLanguage.cpp right now — see
  // IdeLauncherRepo.resolveIde, which always opens such a project in Xcode
  // regardless of the C++ group's configured preference, since no other
  // editor can build/run it the way Xcode can.
  final bool isXcodeProject;

  // A plain (non-Flutter) Java/Kotlin project with its own Android app
  // module — see ProjectLanguageDetector's own AndroidManifest.xml check.
  // A platform/OS target, the same category as isXcodeProject, not a
  // ProjectFramework — Android isn't a framework layered on Java/Kotlin
  // the way Flutter/React are, it's what the whole project targets. See
  // LanguageGroup.androidJavaKotlin, which uses this to offer a separate
  // preferred-IDE default from plain backend/JVM java/kotlin work.
  final bool isAndroidProject;

  // The workspace tool that manages this project's member packages, if any
  // was detected (melos.yaml, nx.json, turbo.json, lerna.json). Null for a
  // plain, non-monorepo project — subPackages is then always empty too.
  final MonorepoTool? monorepoTool;

  // This monorepo's member tree, detected via [monorepoTool]'s own
  // workspace config — a mix of real projects (each a fully-formed
  // ProjectModel in its own right, own language/framework/icon) and plain
  // container folders found along the way that aren't projects
  // themselves, kept as their own nodes so the tree reflects where
  // packages actually live rather than flattening them away. Always empty
  // for a non-monorepo project.
  final List<WorkspaceEntry> subPackages;

  // Whether [subPackages] reflects a real scan or just hasn't been fetched
  // yet. Building a monorepo's full member tree (recursive scan,
  // sibling-scan, path-dependency traversal, a real icon lookup per
  // package) is real filesystem work — too slow to do for every monorepo
  // on every app-launch project listing — so ProjectScanner.getProjects()
  // leaves this false and subPackages empty for a freshly-detected
  // monorepo, and ProjectScanner.loadSubPackages fills both in afterwards,
  // in the background. Always true for a non-monorepo project (there's
  // nothing to load) and for one already fully loaded.
  final bool subPackagesLoaded;

  ProjectModel copyWith({
    bool? favourite,
    List<WorkspaceEntry>? subPackages,
    bool? subPackagesLoaded,
  }) {
    return ProjectModel(
      name: name,
      path: path,
      iconPath: iconPath,
      sourceDir: sourceDir,
      favourite: favourite ?? this.favourite,
      language: language,
      framework: framework,
      isXcodeProject: isXcodeProject,
      isAndroidProject: isAndroidProject,
      monorepoTool: monorepoTool,
      subPackages: subPackages ?? this.subPackages,
      subPackagesLoaded: subPackagesLoaded ?? this.subPackagesLoaded,
    );
  }
}
