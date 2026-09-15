import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// The app's single theme (dark-only — there's no light variant or user
/// toggle), built once here instead of inlined in app.dart, so its
/// palette/type scale can be reached the same way (via `Theme.of(context)`)
/// from any screen or widget rather than each one re-deriving its own ad
/// hoc TextStyle/Color literals.
abstract final class AppTheme {
  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent,
      error: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.neutralContainer,
      outline: AppColors.neutralContainer,
      outlineVariant: AppColors.neutralContainer,
    );

    return ThemeData(
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme(AppColors.onSurface),
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      dividerColor: AppColors.neutralContainer,
    );
  }
}
