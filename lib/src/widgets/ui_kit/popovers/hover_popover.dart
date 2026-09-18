import 'dart:async';

import 'package:flutter/material.dart';

/// Shows [popoverBuilder]'s content in a floating overlay while the mouse
/// hovers [child] (or the popover itself) — for content too rich for
/// [Tooltip]'s plain-text-only `message`/`richMessage` (e.g. a wrapped
/// grid of icon+label chips), where a bespoke widget is worth it over a
/// long comma-separated sentence.
///
/// There's a short grace period before actually hiding, rather than
/// closing the instant the pointer leaves [child] — otherwise moving the
/// mouse across the small gap from [child] to the popover itself (they're
/// not touching, since the popover floats slightly below it) would close
/// it before the pointer ever reaches the content.
class HoverPopover extends StatefulWidget {
  const HoverPopover({
    super.key,
    required this.child,
    required this.popoverBuilder,
  });

  final Widget child;
  final WidgetBuilder popoverBuilder;

  @override
  State<HoverPopover> createState() => _HoverPopoverState();
}

class _HoverPopoverState extends State<HoverPopover> {
  final _controller = OverlayPortalController();
  final _link = LayerLink();
  Timer? _hideTimer;

  void _show() {
    _hideTimer?.cancel();
    if (!_controller.isShowing) _controller.show();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 150), _controller.hide);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        onEnter: (_) => _show(),
        onExit: (_) => _scheduleHide(),
        child: OverlayPortal(
          controller: _controller,
          // OverlayPortal always lays its overlay child out with
          // BoxConstraints.tight(theatreSize) — a hard-coded full-
          // app-window size, unconditionally, regardless of Positioned
          // (see _RenderLayoutSurrogateProxyBox.performLayout in the
          // framework's own overlay.dart: `boxSize = theaterConstraints
          // .biggest`, with no isPositioned branch at all for this deferred-
          // layout mechanism). Align (or Center/UnconstrainedBox — anything
          // whose RenderObject loosens constraints for its own child) is
          // what actually absorbs that: it reports the forced full-window
          // size upward to satisfy the tight constraint, but hands
          // CompositedTransformFollower a *loosened* constraint below,
          // letting the follower (and thus the popover content inside it)
          // size itself naturally instead of being stretched to fill the
          // window too. Alignment itself is irrelevant here — the
          // follower's own leader-link transform positions its content
          // independent of wherever Align would have placed it.
          overlayChildBuilder: (context) => Align(
            alignment: Alignment.topLeft,
            child: CompositedTransformFollower(
              link: _link,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 8),
              // Its own MouseRegion so hovering into the popover (rather
              // than back onto child) also cancels the pending hide.
              child: MouseRegion(
                onEnter: (_) => _show(),
                onExit: (_) => _scheduleHide(),
                child: widget.popoverBuilder(context),
              ),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
