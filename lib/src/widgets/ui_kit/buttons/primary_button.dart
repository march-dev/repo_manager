import 'package:flutter/material.dart';

import '../indicators/loading_spinner.dart';

/// A filled icon+label button whose icon swaps to a [LoadingSpinner] while
/// [loading] — e.g. a "Clean All" action that takes a moment to complete.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    this.foregroundColor,
    this.loading = false,
    this.disabled = false,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;
  final Color backgroundColor;
  final Color? foregroundColor;

  /// Swaps [icon] for a spinner and disables the button, for an action
  /// currently in flight.
  final bool loading;

  /// Disables the button for any other reason (independent of [loading]).
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: (loading || disabled) ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
        disabledForegroundColor: foregroundColor?.withValues(alpha: 0.6),
        // Without this, the label falls back to the theme's own
        // labelLarge — repurposed app-wide (see AppTypography) as a tiny
        // 10px caption style, not a button label — reading far smaller
        // than every other button in the app. titleSmall matches
        // SplitButton's own label style, so every button-like control
        // reads at the same size/weight.
        textStyle: Theme.of(context).textTheme.titleSmall,
      ),
      icon: loading ? const LoadingSpinner() : icon,
      label: label,
    );
  }
}
