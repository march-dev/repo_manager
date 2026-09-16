import 'package:flutter/material.dart';

/// The shared "zebra-striped, hoverable, tappable" row chrome used by every
/// table-like row in the app (a plain table row, a tree row, ...) — a
/// zebra-tinted background, secondary-tap detection, and a Material+InkWell
/// for the primary tap/double-tap/hover, wrapping arbitrary row content
/// that [builder] rebuilds on every hover change.
class HoverableRow extends StatefulWidget {
  const HoverableRow({
    super.key,
    required this.height,
    required this.builder,
    this.zebra = false,
    this.onTap,
    this.onDoubleTap,
    this.onSecondaryTapUp,
  });

  final double height;
  final bool zebra;

  /// Builds this row's own content. [isHovered] reflects whether the
  /// pointer is currently over this row — e.g. for a cell that only shows
  /// extra content on hover.
  final Widget Function(BuildContext context, bool isHovered) builder;

  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  /// Given this row's own context (so a handler can look up its Overlay/
  /// Navigator, e.g. to show a context menu) and where the secondary click
  /// landed.
  final void Function(BuildContext context, Offset globalPosition)?
      onSecondaryTapUp;

  @override
  State<HoverableRow> createState() => _HoverableRowState();
}

class _HoverableRowState extends State<HoverableRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: widget.zebra
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
          : Colors.transparent,
      child: GestureDetector(
        onSecondaryTapUp: widget.onSecondaryTapUp == null
            ? null
            : (details) =>
                widget.onSecondaryTapUp!(context, details.globalPosition),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onDoubleTap: widget.onDoubleTap,
            onHover: (hovering) => setState(() => _hovering = hovering),
            child: SizedBox(
              height: widget.height,
              child: widget.builder(context, _hovering),
            ),
          ),
        ),
      ),
    );
  }
}
