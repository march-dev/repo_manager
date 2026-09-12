import 'project_language.enum.dart';

class ProjectModel {
  const ProjectModel({
    required this.name,
    required this.path,
    required this.iconPath,
    required this.sourceDir,
    required this.favourite,
    required this.language,
  });

  final String name;
  final String path;
  final String iconPath;

  // The search directory (from Settings) this project was discovered under —
  // used to group projects in the Explorer's tree/tiles views.
  final String sourceDir;

  final bool favourite;
  final ProjectLanguage language;

  ProjectModel copyWith({bool? favourite}) {
    return ProjectModel(
      name: name,
      path: path,
      iconPath: iconPath,
      sourceDir: sourceDir,
      favourite: favourite ?? this.favourite,
      language: language,
    );
  }
}
