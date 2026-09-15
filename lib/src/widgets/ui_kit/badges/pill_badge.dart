import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// A rounded, filled pill wrapping arbitrary label content (text, an icon
/// row, ...) — the shared shape behind any "small tag next to something"
/// badge in the app. [onTap], when given, makes the whole pill tappable.
///
/// The background lives on this [Material] (rather than a separately
/// decorated [Container]) so an [onTap] ink response paints here too — on
/// top of the background, under [child], clipped to the same rounded shape.
/// A [Container] decoration on the [InkWell]'s child would otherwise sit
/// *above* the ink splash (which paints on the nearest ancestor [Material],
/// further down in the tree than one might expect) and hide it — visible,
/// if at all, only through the decoration's own rounded corners'
/// rectangular cutout, i.e. exactly at the pill's corners rather than
/// across its face.
class PillBadge extends StatelessWidget {
  const PillBadge({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.borderRadius =
        const BorderRadius.all(Radius.circular(AppSizes.radiusSmall)),
    this.padding =
        const EdgeInsets.symmetric(horizontal: AppSizes.spacing6, vertical: 1),
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Defaults to the theme's [ColorScheme.surfaceContainerHighest].
  final Color? color;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    return Material(
      color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
