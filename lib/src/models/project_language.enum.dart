import 'ide.enum.dart';

// Detection is currently only wired up for `flutter`/`dart` (the only kinds
// of project ProjectRepo can discover, via a pubspec.yaml marker file) — the
// rest of the enum exists so the model/UI don't need to change again once
// detection for other project types is added.
enum ProjectLanguage {
  flutter('Flutter', 'assets/images/lang/flutter.webp'),
  dart('Dart', 'assets/images/lang/dart.webp'),
  java('Java', 'assets/images/lang/java.webp'),
  kotlin('Kotlin', 'assets/images/lang/kotlin.webp'),
  objectiveC('Objective-C', 'assets/images/lang/c.webp'),
  swift('Swift', 'assets/images/lang/swift.png'),
  cpp('C++', 'assets/images/lang/cpp.webp'),
  csharp('C#', 'assets/images/lang/c-sharp.webp'),
  javascript('JavaScript', 'assets/images/lang/javascript.webp'),
  typescript('TypeScript', 'assets/images/lang/typescript.png'),
  vueJs('Vue.js', 'assets/images/lang/vue-js.webp'),
  reactJs('React', 'assets/images/lang/react-js.webp'),
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
