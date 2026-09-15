import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// The rounded, bordered, tinted card shell shared by this app's top-level
/// containers (see [HeaderCard]) — a themed background/border around
/// arbitrary content.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.all(AppSizes.spacing16),
    this.borderRadius = AppSizes.radiusLarge,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  /// Set to [Clip.antiAlias] when [child] itself paints a background/ink
  /// that would otherwise poke past this card's rounded corners (e.g. a
  /// `Material` filling the card edge-to-edge).
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: margin,
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: AppSizes.borderWidth,
        ),
      ),
      child: child,
    );
  }
}
