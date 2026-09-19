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
    'assets/images/ide/webstorm.png',
    {
      ProjectLanguage.javascript,
      ProjectLanguage.typescript,
    },
  ),
  pyCharm(
    'PyCharm',
    'assets/images/ide/pycharm.png',
    {ProjectLanguage.python},
  ),
  goLand(
    'GoLand',
    'assets/images/ide/goland.png',
    {ProjectLanguage.go},
  ),
  rustRover(
    'RustRover',
    'assets/images/ide/rustrover.webp',
    {ProjectLanguage.rust},
  ),
  phpStorm(
    'PhpStorm',
    'assets/images/ide/phpstorm.png',
    {ProjectLanguage.php},
  ),
  intellijIdea(
    'IntelliJ IDEA',
    'assets/images/ide/intellij-idea.png',
    {
      ProjectLanguage.java,
      ProjectLanguage.kotlin,
      // Same Dart/Flutter plugin Android Studio bundles works in plain
      // IntelliJ IDEA too — not a dedicated candidate in dartFlutter's own
      // group (Android Studio/VS Code stay the sensible defaults there),
      // but a real, working "Open With" option.
      ProjectLanguage.dart,
    },
  ),
  clion(
    'CLion',
    'assets/images/ide/clion.png',
    {ProjectLanguage.cpp},
  ),
  rider(
    'Rider',
    'assets/images/ide/rider.png',
    {ProjectLanguage.csharp},
  ),
  ;

  const Ide(this.label, this.iconAsset, this.supportedLanguages);

  final String label;
  final String iconAsset;
  final Set<ProjectLanguage> supportedLanguages;
}
