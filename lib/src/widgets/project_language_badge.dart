import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/project_framework.enum.dart';
import '../models/project_language.enum.dart';

/// A small icon + label identifying a project's language, shown as a
/// subtitle under a project's name — followed by its framework's own icon
/// + label (e.g. "Dart · Flutter", "JavaScript · React") when one was
/// detected.
class ProjectLanguageBadge extends StatelessWidget {
  const ProjectLanguageBadge({
    super.key,
    required this.language,
    this.framework,
  });

  final ProjectLanguage language;
  final ProjectFramework? framework;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    final framework = this.framework;

    Widget iconFor(String? iconAsset) {
      return SizedBox(
        width: 12,
        height: 12,
        child: iconAsset != null
            ? Image.asset(iconAsset)
            : Icon(
                CupertinoIcons.chevron_left_slash_chevron_right,
                size: 12,
                color: color,
              ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconFor(language.iconAsset),
        const SizedBox(width: 4),
        Text(language.label, style: TextStyle(fontSize: 11, color: color)),
        if (framework != null) ...[
          Text(' · ', style: TextStyle(fontSize: 11, color: color)),
          iconFor(framework.iconAsset),
          const SizedBox(width: 4),
          Text(framework.label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ],
    );
  }
}
