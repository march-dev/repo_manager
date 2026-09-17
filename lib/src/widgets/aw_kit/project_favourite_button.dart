import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../repo_manager.dart';

/// A per-row favourite toggle: a filled star while [project] is favourited,
/// an outline star otherwise. Purely presentational — takes [onPressed]
/// rather than reaching into a screen's own state itself, so it stays
/// usable from anywhere a project row is rendered regardless of which
/// state actually owns that project's favourite flag.
class ProjectFavouriteButton extends StatelessWidget {
  const ProjectFavouriteButton({
    super.key,
    required this.project,
    required this.onPressed,
    this.size,
  });

  final ProjectModel project;
  final VoidCallback onPressed;

  /// Pins this button to a fixed square tap target — see
  /// [CircleIconButton.size].
  final double? size;

  static const _iconSize = AppSizes.iconLarge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CircleIconButton(
      size: size,
      backgroundColor: Colors.transparent,
      color: project.favourite ? AppColors.favourite : null,
      tooltip: project.favourite
          ? l10n.explorerRemoveFavouriteTooltip
          : l10n.explorerAddFavouriteTooltip,
      onPressed: onPressed,
      icon: Icon(
        project.favourite ? CupertinoIcons.star_fill : CupertinoIcons.star,
        size: _iconSize,
      ),
    );
  }
}
