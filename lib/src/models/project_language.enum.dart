import 'package:flutter/material.dart';

import '../utils/ide_host_availability.util.dart';
import 'ide.enum.dart';

/// A project's underlying programming language. Frameworks built on top of
/// a language (Flutter on Dart, React/Vue/Angular/Next.js on JS/TS, Xamarin
/// on C#, ...) are a separate, optional [ProjectFramework] — see
/// ProjectModel.framework — not a value here.
enum ProjectLanguage {
  dart('Dart', 'assets/images/lang/dart.webp', Color(0xFF00B4AB)),
  java('Java', 'assets/images/lang/java.webp', Color(0xFFB07219)),
  kotlin('Kotlin', 'assets/images/lang/kotlin.webp', Color(0xFFA97BFF)),
  objectiveC('Objective-C', 'assets/images/lang/c.webp', Color(0xFF438EFF)),
  swift('Swift', 'assets/images/lang/swift.png', Color(0xFFF05138)),
  cpp('C++', 'assets/images/lang/cpp.webp', Color(0xFFF34B7D)),
  csharp('C#', 'assets/images/lang/c-sharp.webp', Color(0xFF178600)),
  javascript(
      'JavaScript', 'assets/images/lang/javascript.webp', Color(0xFFF1E05A)),
  typescript(
      'TypeScript', 'assets/images/lang/typescript.png', Color(0xFF3178C6)),
  go('Go', 'assets/images/lang/go.webp', Color(0xFF00ADD8)),
  rust('Rust', 'assets/images/lang/rust-dark.webp', Color(0xFFDEA584)),
  php('PHP', 'assets/images/lang/php.png', Color(0xFF4F5D95)),
  python('Python', 'assets/images/lang/python.webp', Color(0xFF3572A5)),
  ;

  const ProjectLanguage(this.label, this.iconAsset, this.color);

  final String label;

  /// Null for languages without an icon asset yet — the UI falls back to a
  /// generic icon in that case.
  final String? iconAsset;

  /// The colour GitHub's own linguist language bar uses for this language
  /// — reused for [CompositionBar]'s own GitHub-style stacked bar/legend,
  /// so a project's language breakdown reads the same way a repo's
  /// language bar does on GitHub itself.
  final Color color;

  /// Derived from [Ide.supportedLanguages], so the two enums stay in sync
  /// from one hand-maintained source of truth instead of two — filtered to
  /// [isIdeAvailableOnHost] so e.g. a C++ project's "Open With" menu never
  /// offers Xcode on a Windows/Linux host, where it can't possibly exist.
  /// Game-engine editors (Ide.unity/Ide.unrealEngine) never show up here —
  /// they have no supportedLanguages entries at all, see their own doc.
  Set<Ide> get supportedIdes => {
        for (final ide in Ide.values)
          if (ide.supportedLanguages.contains(this) &&
              isIdeAvailableOnHost(ide))
            ide,
      };
}
