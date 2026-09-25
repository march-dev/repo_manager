import '../utils/ide_host_availability.util.dart';
import 'ide.enum.dart';
import 'project_language.enum.dart';

/// Groups languages that get a single, shared "preferred IDE" setting in
/// Settings (see settings.screen.dart's _PreferredEditorCard) — curated by
/// hand rather than derived from [Ide.supportedLanguages], since "this IDE
/// can technically open this language" (e.g. Xcode can edit plain C++) isn't
/// the same as "this IDE is a sensible default for this kind of project".
///
/// Every [ProjectLanguage] value has a group below — none fall back to
/// IdeLauncherRepo.resolveIde's own bare Ide.vscode default any more.
///
/// [requiresAndroid], when true, means this group only matches a java/
/// kotlin project that's actually an Android app (ProjectModel
/// .isAndroidProject) — [androidJavaKotlin] doesn't claim a backend/plain
/// JVM project sharing the same language. [forLanguage] checks that group
/// first, so [javaKotlin] (no such requirement) acts as the catch-all once
/// the more specific one has had a chance to claim the project instead.
///
/// A Unity/Unreal Engine project's own C#/C++ still resolves through the
/// plain [csharp]/[cpp] groups below like any other project of that
/// language — launching the actual game engine editor is a separate,
/// additional context-menu action (see PlatformTarget.unity/
/// PlatformTarget.unrealEngine), not a change to this preferred-IDE
/// default, the same way Flutter's own ios/android submenu doesn't change
/// what its "Open" defaults to either.
enum LanguageGroup {
  dartFlutter(
    'Dart & Flutter',
    {ProjectLanguage.dart},
    // IntelliJ IDEA runs the same Dart/Flutter plugin Android Studio
    // bundles (see Ide.intellijIdea's own supportedLanguages) — a real,
    // if less common, third option.
    [Ide.vscode, Ide.androidStudio, Ide.intellijIdea],
  ),
  androidJavaKotlin(
    // Named for the platform rather than the language pair (unlike
    // javaKotlin right below) — its own icon (see settings.screen.dart's
    // _iconAssetsFor) is what actually signals "this one's Java/Kotlin
    // specifically", so the label is free to just say what it's for.
    'Android',
    {ProjectLanguage.java, ProjectLanguage.kotlin},
    [Ide.androidStudio, Ide.intellijIdea, Ide.vscode],
    requiresAndroid: true,
  ),
  // Catches every java/kotlin project androidJavaKotlin doesn't claim —
  // backend/plain JVM work, where IntelliJ IDEA (not Android Studio,
  // which is really IntelliJ IDEA plus Android-specific tooling this kind
  // of project has no use for) is the natural default: 84% of Java
  // developers use it vs. VS Code's 31% (JetBrains State of Developer
  // Ecosystem 2025).
  javaKotlin(
    'Java & Kotlin',
    {ProjectLanguage.java, ProjectLanguage.kotlin},
    [Ide.intellijIdea, Ide.vscode],
  ),
  objectiveCSwift(
    'Objective-C & Swift',
    {ProjectLanguage.objectiveC, ProjectLanguage.swift},
    // Xcode only exists on macOS — candidatesOnHost/defaultIde fall
    // through to vscode on any other host.
    [Ide.xcode, Ide.vscode],
  ),
  // Split from a single combined C++ & C# group — CLion and Rider are
  // JetBrains' own separate C++ and .NET/C# IDEs respectively (Rider
  // doesn't edit plain C++, CLion doesn't edit C#), so a shared group
  // covering both languages couldn't offer either one as a sensible
  // default without also offering it for the other language it doesn't
  // actually support. No clear leader here either way — CLion, Visual
  // Studio, and VS Code hold roughly equal shares among C++ developers
  // overall (JetBrains State of Developer Ecosystem 2025) — so Windows
  // keeps its native Visual Studio as the tie-breaker; CLion covers
  // macOS/Linux, where Visual Studio can't run at all.
  cpp(
    'C++',
    {ProjectLanguage.cpp},
    [Ide.visualStudio, Ide.clion, Ide.vscode],
  ),
  csharp(
    'C#',
    {ProjectLanguage.csharp},
    // Visual Studio (the real Microsoft one) is Windows-only — Visual
    // Studio for Mac was discontinued, so Rider (the standard cross-
    // platform .NET JetBrains IDE) is next in line, ahead of vscode.
    // Near-tied overall (Rider 45% vs. Visual Studio 44% — JetBrains
    // State of .NET 2025), which — since that figure spans every
    // platform, including the ones where Visual Studio isn't even an
    // option — doesn't clearly say Windows-specific preference has
    // flipped; Visual Studio stays that platform's tie-breaking default.
    [Ide.visualStudio, Ide.rider, Ide.vscode],
  ),
  // VS Code dominates JS/TS specifically (~76% overall usage vs. WebStorm's
  // ~12% among JS/TS developers — JetBrains State of Developer Ecosystem
  // 2025), unlike every other JetBrains-vs-VS Code pairing below, where
  // the specialized IDE actually leads for its own language.
  jsTs(
    'JavaScript & TypeScript',
    {ProjectLanguage.javascript, ProjectLanguage.typescript},
    [Ide.vscode, Ide.webStorm],
  ),
  // PyCharm 49% vs. VS Code 42% among Python developers (JetBrains State
  // of Developer Ecosystem 2025) — a real, if narrow, lead.
  python(
    'Python',
    {ProjectLanguage.python},
    [Ide.pyCharm, Ide.vscode],
  ),
  // GoLand named "go-to IDE" by 47% of Go developers, the clear plurality
  // leader (JetBrains State of Developer Ecosystem 2025).
  go(
    'Go',
    {ProjectLanguage.go},
    [Ide.goLand, Ide.vscode],
  ),
  // VS Code leads Rust specifically by a wide margin (51.6% in the 2025
  // State of Rust survey, rust-lang.org) — RustRover (released 2023)
  // hasn't displaced it the way GoLand/PyCharm/PhpStorm have for their
  // own languages.
  rust(
    'Rust',
    {ProjectLanguage.rust},
    [Ide.vscode, Ide.rustRover],
  ),
  // PhpStorm + IntelliJ IDEA's PHP plugin combined: 68% of PHP developers,
  // vs. VS Code's 23% (JetBrains State of PHP 2025) — a decisive lead.
  php(
    'PHP',
    {ProjectLanguage.php},
    [Ide.phpStorm, Ide.vscode],
  ),
  ;

  const LanguageGroup(
    this.label,
    this.languages,
    this.candidateIdes, {
    this.requiresAndroid = false,
  });

  final String label;
  final Set<ProjectLanguage> languages;
  final bool requiresAndroid;

  /// Ordered by preference, most-preferred first — not itself filtered by
  /// what can actually run on this host, see [candidatesOnHost]/
  /// [defaultIde] for that. Every group ends in [Ide.vscode] as a
  /// universal fallback, so those two are never empty.
  final List<Ide> candidateIdes;

  /// [candidateIdes] filtered to [isIdeAvailableOnHost] — what Settings'
  /// picker actually offers, so a host never sees an IDE (Visual Studio
  /// outside Windows, Xcode outside macOS) it could never launch anyway.
  List<Ide> get candidatesOnHost =>
      candidateIdes.where(isIdeAvailableOnHost).toList();

  /// The most-preferred [candidateIdes] entry that's actually available on
  /// this host — e.g. C# defaults to Visual Studio on Windows (where it
  /// exists) but Rider on macOS/Linux (where it doesn't).
  Ide get defaultIde {
    final onHost = candidatesOnHost;
    return onHost.isNotEmpty ? onHost.first : candidateIdes.first;
  }

  /// [isAndroidProject] narrows the match to [androidJavaKotlin] when the
  /// project's actually an Android app; [javaKotlin] (no such requirement)
  /// is checked afterwards, as the catch-all for the same two languages.
  static LanguageGroup? forLanguage(
    ProjectLanguage language, {
    bool isAndroidProject = false,
  }) {
    for (final group in LanguageGroup.values) {
      if (!group.languages.contains(language)) continue;
      if (group.requiresAndroid && !isAndroidProject) continue;
      return group;
    }
    return null;
  }
}
