import 'ide.enum.dart';
import 'project_language.enum.dart';

/// Groups languages that get a single, shared "preferred IDE" setting in
/// Settings (see settings.screen.dart's _PreferredEditorCard) — curated by
/// hand rather than derived from [Ide.supportedLanguages], since "this IDE
/// can technically open this language" (e.g. Xcode can edit plain C++) isn't
/// the same as "this IDE is a sensible default for this kind of project".
///
/// Languages not covered by any group here (JS, TS, Vue, React) don't have
/// a dedicated preferred-IDE setting yet, and fall back to VS Code (see
/// ProjectRepo.resolveIde).
enum LanguageGroup {
  dartFlutter(
    'Dart & Flutter',
    {ProjectLanguage.dart, ProjectLanguage.flutter},
    {Ide.vscode, Ide.androidStudio},
    Ide.vscode,
  ),
  javaKotlin(
    'Java & Kotlin',
    {ProjectLanguage.java, ProjectLanguage.kotlin},
    {Ide.androidStudio, Ide.vscode},
    Ide.androidStudio,
  ),
  objectiveCSwift(
    'Objective-C & Swift',
    {ProjectLanguage.objectiveC, ProjectLanguage.swift},
    {Ide.xcode, Ide.vscode},
    Ide.xcode,
  ),
  cppCsharp(
    'C++ & C#',
    {ProjectLanguage.cpp, ProjectLanguage.csharp},
    {Ide.visualStudio, Ide.vscode},
    Ide.visualStudio,
  ),
  ;

  const LanguageGroup(
    this.label,
    this.languages,
    this.candidateIdes,
    this.defaultIde,
  );

  final String label;
  final Set<ProjectLanguage> languages;
  final Set<Ide> candidateIdes;
  final Ide defaultIde;

  static LanguageGroup? forLanguage(ProjectLanguage language) {
    for (final group in LanguageGroup.values) {
      if (group.languages.contains(language)) return group;
    }
    return null;
  }
}
