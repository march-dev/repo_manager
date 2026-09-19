import '../utils/ide_host_availability.util.dart';
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
  go('Go', 'assets/images/lang/go.webp'),
  rust('Rust', 'assets/images/lang/rust-dark.webp'),
  php('PHP', 'assets/images/lang/php.png'),
  python('Python', 'assets/images/lang/python.webp'),
  ;

  const ProjectLanguage(this.label, this.iconAsset);

  final String label;

  /// Null for languages without an icon asset yet — the UI falls back to a
  /// generic icon in that case.
  final String? iconAsset;

  /// Derived from [Ide.supportedLanguages], so the two enums stay in sync
  /// from one hand-maintained source of truth instead of two — filtered to
  /// [isIdeAvailableOnHost] so e.g. a C++ project's "Open With" menu never
  /// offers Xcode on a Windows/Linux host, where it can't possibly exist.
  Set<Ide> get supportedIdes => {
        for (final ide in Ide.values)
          if (ide.supportedLanguages.contains(this) &&
              isIdeAvailableOnHost(ide))
            ide,
      };
}
