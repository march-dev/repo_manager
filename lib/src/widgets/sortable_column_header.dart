import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SortableColumnHeader extends StatelessWidget {
  const SortableColumnHeader({
    super.key,
    required this.label,
    required this.active,
    required this.ascending,
    required this.onTap,
    this.alignment = Alignment.centerLeft,
    this.padding = EdgeInsets.zero,
  });

  final String label;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;
  final Alignment alignment;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = active
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.6);

    // InkWell must be the outer widget so it inherits the full column size
    // from its parent (Expanded/SizedBox); Align alone would only size
    // itself to the label's content, shrinking the tappable area. ClipRect
    // keeps the ink response confined to that column (e.g. the Name column
    // reserves left padding for the row icon above it — without the clip,
    // the splash can bleed into that reserved area past the label itself).
    return ClipRect(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Align(
            alignment: alignment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: color,
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: 2),
                  Icon(
                    ascending
                        ? CupertinoIcons.arrow_up
                        : CupertinoIcons.arrow_down,
                    size: 12,
                    color: color,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
