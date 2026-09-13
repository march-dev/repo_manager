import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../repo_manager.dart';

/// A small colored circle, typically paired with a label to indicate what a
/// [SizeBar] segment represents.
class ColorDot extends StatelessWidget {
  const ColorDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

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

/// A rounded, framed bar visualizing the proportion of [coreBytes] vs
/// [cacheBytes] out of [totalBytes] (inspired by macOS's storage usage bar).
///
/// Core and cache render as two independently-rounded segments separated by
/// a small gap, rather than one continuously-filled bar. A segment too thin
/// to read as a pill renders as a dot instead, and a segment with zero bytes
/// isn't painted at all — animating in from nothing (rather than popping in
/// at full size) if it later gains bytes. With no data at all yet (and
/// nothing else indicating a loading state), the bar fills fully with the
/// core color as a neutral placeholder rather than sitting empty.
class SizeBar extends StatelessWidget {
  const SizeBar({
    super.key,
    required this.coreBytes,
    required this.cacheBytes,
    required this.totalBytes,
    this.height = 12,
    this.width,
    this.animationDuration = const Duration(milliseconds: 350),
    this.previousCoreBytes,
    this.previousCacheBytes,
    this.previousTotalBytes,
  });

  final int coreBytes;
  final int cacheBytes;
  final int totalBytes;

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
  final int? previousCoreBytes;
  final int? previousCacheBytes;
  final int? previousTotalBytes;

  /// Gap between the background frame and the segments, so the frame reads
  /// as a visible border around the bar rather than being fully covered.
  static const framePadding = 2.0;

  // Gap between the core and cache segments — public so ProjectSizeBar can
  // work out the smallest width that still fits two full (unsquished) dots.
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
        final current = _layoutFor(barWidth, coreBytes, cacheBytes, totalBytes);

        _SegmentLayout? previous;
        if (previousCoreBytes != null &&
            previousCacheBytes != null &&
            previousTotalBytes != null) {
          previous = _layoutFor(
            barWidth,
            previousCoreBytes!,
            previousCacheBytes!,
            previousTotalBytes!,
          );
        }

        return _AnimatedSegments(
          current: current,
          previous: previous,
          height: height,
          duration: animationDuration,
        );
      },
    );
  }

  _SegmentLayout _layoutFor(
    double barWidth,
    int coreBytes,
    int cacheBytes,
    int totalBytes,
  ) {
    if (totalBytes <= 0) {
      // No data at all yet: fill with the core color as a neutral
      // placeholder, using the same layout pipeline real data does —
      // rather than a separate widget — so the eventual transition to
      // real data is one continuous animation instead of a hard swap.
      return _SegmentLayout(coreWidth: barWidth, cacheWidth: 0);
    }

    final hasCore = coreBytes > 0;
    final hasCache = cacheBytes > 0;
    final hasGap = hasCore && hasCache;
    final usableWidth = hasGap ? barWidth - gap : barWidth;

    var coreWidth = hasCore ? usableWidth * coreBytes / totalBytes : 0.0;
    var cacheWidth = hasCache ? usableWidth * cacheBytes / totalBytes : 0.0;

    // A segment too thin to read as a pill is drawn as a dot instead;
    // whatever width it would have used is handed to the other segment.
    // (The dot's shape itself — a circle rather than a squished pill — is
    // handled purely by width in _AnimatedSegments; this is only about
    // deciding how much width each segment's *target* gets.)
    final coreIsDot = hasCore && coreWidth < height;
    final cacheIsDot = hasCache && cacheWidth < height;

    if (coreIsDot) coreWidth = height;
    if (cacheIsDot) cacheWidth = height;

    if (coreIsDot && !cacheIsDot && hasCache) {
      cacheWidth = usableWidth - coreWidth;
    } else if (cacheIsDot && !coreIsDot && hasCore) {
      coreWidth = usableWidth - cacheWidth;
    }

    return _SegmentLayout(coreWidth: coreWidth, cacheWidth: cacheWidth);
  }
}

/// The resolved pixel widths for one [SizeBar] state (a given byte split at
/// a given bar width).
class _SegmentLayout {
  const _SegmentLayout({required this.coreWidth, required this.cacheWidth});

  static const zero = _SegmentLayout(coreWidth: 0, cacheWidth: 0);

  final double coreWidth;
  final double cacheWidth;
}

/// Renders the core/cache segments, animating any change to their widths
/// or heights (a segment appearing/disappearing, or the split between two
/// already-present segments shifting).
///
/// Core is anchored to the bar's left edge and cache to its right edge (via
/// a [Stack], not a [Row]), so each one visibly grows/shrinks from its own
/// fixed edge — cache always animates in from the right, regardless of
/// whatever core's current width happens to be, rather than appearing to
/// grow outward from wherever core's trailing edge currently sits. This
/// also means the two segments can never overflow their shared bar: unlike
/// a `Row`, a `Stack` doesn't require its children's sizes to sum to the
/// available width, so even if core and cache were momentarily out of sync
/// mid-animation, they'd just overlap slightly rather than crash with a
/// `RenderFlex` overflow.
class _AnimatedSegments extends StatefulWidget {
  const _AnimatedSegments({
    required this.current,
    required this.previous,
    required this.height,
    required this.duration,
  });

  final _SegmentLayout current;

  /// Null means nothing was ever shown before — start from [_SegmentLayout.zero].
  final _SegmentLayout? previous;
  final double height;
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
          _segment(
              width: layout.coreWidth, color: ProjectSizeType.core, left: 0),
          _segment(
              width: layout.cacheWidth, color: ProjectSizeType.cache, right: 0),
        ],
      ),
    );
  }

  Widget _segment({
    required double width,
    required ProjectSizeType color,
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
                  color: color.color,
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

/// The per-project row's [SizeBar]: prints the project's total size above
/// it, adds a loading spinner while the size is still being computed, and a
/// hover tooltip breaking the total down by core/cache once it's known.
class ProjectSizeBar extends StatelessObserverWidget {
  const ProjectSizeBar({
    super.key,
    required this.item,
    required this.maxTotalBytes,
  });

  static const height = 12.0;
  static const _animationDuration = Duration(milliseconds: 350);

  // A sliver this thin would otherwise be easy to miss (and hard to hover
  // for its tooltip), so it's the smallest fraction of maxTotalBytes any
  // bar is allowed to shrink to.
  static const _minWidthFraction = 0.06;

  // Below this, core and cache's dots (each SizeBar.height wide, plus the
  // gap between them) don't both fit and end up overlapping instead of
  // rendering as two distinct circles — so no bar is ever scaled narrower
  // than the width two full-size dots actually need. This is the *outer*
  // width passed to SizeBar, so it also has to cover the frame padding
  // SizeBar reserves on each side for its own border — otherwise the
  // segments themselves would still be squeezed below the space they need.
  static const _minBarWidth =
      2 * height + SizeBar.gap + 2 * SizeBar.framePadding;

  final ProjectItemStore item;

  // The largest project total currently in the list (see
  // StorageStore.maxProjectTotalBytes) — this row's bar is scaled relative
  // to it, so its length reads as a size comparison across the whole list
  // rather than just this project's own core:cache ratio.
  final int maxTotalBytes;

  WidgetSpan _legendDot(Color color) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: ColorDot(color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = item.size;
    final labelColor = colorScheme.onSurface.withValues(alpha: 0.7);

    Widget bar;

    if (size == null) {
      const outerHeight = height + SizeBar.framePadding * 2;

      bar = Container(
        width: double.infinity,
        height: outerHeight,
        padding: const EdgeInsets.all(SizeBar.framePadding),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(outerHeight / 2),
        ),
        child: LinearProgressIndicator(
          borderRadius: BorderRadius.circular(outerHeight / 2),
          backgroundColor: colorScheme.surfaceContainerHighest,
          // A more app-friendly color than the theme's default accent;
          // falls back to the core segment color used throughout the bar.
          valueColor: AlwaysStoppedAnimation(ProjectSizeType.core.color),
          trackGap: 0,
        ),
      );
    } else {
      // What was last actually shown is remembered on the store (not this
      // widget's own state), because a later rebuild-from-scratch of this
      // row — e.g. the list reordering after a re-sort, which
      // ListView.builder/.separated handles by discarding and recreating
      // row widgets rather than moving them — would otherwise lose track
      // of it entirely: a fresh widget has no "previous build" to animate
      // from, so without this it either replays the from-zero entrance
      // animation for data that isn't new, or (if that's suppressed some
      // other way) pops in unanimated even when the data genuinely did
      // just change. Remembering the actual last-shown values lets a
      // fresh widget continue the transition from wherever it visually
      // left off, whether or not the underlying Element survived.
      final previous = item.lastShownSize;
      item.lastShownSize = size;

      final widthFraction = maxTotalBytes > 0
          ? (size.totalBytes / maxTotalBytes).clamp(_minWidthFraction, 1.0)
          : 1.0;

      bar = LayoutBuilder(
        builder: (context, constraints) {
          // A plain widthFactor can shrink the bar below the width its own
          // dots need once the column itself is fairly narrow — clamp the
          // resolved pixel width instead of the fraction so that can't
          // happen regardless of how small this project is relative to
          // maxTotalBytes.
          final barWidth = math.max(
            constraints.maxWidth * widthFraction,
            _minBarWidth,
          );

          return Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: barWidth,
              child: Tooltip(
                verticalOffset: 12,
                richMessage: TextSpan(
                  children: [
                    _legendDot(ProjectSizeType.core.color),
                    TextSpan(text: ' Core: ${formatBytes(size.baseBytes)}\n'),
                    _legendDot(ProjectSizeType.cache.color),
                    TextSpan(
                      text: ' Cache: ${formatBytes(size.cacheBytes)}',
                    ),
                  ],
                ),
                child: SizeBar(
                  coreBytes: size.baseBytes,
                  cacheBytes: size.cacheBytes,
                  totalBytes: size.totalBytes,
                  height: height,
                  animationDuration: _animationDuration,
                  previousCoreBytes: previous?.baseBytes,
                  previousCacheBytes: previous?.cacheBytes,
                  previousTotalBytes: previous?.totalBytes,
                ),
              ),
            ),
          );
        },
      );
    }

    return AnimatedSwitcher(
      duration: _animationDuration,
      child: Column(
        key: ValueKey(size == null ? 'loading' : 'bar'),
        mainAxisSize: MainAxisSize.min,
        // Stretch (rather than just start) so this always claims the full
        // column width itself, regardless of how its parent aligns it —
        // otherwise, now that the bar is shorter than the column for
        // smaller projects, the whole label+bar block could get centered
        // as one narrow unit instead of pinned to the column's left edge.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            size != null ? formatBytes(size.totalBytes) : '',
            style: TextStyle(fontSize: 11, color: labelColor),
          ),
          const SizedBox(height: 4),
          bar,
        ],
      ),
    );
  }
}
