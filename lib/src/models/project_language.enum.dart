import 'ide.enum.dart';

/// A project's underlying programming language. Frameworks built on top of
/// a language (Flutter on Dart, React/Vue/Angular/Next.js on JS/TS, Xamarin
/// on C#, ...) are a separate, optional [ProjectFramework] — see
/// ProjectModel.framework — not a value here.
enum ProjectLanguage {
  dart('Dart', 'assets/images/lang/dart.webp'),
  java('Java', 'assets/images/lang/java.webp'),
  kotlin('Kotlin', 'assets/images/lang/kotlin.webp'),
  objectiveC('Objective-C', 'assets/images/lang/c.webp'),
  swift('Swift', 'assets/images/lang/swift.png'),
  cpp('C++', 'assets/images/lang/cpp.webp'),
  csharp('C#', 'assets/images/lang/c-sharp.webp'),
  javascript('JavaScript', 'assets/images/lang/javascript.webp'),
  typescript('TypeScript', 'assets/images/lang/typescript.png'),
  ;

  const ProjectLanguage(this.label, this.iconAsset);

  final String label;

  /// Null for languages without an icon asset yet — the UI falls back to a
  /// generic icon in that case.
  final String? iconAsset;

  /// Derived from PreferredIde.supportedLanguages, so the two enums stay in
  /// sync from one hand-maintained source of truth instead of two.
  Set<Ide> get supportedIdes => {
        for (final ide in Ide.values)
          if (ide.supportedLanguages.contains(this)) ide,
      };
}
