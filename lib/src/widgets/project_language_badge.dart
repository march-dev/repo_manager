import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/project_language.enum.dart';

/// A small icon + label identifying a project's language/framework, shown
/// as a subtitle under a project's name.
class ProjectLanguageBadge extends StatelessWidget {
  const ProjectLanguageBadge({super.key, required this.language});

  final ProjectLanguage language;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    final iconAsset = language.iconAsset;

    final icon = SizedBox(
      width: 12,
      height: 12,
      child: iconAsset != null
          ? Image.asset(iconAsset)
          : Icon(CupertinoIcons.chevron_left_slash_chevron_right,
              size: 12, color: color),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 4),
        Text(language.label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
