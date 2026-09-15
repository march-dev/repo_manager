import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../../../utils/byte.util.dart';
import '../badges/color_dot.dart';

/// A "<label>: <formatted bytes>" legend entry, optionally preceded by a
/// [ColorDot] matching a [SizeBar] segment's color.
class SizeSummary extends StatelessWidget {
  const SizeSummary({
    super.key,
    required this.label,
    required this.bytes,
    this.color,
  });

  final String label;
  final int bytes;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (color != null) ...[
          ColorDot(color: color!),
          const SizedBox(width: 6),
        ],
        Text('$label: ${formatBytes(bytes)}'),
      ],
    );
  }
}

/// A rounded, framed bar visualizing the proportion of [leftValue] vs
/// [rightValue] out of [totalValue] (inspired by macOS's storage usage
/// bar).
///
/// The two segments render as independently-rounded pills, colored
/// [leftColor]/[rightColor] and separated by a small gap, rather than one
/// continuously-filled bar. A segment too thin to read as a pill renders as
/// a dot instead, and a segment with zero value isn't painted at all —
/// animating in from nothing (rather than popping in at full size) if it
/// later gains value. With no data at all yet (and nothing else indicating
/// a loading state), the bar fills fully with [leftColor] as a neutral
/// placeholder rather than sitting empty.
class SizeBar extends StatelessWidget {
  const SizeBar({
    super.key,
    required this.leftValue,
    required this.rightValue,
    required this.totalValue,
    required this.leftColor,
    required this.rightColor,
    this.height = 12,
    this.width,
    this.animationDuration = const Duration(milliseconds: 350),
    this.previousLeftValue,
    this.previousRightValue,
    this.previousTotalValue,
  });

  final int leftValue;
  final int rightValue;
  final int totalValue;
  final Color leftColor;
  final Color rightColor;

  /// Thickness of the colored segments themselves, excluding [framePadding].
  final double height;

  /// Overall bar width. Fills the available width when null.
  final double? width;
  final Duration animationDuration;

  /// What was last actually displayed for this same data, if anything —
  /// pass these when the *widget* can be recreated from scratch (e.g. a
  /// list item discarded and rebuilt when its list position changes)
  /// even though the *data* it represents may not be new. All three null
  /// means "never shown before", so the bar grows in from nothing; when
  /// provided, the very first frame renders as if these were still the
  /// current values, then animates to the real ones — continuing the
  /// transition visually instead of either replaying the entrance
  /// animation or popping in unanimated.
  final int? previousLeftValue;
  final int? previousRightValue;
  final int? previousTotalValue;

  /// Gap between the background frame and the segments, so the frame reads
  /// as a visible border around the bar rather than being fully covered.
  static const framePadding = AppSizes.spacing2;

  // Gap between the two segments — public so callers can work out the
  // smallest width that still fits two full (unsquished) dots.
  static const gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final outerHeight = height + framePadding * 2;

    return Container(
      width: width ?? double.infinity,
      height: outerHeight,
      padding: const EdgeInsets.all(framePadding),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(outerHeight / 2),
      ),
      child: _buildSegments(),
    );
  }

  Widget _buildSegments() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final current = _layoutFor(barWidth, leftValue, rightValue, totalValue);

        _SegmentLayout? previous;
        if (previousLeftValue != null &&
            previousRightValue != null &&
            previousTotalValue != null) {
          previous = _layoutFor(
            barWidth,
            previousLeftValue!,
            previousRightValue!,
            previousTotalValue!,
          );
        }

        return _AnimatedSegments(
          current: current,
          previous: previous,
          height: height,
          leftColor: leftColor,
          rightColor: rightColor,
          duration: animationDuration,
        );
      },
    );
  }

  _SegmentLayout _layoutFor(
    double barWidth,
    int leftValue,
    int rightValue,
    int totalValue,
  ) {
    if (totalValue <= 0) {
      // No data at all yet: fill with the left color as a neutral
      // placeholder, using the same layout pipeline real data does —
      // rather than a separate widget — so the eventual transition to
      // real data is one continuous animation instead of a hard swap.
      return _SegmentLayout(leftWidth: barWidth, rightWidth: 0);
    }

    final hasLeft = leftValue > 0;
    final hasRight = rightValue > 0;
    final hasGap = hasLeft && hasRight;
    final usableWidth = hasGap ? barWidth - gap : barWidth;

    var leftWidth = hasLeft ? usableWidth * leftValue / totalValue : 0.0;
    var rightWidth = hasRight ? usableWidth * rightValue / totalValue : 0.0;

    // A segment too thin to read as a pill is drawn as a dot instead;
    // whatever width it would have used is handed to the other segment.
    // (The dot's shape itself — a circle rather than a squished pill — is
    // handled purely by width in _AnimatedSegments; this is only about
    // deciding how much width each segment's *target* gets.)
    final leftIsDot = hasLeft && leftWidth < height;
    final rightIsDot = hasRight && rightWidth < height;

    if (leftIsDot) leftWidth = height;
    if (rightIsDot) rightWidth = height;

    if (leftIsDot && !rightIsDot && hasRight) {
      rightWidth = usableWidth - leftWidth;
    } else if (rightIsDot && !leftIsDot && hasLeft) {
      leftWidth = usableWidth - rightWidth;
    }

    return _SegmentLayout(leftWidth: leftWidth, rightWidth: rightWidth);
  }
}

/// The resolved pixel widths for one [SizeBar] state (a given value split
/// at a given bar width).
class _SegmentLayout {
  const _SegmentLayout({required this.leftWidth, required this.rightWidth});

  static const zero = _SegmentLayout(leftWidth: 0, rightWidth: 0);

  final double leftWidth;
  final double rightWidth;
}

/// Renders the two segments, animating any change to their widths or
/// heights (a segment appearing/disappearing, or the split between two
/// already-present segments shifting).
///
/// The left segment is anchored to the bar's left edge and the right one to
/// its right edge (via a [Stack], not a [Row]), so each one visibly
/// grows/shrinks from its own fixed edge — the right segment always
/// animates in from the right, regardless of whatever the left's current
/// width happens to be, rather than appearing to grow outward from
/// wherever the left's trailing edge currently sits. This also means the
/// two segments can never overflow their shared bar: unlike a `Row`, a
/// `Stack` doesn't require its children's sizes to sum to the available
/// width, so even if the two were momentarily out of sync mid-animation,
/// they'd just overlap slightly rather than crash with a `RenderFlex`
/// overflow.
class _AnimatedSegments extends StatefulWidget {
  const _AnimatedSegments({
    required this.current,
    required this.previous,
    required this.height,
    required this.leftColor,
    required this.rightColor,
    required this.duration,
  });

  final _SegmentLayout current;

  /// Null means nothing was ever shown before — start from [_SegmentLayout.zero].
  final _SegmentLayout? previous;
  final double height;
  final Color leftColor;
  final Color rightColor;
  final Duration duration;

  @override
  State<_AnimatedSegments> createState() => _AnimatedSegmentsState();
}

class _AnimatedSegmentsState extends State<_AnimatedSegments> {
  // AnimatedPositioned never animates its very first build — there's no
  // earlier value yet for it to interpolate from, so it would otherwise
  // just pop in at full size. Rendering `previous` (or zero, if nothing
  // was ever shown before) for exactly one frame, then flipping to
  // `current`, turns that into a genuine change for AnimatedPositioned to
  // animate — a real prior state continues visually instead of either
  // replaying a from-zero entrance or popping in unanimated.
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _revealed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout =
        _revealed ? widget.current : (widget.previous ?? _SegmentLayout.zero);

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          _segment(width: layout.leftWidth, color: widget.leftColor, left: 0),
          _segment(
              width: layout.rightWidth, color: widget.rightColor, right: 0),
        ],
      ),
    );
  }

  Widget _segment({
    required double width,
    required Color color,
    double? left,
    double? right,
  }) {
    // The outer positioned box is *always* stretched to the bar's full
    // height (top:0, bottom:0) — for every segment, dot or not, present or
    // absent — so width is the only thing this level ever animates.
    //
    // Doing this any other way (e.g. deriving top/height from whether the
    // segment happens to be a dot right now) means an absent segment
    // that's about to become a dot arrives with a *different* vertical
    // representation (an explicit height going 0 -> h) than a segment
    // that's already a dot (a constant, fully-stretched box) — and even
    // though a width:0 box is invisible either way, AnimatedPositioned
    // tweens the *resolved* edges, not the representation, so that
    // difference alone was enough to animate a height change on a dot's
    // first appearance despite it "never changing" in the dot branch.
    // Keeping the outer box's vertical geometry identical in every state
    // removes that possibility entirely.
    return AnimatedPositioned(
      duration: widget.duration,
      curve: Curves.easeInOut,
      left: left,
      right: right,
      top: 0,
      bottom: 0,
      width: width,
      // One shape formula for dot, pill, and everything in between —
      // rather than switching between two different widget subtrees at
      // the isDot boundary. A widget-type swap can't be animated (Flutter
      // just unmounts the old shape and mounts the new one instantly), so
      // an isDot flip used to visibly *snap* between a circle and a pill
      // instead of morphing. Sizing the shape to
      // (currentWidth, min(currentWidth, barHeight)) is continuous across
      // the whole range: a thin sliver is a small square (reads as a
      // circle via a large border radius), and once width reaches the bar
      // height it's pinned there, giving a normal full-height pill for
      // any width beyond that — the same LayoutBuilder-driven child the
      // whole time, so AnimatedPositioned's width animation carries the
      // shape smoothly through a dot<->pill transition instead of
      // snapping at the boundary.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shapeHeight = constraints.maxWidth < widget.height
              ? constraints.maxWidth
              : widget.height;

          return Center(
            child: SizedBox(
              width: constraints.maxWidth,
              height: shapeHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(shapeHeight / 2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
