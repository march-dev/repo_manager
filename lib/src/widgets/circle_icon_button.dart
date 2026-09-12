import 'package:flutter/material.dart';

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
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: const CircleBorder(),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        color: color,
        tooltip: tooltip,
        icon: icon,
      ),
    );
  }
}
