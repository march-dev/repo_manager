import 'package:flutter/material.dart';

/// The app's type scale — seven named styles covering every repeating text
/// pattern found across the app (a big bold stat number, an uppercase
/// muted group label, a small secondary caption, ...), mapped onto
/// Material's own [TextTheme] slots so `Theme.of(context).textTheme.x`
/// works everywhere instead of each widget hand-rolling its own
/// `TextStyle(fontSize: ..., fontWeight: ...)` literal.
///
/// Two slots ([titleMedium], [labelLarge]) are deliberately left untouched
/// by anything else in the app so they're safe to repurpose here without
/// disturbing an existing call site — notably [labelMedium] is NOT one of
/// them: _RailItem (app.dart) relies on its stock Material default to
/// match NavigationRail's own M3 look exactly, so it's left alone.
/// [labelLarge] being the *smallest* caption tier — rather than the
/// largest, as its Material name would suggest — is one deliberate
/// consequence of that: there's no natural Material slot for "smaller
/// than labelSmall", so this reuses labelLarge's name for it anyway
/// rather than inventing a non-standard TextTheme field.
///
/// Colors are baked in here (rather than left null for Theme to derive)
/// since [ThemeData] doesn't retroactively tint a caller-supplied
/// [TextTheme] from the [ColorScheme] the way its own generated default
/// one is — most call sites still override the color anyway (e.g.
/// onSurface at a lower alpha for "muted"), which a plain `copyWith` on
/// top of these handles fine.
abstract final class AppTypography {
  static TextTheme textTheme(Color onSurface) {
    return TextTheme(
      // Row/body text — project names, dialog body text, table cells, ...
      bodyMedium: TextStyle(fontSize: 13, color: onSurface),
      // Small secondary text — hints, badges.
      bodySmall: TextStyle(fontSize: 12, color: onSurface),
      // Emphasised text at the same size as bodyMedium — row/dialog
      // titles, a project's own name.
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      // Bold, letter-spaced section headers — a folder-path section's own
      // heading (explorer.screen.dart's _DirSectionHeader).
      titleMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: onSurface,
      ),
      // Big numeric stat values (Dashboard's summary cards).
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      // Small uppercase group/category labels — stat group titles, nav
      // rail group headers, a detail row's own label.
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: onSurface,
      ),
      // The smallest caption tier — an IDE's name under an "Open In" hint,
      // a monorepo badge's package count. See the class doc for why this
      // is labelLarge rather than something smaller-sounding.
      labelLarge: TextStyle(fontSize: 10, color: onSurface),
    );
  }
}
