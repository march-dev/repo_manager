import 'package:flutter/material.dart';

/// A single-select [SegmentedButton] preset for this app's own toggles
/// (explorer's grouping switch, settings' per-language IDE picker): hides
/// the built-in selected-checkmark icon and paints unselected segments in
/// the scaffold background instead of Material's default surface tint, so
/// the selected segment reads as the only thing that stands out rather
/// than floating a separate panel over the header card behind it.
class AppSegmentedButton<T> extends StatelessWidget {
  const AppSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SegmentedButton<T>(
      showSelectedIcon: false,
      segments: segments,
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        // SegmentedButton.styleFrom's plain `backgroundColor`/
        // `foregroundColor` only ever apply to the WidgetState.any
        // fallback — passing just those leaves WidgetState.selected
        // mapped to null (see the framework's `_defaultColor` helper),
        // so a selected segment falls back to whatever's painted behind
        // it instead of an explicit color. That's invisible whenever
        // the surrounding card happens to share the scaffold background,
        // which is most of the time — most noticeable on the icon-only
        // (label-less) segments this button collapses to at narrow
        // widths, since there's no label-color shift left to notice
        // selection by either. Pinning selectedBackgroundColor
        // explicitly (matching the "selected" pill treatment used for
        // nav rail items elsewhere — see app.dart's _RailItem) keeps
        // the selected segment visibly distinct regardless of card
        // background or label presence.
        selectedBackgroundColor: colorScheme.secondaryContainer,
        selectedForegroundColor: colorScheme.onSecondaryContainer,
        // Without this, segment labels fall back to the theme's own
        // labelLarge — repurposed app-wide (see AppTypography) as a tiny
        // 10px caption style, not a button label — reading far smaller
        // than every other button in the app. titleSmall matches
        // SplitButton's own label style, so every button-like control
        // reads at the same size/weight.
        textStyle: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
