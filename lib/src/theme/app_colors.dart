import 'package:flutter/material.dart';

/// The app's color palette — extracted from what used to be an inline
/// ColorScheme in app.dart, plus the two semantic colors most widgets were
/// each reaching for their own `Colors.amber`/`Colors.red` literal for.
/// Referencing these by name here (rather than the raw constant at every
/// call site) mirrors how ProjectSizeType already centralizes its own
/// core/cache colors.
abstract final class AppColors {
  // A cyan/teal accent reads more like a terminal or code-editor cursor
  // than the default iOS system blue, without colliding with the amber
  // (favourite), red (destructive), or indigo (ProjectSizeType.core)
  // already used elsewhere in the app.
  static const accent = Color(0xFF00BCD4);
  static const error = Color(0xFFFF453A);
  static const surface = Color(0xFF2C2C2E);
  static const onSurface = Color(0xFFF5F5F7);
  static const scaffoldBackground = Color(0xFF1E1E1E);

  /// One flat neutral used for every "faint structural" role at once —
  /// surfaceContainerHighest, outline, outlineVariant and the app's own
  /// Divider color were already all the same value before this was
  /// extracted, which reads as a deliberate choice for a monochrome dark
  /// theme rather than four coincidentally-identical literals.
  static const neutralContainer = Color(0xFF3A3A3C);

  /// A project pinned as a favourite — matches the star icon's fill color.
  static const favourite = Colors.amber;

  /// A destructive action, e.g. removing a configured directory.
  static const destructive = Colors.red;
}
