import 'package:flutter/material.dart';

/// Wraps [child] with the common "skeleton loading" effect — a soft
/// highlight band sweeping left to right, repeating for as long as this
/// stays mounted — for placeholder content that already sits in its final
/// layout spot and just needs to visibly read as "still loading" without
/// swapping to a spinner or any other shape.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.onSurface.withValues(alpha: 0.18);
    final highlight = colorScheme.onSurface.withValues(alpha: 0.55);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          // srcIn replaces the child's own painted colour entirely with
          // the gradient's, using only the child's shape/glyphs as a
          // mask — srcATop instead *blends* the gradient with the
          // child's existing colour, which is invisible here since both
          // are the same onSurface hue (blending a colour with itself at
          // any alpha still nets that same colour, so nothing visibly
          // moved).
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [base, highlight, base],
            stops: const [0.35, 0.5, 0.65],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            transform: _SlidingGradientTransform(slide: _controller.value),
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Slides the whole gradient from off the left edge to off the right edge
/// as [slide] goes 0 -> 1, which [Shimmer] repeats continuously — the
/// gradient itself stays put; only the visible highlight band moves.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slide});

  final double slide;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (2 * slide - 1), 0, 0);
  }
}
