import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../repo_manager.dart';

/// A per-row favourite toggle: a filled star while [project] is favourited,
/// an outline star otherwise. Reads/writes favourite state through the
/// nearest [ExplorerStore], so any screen already providing one (Explorer,
/// Storage) can drop this in without wiring a callback of its own.
class ProjectFavouriteButton extends StatelessWidget {
  const ProjectFavouriteButton({super.key, required this.project, this.size});

  final ProjectModel project;

  /// Pins this button to a fixed square tap target — see
  /// [CircleIconButton.size].
  final double? size;

  static const _iconSize = 20.0;

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
      onPressed: () => context.read<ExplorerStore>().toggleFavourite(project),
      icon: Icon(
        project.favourite ? CupertinoIcons.star_fill : CupertinoIcons.star,
        size: _iconSize,
      ),
    );
  }
}
