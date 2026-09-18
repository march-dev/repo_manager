import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import 'circle_icon_button.dart';

/// A header refresh action — storage.screen.dart's and explorer.screen
/// .dart's own manual refresh button, and whichever screen picks this up
/// next. Spins the icon continuously while [refreshing] (whether triggered
/// by tapping this button or a silent background refresh elsewhere) and
/// disables taps for the duration, rather than swapping the icon for a
/// separate progress indicator.
class RefreshIconButton extends StatefulWidget {
  const RefreshIconButton({
    super.key,
    required this.refreshing,
    required this.onPressed,
    this.tooltip,
  });

  final bool refreshing;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  State<RefreshIconButton> createState() => _RefreshIconButtonState();
}

class _RefreshIconButtonState extends State<RefreshIconButton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void initState() {
    super.initState();
    if (widget.refreshing) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant RefreshIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshing == oldWidget.refreshing) return;
    if (widget.refreshing) {
      _controller.repeat();
    } else {
      // Snaps back to the upright icon rather than freezing mid-spin.
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      onPressed: widget.refreshing ? null : widget.onPressed,
      backgroundColor: Colors.transparent,
      tooltip: widget.tooltip,
      icon: RotationTransition(
        turns: _controller,
        // CupertinoIcons.refresh is two chasing arrows, which reads oddly
        // mid-spin — a single clockwise arrow is the shape actually meant
        // to be animated this way.
        child: const Icon(Icons.refresh_rounded, size: AppSizes.iconLarge),
      ),
    );
  }
}
