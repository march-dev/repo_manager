import 'package:flutter/material.dart';

import '../indicators/loading_spinner.dart';

/// A circular icon button with its own filled background — the shape shared
/// by storage.screen.dart's cleanup button and explorer.screen.dart's
/// favourite button (the latter with a transparent background, so it reads
/// as a plain icon while still being the same underlying component).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    this.color,
    this.tooltip,
    this.size,
  }) : loading = false;

  /// Swaps [icon] for a [LoadingSpinner] (and stops responding to taps)
  /// while [loading] — e.g. a per-row cleanup action that takes a moment
  /// to complete. Disable the button for any other reason the normal way,
  /// by passing `null` for [onPressed].
  const CircleIconButton.loading({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.loading,
    this.color,
    this.tooltip,
    this.size,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color? color;
  final String? tooltip;
  final bool loading;

  /// Pins this button to a fixed square tap target rather than letting it
  /// shrink to [icon]'s own bounds (this button's zero padding otherwise
  /// leaves it exactly icon-sized) — set this when the button sits in a
  /// layout that assumes a specific reserved width (e.g. a table's own
  /// fixed action column), so every caller doing that no longer has to
  /// wrap this in its own matching `SizedBox`.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final button = IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: const CircleBorder(),
          // Matches _CleanAllButton's disabled look: fade this button's own
          // colors rather than falling back to Material's generic grey
          // disabled style, so a disabled icon button still reads as "this
          // action, temporarily unavailable" instead of a different button.
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
          disabledForegroundColor: color?.withValues(alpha: 0.6),
        ),
      ),
      child: IconButton(
        onPressed: loading ? null : onPressed,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        color: color,
        tooltip: tooltip,
        icon: loading ? LoadingSpinner(color: color) : icon,
      ),
    );

    final size = this.size;
    return size == null
        ? button
        : SizedBox(width: size, height: size, child: button);
  }
}
