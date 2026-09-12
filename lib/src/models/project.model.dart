import 'project_language.enum.dart';

class ProjectModel {
  const ProjectModel({
    required this.name,
    required this.path,
    required this.iconPath,
    required this.sourceDir,
    required this.favourite,
    required this.language,
    required this.isXcodeProject,
  });

  final String name;
  final String path;
  final String iconPath;

  // The search directory (from Settings) this project was discovered under —
  // used to group projects in the Explorer's tree/tiles views.
  final String sourceDir;

  final bool favourite;
  final ProjectLanguage language;

  // Whether this project has its own .xcodeproj/.xcworkspace (or
  // Package.swift). Only meaningful for ProjectLanguage.cpp right now — see
  // ProjectRepo.resolveIde, which always opens such a project in Xcode
  // regardless of the C++ & C# group's configured preference, since no
  // other editor can build/run it the way Xcode can.
  final bool isXcodeProject;

  ProjectModel copyWith({bool? favourite}) {
    return ProjectModel(
      name: name,
      path: path,
      iconPath: iconPath,
      sourceDir: sourceDir,
      favourite: favourite ?? this.favourite,
      language: language,
      isXcodeProject: isXcodeProject,
    );
  }
}
