import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// The single-pixel, theme-outlined row/section separator repeated across
/// tables, cards, and settings lists.
class HairlineDivider extends StatelessWidget {
  const HairlineDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: AppSizes.borderWidth,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
