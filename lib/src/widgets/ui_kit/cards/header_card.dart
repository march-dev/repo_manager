import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import 'app_card.dart';

/// The rounded, bordered card shared by every screen's top-of-page header:
/// a title row (with optional trailing actions) and, optionally, more
/// content below it (e.g. storage.screen.dart's size bar/summary).
class HeaderCard extends StatelessWidget {
  const HeaderCard({
    super.key,
    required this.title,
    this.actions = const [],
    this.child,
    this.margin = const EdgeInsets.all(AppSizes.spacing16),
  });

  final String title;

  /// Trailing widgets in the title row, right-aligned — [title] takes
  /// whatever space these leave (truncating with an ellipsis rather than
  /// overflowing if that's not much), with at least a fixed gap between
  /// the two.
  final List<Widget> actions;

  /// Extra content shown below the title row, separated by a fixed gap.
  final Widget? child;

  /// Defaults to surrounding the card on all sides, for use as a standalone
  /// screen header (storage.screen.dart, explorer.screen.dart). Pass
  /// [EdgeInsets.zero] when stacking several of these and handling spacing
  /// externally instead (settings.screen.dart).
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      margin: margin,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: colorScheme.onSurface,
                      ),
                ),
              ),
              if (actions.isNotEmpty) const SizedBox(width: AppSizes.spacing12),
              ...actions,
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: AppSizes.spacing12),
            child!,
          ],
        ],
      ),
    );
  }
}
