import 'package:flutter/material.dart';

import 'project_language.enum.dart';

/// How risky it is to delete a given [CleanerEntry] — shown as a small
/// coloured indicator next to each entry row (see system_cleaner.screen.
/// dart's own _SafetyIndicator) so a user can tell "purely regenerable
/// build/compiler output" apart from "downloaded package sources I'd need
/// network access to rebuild" apart from "this isn't really disposable
/// cache at all" at a glance, rather than having to know each tool's own
/// behaviour ahead of time.
enum CleanerSafetyLevel {
  /// Fully regenerable with no real downside — the tool recreates this
  /// from scratch, offline, the next time it runs (e.g. a pure
  /// compiler/build cache like ccache or Xcode's DerivedData).
  safe(Colors.green, Icons.check_circle_outline),

  /// Regenerable, but rebuilding it isn't free — e.g. it holds downloaded
  /// package sources that need a network connection to fetch again, or
  /// it's broad enough (the whole OS user-caches directory) that other,
  /// non-dev-tool apps' own caches get swept up in the same deletion.
  caution(Colors.orange, Icons.info_outline),

  /// Deleting this can break something until it's rebuilt/reinstalled,
  /// or it isn't disposable cache at all — e.g. pnpm's content-addressed
  /// store (other projects' node_modules symlink into it directly),
  /// Flutter's own engine cache (the SDK itself stops working until
  /// re-precached), or Xcode Archives (real release builds, not a
  /// cache).
  risky(Colors.red, Icons.warning_amber_outlined);

  const CleanerSafetyLevel(this.color, this.icon);

  final Color color;
  final IconData icon;
}

/// A single reclaimable path found on disk — e.g. one npm package's cache
/// entry, or Xcode's whole DerivedData folder. Schematic screens (see
/// system_cleaner.screen.dart) show these as mock data for now; a real
/// scan will produce the same shape from an actual filesystem walk.
class CleanerEntry {
  const CleanerEntry({
    required this.name,
    required this.path,
    required this.sizeBytes,
    this.extraPaths = const [],
    this.icon,
    this.iconAssetPath,
    this.defaultSelected = true,
    this.safetyLevel = CleanerSafetyLevel.safe,
    this.safetyReason,
  });

  final String name;
  final String path;

  /// Null while this entry's real size hasn't been computed yet — either
  /// this is the very first ever scan (nothing cached), or a refresh is
  /// currently recomputing it (see SystemCleanerState's own doc) — shown
  /// as a shimmer in place of the real number until then, rather than a
  /// misleading stale/zero value.
  final int? sizeBytes;

  /// Other paths cleaned together with [path] under this same entry but
  /// never shown on their own row — e.g. Swift Package Manager's small
  /// `security` state directory alongside its main cache. [sizeBytes]
  /// already accounts for these, so nothing here affects the totals; a
  /// real clean just needs to also delete each of these when [path] is
  /// removed.
  final List<String> extraPaths;

  /// Fallback glyph for an entry that has its own icon but no
  /// [iconAssetPath] (e.g. Android's build cache, which has no dedicated
  /// logo asset in this app — just the plain Android glyph). Null (the
  /// common case) means this entry shows no icon at all, not a generic
  /// one — most entries don't map to a single tool distinct from their
  /// own category's icon above them.
  final IconData? icon;

  /// A specific icon asset for this one entry, distinct from its
  /// category's own icon (e.g. Flutter's own logo on its engine-cache
  /// entry, under the Dart-language icon on the Dart Related group
  /// itself) — see CleanerCategory.iconAssetPath for the same idea one
  /// level up.
  final String? iconAssetPath;

  /// Whether a fresh scan pre-checks this entry's own checkbox. True for
  /// almost everything here — a regenerable cache is safe to select by
  /// default. False for an entry that isn't really a cache at all, just
  /// shown for visibility (e.g. Xcode Archives — real release builds a
  /// user made on purpose, not something to select for deletion without
  /// them noticing and opting in).
  final bool defaultSelected;

  /// How risky it is to delete this entry — see [CleanerSafetyLevel]'s
  /// own doc. Defaults to [CleanerSafetyLevel.safe], the common case for
  /// a plain regenerable cache.
  final CleanerSafetyLevel safetyLevel;

  /// This entry's own specific reason for its [safetyLevel] (e.g. "other
  /// projects' node_modules symlink into this store"), shown under a
  /// divider below the general per-level explanation in the safety
  /// popover — see system_cleaner.screen.dart's own _SafetyIndicator.
  /// Null for the common case where the general explanation alone
  /// already covers it (most [CleanerSafetyLevel.safe] entries). Plain,
  /// un-localized English, the same as [name]/[path] above — technical
  /// documentation describing a specific tool's own behaviour, not
  /// app-chrome text.
  final String? safetyReason;
}

/// One reclaimable-cache group (e.g. "Dart Related") and the entries
/// found under it — a group is only ever shown at all once it has at
/// least one entry (see SystemCleanerState's own doc).
class CleanerCategory {
  const CleanerCategory({
    required this.id,
    required this.icon,
    this.language,
    this.iconAssetPath,
    required this.title,
    required this.entries,
    this.pinned = false,
  });

  final String id;

  /// Fallback glyph for a group with no matching [ProjectLanguage]/
  /// [iconAssetPath] (e.g. System Cache), or a language whose own
  /// [ProjectLanguage.iconAsset] is null — see AssetOrFallbackIcon's own
  /// doc.
  final IconData icon;

  /// The project language this group's icon should mirror (e.g. Dart for
  /// the Dart/Flutter group) — reusing the same icon shown throughout the
  /// rest of the app for that language, rather than a separate generic
  /// glyph, so a category reads as "this is the same Dart you see
  /// elsewhere", not an unrelated icon. Ignored when [iconAssetPath] is
  /// given instead — a group isn't both at once.
  final ProjectLanguage? language;

  /// A specific icon asset to use directly (e.g. [Ide.xcode]'s own icon
  /// for the Xcode Related group) — for a group whose identity is a tool
  /// rather than a single [ProjectLanguage]. Takes priority over
  /// [language] when both are somehow given.
  final String? iconAssetPath;

  final String title;
  final List<CleanerEntry> entries;

  /// Always sorted first, ahead of every other group — regardless of its
  /// own [totalBytes] — e.g. the catch-all System group, which reads as
  /// a fixed anchor rather than another group competing with the rest by
  /// size. See SystemCleanerState.sortedCategories.
  final bool pinned;

  int get totalBytes =>
      entries.fold(0, (sum, entry) => sum + (entry.sizeBytes ?? 0));

  /// Whether every entry's own size is currently known — false while a
  /// scan/refresh still has at least one entry's size left to compute
  /// (see SystemCleanerState's own doc), which is when [totalBytes] above
  /// is showing a partial, still-growing figure rather than the real
  /// total, and _CategoryHeaderRow shows a shimmer in its place instead.
  bool get hasKnownTotal => entries.every((entry) => entry.sizeBytes != null);
}
