import 'package:flutter/material.dart';

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
/// [ProjectModel] itself carries no MobX observables, so this widget only
/// ever shows the `project` it was actually built with — reflecting a
/// later change (e.g. a monorepo's member-package tree finishing loading
/// in the background) requires whoever constructs this to be rebuilt with
/// a fresh [ProjectModel] first. A caller built from a lazily-built list
/// (e.g. [AppTable]'s `ListView.builder`), which sits outside whatever
/// `Observer` scope wraps its own `build()`, needs to wrap its own
/// `ProjectRow(...)` call in an `Observer` reading the observable that
/// actually holds the project (see storage.screen.dart's row builder,
/// which does this for `ProjectItemState.project`).
class ProjectRow extends StatelessWidget {
  const ProjectRow({
    super.key,
    required this.project,
    this.iconSize = AppSizes.rowIconSize,
    this.gap = AppSizes.spacing16,
    this.leadingGap = 0,
    this.titleStyle,
    this.subtitle,
    this.trailing,
    double? trailingGap,
    this.onMonorepoBadgeTap,
    this.showMonorepoPackageCount = true,
  }) : trailingGap = trailingGap ?? gap;

  final ProjectModel project;
  final double iconSize;

  /// Defaults to the ambient [DefaultTextStyle] when null (a table row's
  /// own plain body text); Dashboard's tiles pass their own bolder style.
  final TextStyle? titleStyle;

  /// Gap between the icon and the name/subtitle column, and (when
  /// [trailing] is given) between the name column and [trailing].
  final double gap;

  /// Gap after [trailing], before the row's own right edge — defaults to
  /// [gap] (matching the space before it) when not given, e.g. so a card
  /// wrapping this row with its own extra padding can pull that trailing
  /// edge in slightly rather than doubling up with [gap] again. Ignored
  /// when [trailing] is null.
  final double trailingGap;

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

  /// Storage's own rows pass false — its size figure/bar already covers
  /// the whole monorepo workspace as one folder rather than expanding its
  /// member packages the way Explorer does (see storage.screen.dart's own
  /// doc), so a package count here would just be a number nothing else on
  /// that row lets you act on. Only used by the default subtitle's
  /// monorepo badge — ignored when [subtitle] is given.
  final bool showMonorepoPackageCount;

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
                child: _NameColumn(
                  project: project,
                  titleStyle: titleStyle,
                  subtitle: subtitle,
                  onMonorepoBadgeTap: onMonorepoBadgeTap,
                  showMonorepoPackageCount: showMonorepoPackageCount,
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: gap),
                trailing,
                SizedBox(width: trailingGap),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NameColumn extends StatelessWidget {
  const _NameColumn({
    required this.project,
    required this.titleStyle,
    required this.subtitle,
    required this.onMonorepoBadgeTap,
    required this.showMonorepoPackageCount,
  });

  final ProjectModel project;
  final TextStyle? titleStyle;
  final Widget? subtitle;
  final VoidCallback? onMonorepoBadgeTap;
  final bool showMonorepoPackageCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(project.name, overflow: TextOverflow.ellipsis, style: titleStyle),
        const SizedBox(height: AppSizes.spacing2),
        subtitle ??
            _DefaultSubtitle(
              project: project,
              onMonorepoBadgeTap: onMonorepoBadgeTap,
              showMonorepoPackageCount: showMonorepoPackageCount,
            ),
      ],
    );
  }
}

class _DefaultSubtitle extends StatelessWidget {
  const _DefaultSubtitle({
    required this.project,
    required this.showMonorepoPackageCount,
    this.onMonorepoBadgeTap,
  });

  final ProjectModel project;
  final bool showMonorepoPackageCount;
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
          const SizedBox(width: AppSizes.spacing6),
          MonorepoBadge(
            tool: monorepoTool,
            count: showMonorepoPackageCount && project.subPackagesLoaded
                ? project.subPackages.declaredPackageCount(monorepoTool)
                : null,
            onTap: onMonorepoBadgeTap,
          ),
        ],
      ],
    );
  }
}
