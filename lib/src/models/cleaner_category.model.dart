import 'package:flutter/widgets.dart';

import 'project_language.enum.dart';

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
  });

  final String name;
  final String path;
  final int sizeBytes;

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

  int get totalBytes => entries.fold(0, (sum, entry) => sum + entry.sizeBytes);
}
