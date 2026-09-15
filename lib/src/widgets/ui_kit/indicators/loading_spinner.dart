import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';

/// A small inline spinner sized to sit in place of an icon (e.g. a
/// button's own icon slot while its action is in flight).
class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({
    super.key,
    this.size = AppSizes.iconSmall,
    this.strokeWidth = AppSizes.spacing2,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: strokeWidth, color: color),
    );
  }
}
