import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../repo_manager.dart';

/// The shared "project as a row" content — an icon, its name, and (unless
/// [subtitle] overrides it) a language badge plus, for a monorepo, a
/// package-count badge — reused by Explorer/Storage's table rows and
/// Dashboard's quick-launch tiles instead of each screen laying out the
/// same icon+name+badge cluster by hand.
///
/// This only lays out that cluster — it doesn't own any row chrome (zebra
/// striping, hover state, tap handling, ...), since that differs enough
/// between a table row, a tile, and a tree row that forcing one shared
/// shell isn't worth it; callers wrap this in whatever shell they need.
///
/// The default subtitle's monorepo badge renders inside its own [Observer]
/// since a caller typically builds this from a lazily-built list (e.g.
/// [AppTable]'s `ListView.builder`) outside whatever `Observer` scope wraps
/// their own `build()` — without its own, a badge count that finishes
/// loading in the background wouldn't trigger a rebuild here on its own.
class ProjectRow extends StatelessWidget {
  const ProjectRow({
    super.key,
    required this.project,
    this.iconSize = 40,
    this.gap = 16,
    this.leadingGap = 0,
    this.titleStyle,
    this.subtitle,
    this.trailing,
    this.onMonorepoBadgeTap,
  });

  final ProjectModel project;
  final double iconSize;

  /// Defaults to the ambient [DefaultTextStyle] when null (a table row's
  /// own plain body text); Dashboard's tiles pass their own bolder style.
  final TextStyle? titleStyle;

  /// Gap between the icon and the name/subtitle column, and (when
  /// [trailing] is given) on both sides of [trailing].
  final double gap;

  /// Extra inset before the icon — e.g. a table row's own left padding,
  /// which (unlike [gap]) a tile packed flush against its own card padding
  /// doesn't want. Zero (no inset) by default.
  final double leadingGap;

  /// Replaces the default language/monorepo-badge line when given.
  final Widget? subtitle;

  /// Shown at the end of the row (e.g. Explorer's hover [OpenInHint]).
  final Widget? trailing;

  /// Only used by the default subtitle's monorepo badge — ignored when
  /// [subtitle] is given.
  final VoidCallback? onMonorepoBadgeTap;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;

    return Row(
      children: [
        if (leadingGap > 0) SizedBox(width: leadingGap),
        ProjectIcon(iconPath: project.iconPath, size: iconSize),
        SizedBox(width: gap),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    const SizedBox(height: 2),
                    subtitle ??
                        _DefaultSubtitle(
                          project: project,
                          onMonorepoBadgeTap: onMonorepoBadgeTap,
                        ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: gap),
                trailing,
                SizedBox(width: gap),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DefaultSubtitle extends StatelessWidget {
  const _DefaultSubtitle({required this.project, this.onMonorepoBadgeTap});

  final ProjectModel project;
  final VoidCallback? onMonorepoBadgeTap;

  @override
  Widget build(BuildContext context) {
    final monorepoTool = project.monorepoTool;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProjectLanguageBadge(
          language: project.language,
          framework: project.framework,
        ),
        if (monorepoTool != null) ...[
          const SizedBox(width: 6),
          Observer(
            builder: (context) => MonorepoBadge(
              tool: monorepoTool,
              count: project.subPackagesLoaded
                  ? project.subPackages.projectCount
                  : null,
              onTap: onMonorepoBadgeTap,
            ),
          ),
        ],
      ],
    );
  }
}
