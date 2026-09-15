import 'package:flutter/material.dart';

/// A fixed-height sticky header for a [CustomScrollView] section — stays
/// pinned to the top of the viewport while that section's own content
/// scrolls underneath it, rather than scrolling away with the rest of the
/// section like a plain heading would.
class PinnedSectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  PinnedSectionHeaderDelegate({
    required this.child,
    this.height = 44,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      // Opaque and matching the page background — this sits on top of the
      // section's own content as it scrolls underneath it, so without this
      // it would read as transparent glass over whatever's currently
      // scrolled beneath.
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.centerLeft,
      padding: padding,
      child: child,
    );
  }

  // Cheap enough to just always rebuild rather than trying to diff `child`
  // by equality — most widgets (this one's callers' titles included) don't
  // override `==`, so comparing instances would just report "changed" on
  // every rebuild anyway.
  @override
  bool shouldRebuild(covariant PinnedSectionHeaderDelegate oldDelegate) => true;
}
