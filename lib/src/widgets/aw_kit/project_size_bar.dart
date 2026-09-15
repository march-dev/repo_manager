import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../repo_manager.dart';

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

  // Below this, the core and cache dots (each SizeBar.height wide, plus the
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
                  leftValue: size.baseBytes,
                  rightValue: size.cacheBytes,
                  totalValue: size.totalBytes,
                  leftColor: ProjectSizeType.core.color,
                  rightColor: ProjectSizeType.cache.color,
                  height: height,
                  animationDuration: _animationDuration,
                  previousLeftValue: previous?.baseBytes,
                  previousRightValue: previous?.cacheBytes,
                  previousTotalValue: previous?.totalBytes,
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
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(fontSize: 11, color: labelColor),
          ),
          const SizedBox(height: 4),
          bar,
        ],
      ),
    );
  }
}
