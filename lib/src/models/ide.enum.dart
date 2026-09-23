import 'project_language.enum.dart';

enum Ide {
  vscode(
    'VS Code',
    'assets/images/ide/vscode.webp',
    {
      ProjectLanguage.dart,
      ProjectLanguage.java,
      ProjectLanguage.kotlin,
      ProjectLanguage.objectiveC,
      ProjectLanguage.swift,
      ProjectLanguage.cpp,
      ProjectLanguage.csharp,
      ProjectLanguage.javascript,
      ProjectLanguage.typescript,
      ProjectLanguage.go,
      ProjectLanguage.rust,
      ProjectLanguage.php,
      ProjectLanguage.python,
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
  // JetBrains lineup — no icon assets of their own yet, so each borrows
  // VS Code's for now as a placeholder; swap in real ones once added.
  webStorm(
    'WebStorm',
    'assets/images/ide/vscode.webp',
    {
      ProjectLanguage.javascript,
      ProjectLanguage.typescript,
    },
  ),
  pyCharm(
    'PyCharm',
    'assets/images/ide/vscode.webp',
    {ProjectLanguage.python},
  ),
  goLand(
    'GoLand',
    'assets/images/ide/vscode.webp',
    {ProjectLanguage.go},
  ),
  rustRover(
    'RustRover',
    'assets/images/ide/vscode.webp',
    {ProjectLanguage.rust},
  ),
  phpStorm(
    'PhpStorm',
    'assets/images/ide/vscode.webp',
    {ProjectLanguage.php},
  ),
  intellijIdea(
    'IntelliJ IDEA',
    'assets/images/ide/vscode.webp',
    {
      ProjectLanguage.java,
      ProjectLanguage.kotlin,
      // Same Dart/Flutter plugin Android Studio bundles works in plain
      // IntelliJ IDEA too — a real, working option, listed as a third
      // (less common) candidate in LanguageGroup.dartFlutter alongside
      // VS Code/Android Studio.
      ProjectLanguage.dart,
    },
  ),
  clion(
    'CLion',
    'assets/images/ide/vscode.webp',
    {ProjectLanguage.cpp},
  ),
  rider(
    'Rider',
    'assets/images/ide/vscode.webp',
    {ProjectLanguage.csharp},
  ),
  ;

  const Ide(this.label, this.iconAsset, this.supportedLanguages);

  final String label;
  final String iconAsset;
  final Set<ProjectLanguage> supportedLanguages;
}
