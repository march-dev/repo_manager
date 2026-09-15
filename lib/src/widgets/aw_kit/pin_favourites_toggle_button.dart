import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../repo_manager.dart';

/// A table header cell toggling whether favourited rows stay pinned to the
/// top of the list. An [InkWell] rather than an [IconButton] — matching
/// [HeaderSortableButton] next to it instead of looking like a stray action
/// button — the icon is sized to sit next to that header's own 11px
/// label/12px sort arrow instead of a full [IconButton]'s much larger
/// default tap target.
class PinFavouritesToggleButton extends AppTableHeaderCell {
  const PinFavouritesToggleButton({
    super.key,
    required this.pinned,
    required this.onToggle,
  });

  final bool pinned;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return ClipRect(
      child: Tooltip(
        message: pinned
            ? l10n.explorerPinFavouritesOnTooltip
            : l10n.explorerPinFavouritesOffTooltip,
        child: InkWell(
          onTap: onToggle,
          child: Center(
            child: Icon(
              pinned ? CupertinoIcons.pin_fill : CupertinoIcons.pin_slash,
              size: AppSizes.iconTiny,
              color: pinned
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
