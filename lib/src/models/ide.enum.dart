import 'project_language.enum.dart';

enum Ide {
  vscode(
    'VS Code',
    'assets/images/ide/vscode.webp',
    {
      ProjectLanguage.dart,
      ProjectLanguage.java,
      ProjectLanguage.kotlin,
      ProjectLanguage.cpp,
      ProjectLanguage.csharp,
      ProjectLanguage.javascript,
      ProjectLanguage.typescript,
    },
  ),
  androidStudio(
    'Android Studio',
    'assets/images/ide/android-studio.webp',
    {
      ProjectLanguage.dart,
      ProjectLanguage.java,
      ProjectLanguage.kotlin,
    },
  ),
  xcode(
    'Xcode',
    'assets/images/ide/xcode.png',
    {
      ProjectLanguage.objectiveC,
      ProjectLanguage.swift,
      ProjectLanguage.cpp,
    },
  ),
  visualStudio(
    'Visual Studio',
    'assets/images/ide/visual-studio.png',
    {
      ProjectLanguage.cpp,
      ProjectLanguage.csharp,
    },
  ),
  ;

  const Ide(this.label, this.iconAsset, this.supportedLanguages);

  final String label;
  final String iconAsset;
  final Set<ProjectLanguage> supportedLanguages;
}
