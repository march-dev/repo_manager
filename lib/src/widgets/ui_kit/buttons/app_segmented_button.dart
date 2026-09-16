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
    return SegmentedButton<T>(
      showSelectedIcon: false,
      segments: segments,
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: SegmentedButton.styleFrom(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
