import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// Mirrors the look of a NavigationRailDestination (icon in a pill-shaped
/// selection indicator, label below) — used to hand-build the app's own
/// nav rail (see app.dart's `_RootScaffold`), since a real `NavigationRail`
/// has no way to interleave group titles between destinations or pin one
/// below a scrollable list of them, and reused as-is for a lone
/// rail-styled action elsewhere (e.g. project_details.screen.dart's own
/// back button, styled to match the "Other" rail page's own Back row).
class RailItem extends StatelessWidget {
  const RailItem({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Matches NavigationRail's own Material 3 defaults (_NavigationRailDefaultsM3)
    // exactly, since a real NavigationRailDestination isn't usable here.
    final iconColor = selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;
    final labelStyle = Theme.of(context)
        .textTheme
        .labelMedium!
        .copyWith(color: colorScheme.onSurface);

    return Material(
      type: MaterialType.transparency,
      child: _PillInkResponse(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSizes.radiusXLarge),
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                size: AppSizes.iconXLarge,
                color: iconColor,
              ),
            ),
            const SizedBox(height: AppSizes.spacing4),
            Text(label, style: labelStyle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// A real NavigationRailDestination's ink response covers its whole tap
// target (icon + label) but visually confines its splash/highlight to the
// 56x32 indicator pill up top — otherwise a tap near the label paints a
// ripple across the text. This mirrors that (see the framework's own
// `_IndicatorInkWell` in navigation_rail.dart) via a fixed-size rect
// centered at the top of whatever bounds this response ends up with.
class _PillInkResponse extends InkResponse {
  const _PillInkResponse({required super.onTap, required super.child})
      : super(
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        );

  static const _indicatorWidth = 56.0;
  static const _indicatorHeight = 32.0;

  @override
  RectCallback? getRectCallback(RenderBox referenceBox) {
    final width = referenceBox.size.width;
    return () => Rect.fromLTWH(
          width / 2 - _indicatorWidth / 2,
          0,
          _indicatorWidth,
          _indicatorHeight,
        );
  }
}
