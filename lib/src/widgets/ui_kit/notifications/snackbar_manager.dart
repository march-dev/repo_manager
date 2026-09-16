import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// The single place a transient status message (e.g. "collection already
/// exists", "couldn't clean up MyApp") gets shown, so every one of them
/// looks and behaves the same, and a second message never stacks on top
/// of a first one still on screen.
///
/// Raises its own [OverlayEntry] in the top-right corner rather than going
/// through [ScaffoldMessenger]'s [SnackBar] — that widget is always
/// anchored to the bottom of the Scaffold (a margin only insets it from
/// that edge, it can't be moved to a different one), which isn't where
/// this app wants a passing status message to show up.
///
/// Takes no [BuildContext] — [show] is called from plenty of places that
/// don't have one at all (a repo/store reporting a failed filesystem
/// operation), not just widgets. [attach] wires this to the app's root
/// [Navigator] once, at startup (see app.dart); every call to [show]
/// before that point, or if the overlay somehow isn't mounted, is just a
/// no-op rather than a crash.
abstract final class SnackbarManager {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static OverlayEntry? _entry;

  static void show(
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    // Replaces rather than stacks — a message still showing when another
    // fires is almost always stale (e.g. the user retried the same
    // action), so swapping it out reads truer than making them wait it
    // out.
    _entry?.remove();

    final entry = OverlayEntry(
      builder: (context) =>
          _Toast(message: message, backgroundColor: backgroundColor),
    );
    _entry = entry;
    overlay.insert(entry);

    Future.delayed(duration, () {
      if (_entry != entry) return;
      entry.remove();
      _entry = null;
    });
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.message, this.backgroundColor});

  final String message;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + AppSizes.spacing16,
      right: AppSizes.spacing16,
      // Purely informational — nothing to tap on it — so it shouldn't
      // steal clicks meant for whatever's underneath while it's up.
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: AppSizes.spacing12,
            ),
            decoration: BoxDecoration(
              // Orange rather than a neutral surface or the theme's own
              // accent — reads as a warning/notice, not just a status
              // update, at a glance.
              color: backgroundColor ?? Colors.orange,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}
