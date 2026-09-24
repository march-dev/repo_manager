import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../cards/app_card.dart';

/// The rounded, bordered, fixed-width shell every rail-shaped container in
/// the app uses — the real nav rail (app.dart's `_NavigationRail`) and a
/// lone rail-styled action elsewhere (project_details.screen.dart's own
/// back button) alike — so both stay visually identical (width, margin,
/// corner radius) without duplicating this shape by hand.
class RailContainer extends StatelessWidget {
  const RailContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Wider than a stock NavigationRail's own 80/88px collapsed width —
      // "Dashboard" (the longest label the real rail shows) was clipping/
      // wrapping at that width against this shell's own pill/label layout.
      width: 96,
      child: AppCard(
        margin: const EdgeInsets.fromLTRB(
          AppSizes.spacing16,
          AppSizes.spacing16,
          0,
          AppSizes.spacing16,
        ),
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
