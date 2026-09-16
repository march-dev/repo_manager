import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// The basic single-line text input shared across the app — [SearchField]
/// and the New/Rename Collection dialog both build on this rather than
/// each wiring up their own styled [TextField], so every text field in
/// the app looks and behaves the same by construction.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.contentPadding,
  });

  final TextEditingController controller;
  final String hintText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// An inline action/icon at the field's start (e.g. [SearchField]'s
  /// search glyph) — sized via [prefixIconConstraints].
  final Widget? prefixIcon;
  final BoxConstraints? prefixIconConstraints;

  /// An inline action/icon at the field's end (e.g. [SearchField]'s clear
  /// button) — sized via [suffixIconConstraints].
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;

  final EdgeInsetsGeometry? contentPadding;

  // Filled with the scaffold background (rather than the theme's default
  // fill) so this sits flush with the page instead of reading as a
  // separate floating panel, with an explicit enabled/focused border —
  // otherwise focusing it pulls in the theme's default focused-border
  // color (typically a bright accent), which can read far louder than
  // whatever sits next to it. Focused is just a lightened step of the
  // same outline (not a different hue), so it reads as "this field is
  // active" without shouting.
  InputDecoration _decoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
          borderSide: BorderSide(color: color),
        );

    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      hintText: hintText,
      hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
      border: border(colorScheme.outline),
      enabledBorder: border(colorScheme.outline),
      focusedBorder: border(
        Color.lerp(colorScheme.outline, colorScheme.onSurface, 0.4)!,
      ),
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIconConstraints,
      suffixIcon: suffixIcon,
      suffixIconConstraints: suffixIconConstraints,
      contentPadding: contentPadding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: _decoration(context),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      // Otherwise a tap outside leaves the field focused, pulling in the
      // theme's default focused-border color until something else steals
      // focus instead.
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
    );
  }
}
