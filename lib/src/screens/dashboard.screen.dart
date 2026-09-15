import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

/// The app's landing tab — a quick summary of everything Explorer/Storage
/// have found, and a one-tap launcher for whatever's been starred as a
/// favourite there or opened recently. Reads ExplorerStore/StorageStore
/// rather than owning its own copies of the project list/size data (see
/// _RootScaffold, which provides both above this screen and Explorer's/
/// Storage's own), so starring a project or cleaning up cache stays in
/// sync between screens instantly.
///
/// The summary lives in four independent cards (Projects/Size overview,
/// Language/Framework distribution) rather than one combined header — each
/// reads only the store data it needs, and there's no longer a page title
/// above them, since the nav rail already shows Dashboard as the selected
/// tab. The cards scroll away with the rest of the page (Pinned Projects/
/// Recently Opened) rather than staying pinned above it; only the section
/// titles below them stay pinned, as sticky sliver headers.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        // Wraps the whole scrollable page so any tile's right-click menu
        // has somewhere to open into — see showProjectContextMenu.
        child: ProjectContextMenuRegion(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: HeaderCard(
                                title: l10n.dashboardProjectsOverviewTitle,
                                margin: EdgeInsets.zero,
                                child: const _ProjectsOverviewContent(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: HeaderCard(
                                title: l10n.dashboardSizeOverviewTitle,
                                margin: EdgeInsets.zero,
                                child: const _SizeOverviewContent(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 1,
                              child: HeaderCard(
                                title: l10n.dashboardLanguageDistributionTitle,
                                margin: EdgeInsets.zero,
                                child: const _LanguageBreakdownSection(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: HeaderCard(
                                title: l10n.dashboardFrameworkDistributionTitle,
                                margin: EdgeInsets.zero,
                                child: const _FrameworkBreakdownSection(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverPersistentHeader(
                  pinned: true,
                  delegate:
                      _SectionTitleDelegate(l10n.dashboardPinnedProjectsTitle),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 28),
                sliver: SliverToBoxAdapter(child: _PinnedProjectsSection()),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverPersistentHeader(
                  pinned: true,
                  delegate:
                      _SectionTitleDelegate(l10n.dashboardRecentlyOpenedTitle),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                sliver: SliverToBoxAdapter(child: _RecentlyOpenedSection()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectsOverviewContent extends StatelessObserverWidget {
  const _ProjectsOverviewContent();

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();
    final l10n = AppLocalizations.of(context)!;
    final projects = store.projects;
    final favouriteCount = projects.where((p) => p.favourite).length;
    final monorepoCount = projects.where((p) => p.monorepoTool != null).length;

    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: [
        _SummaryStat(label: l10n.statTotalLabel, value: '${projects.length}'),
        _SummaryStat(label: l10n.statPinnedLabel, value: '$favouriteCount'),
        _SummaryStat(label: l10n.statMonorepoLabel, value: '$monorepoCount'),
      ],
    );
  }
}

class _SizeOverviewContent extends StatelessObserverWidget {
  const _SizeOverviewContent();

  @override
  Widget build(BuildContext context) {
    final store = context.read<StorageStore>();
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _SummaryStat(
              label: l10n.statTotalLabel,
              value: formatBytes(store.totalBytes),
            ),
            _SummaryStat(
              label: l10n.statReclaimableLabel,
              value: formatBytes(store.cacheBytes),
              valueColor: ProjectSizeType.cache.color,
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Shows what cleaning up would actually do to the total, rather
        // than leaving "reclaimable" as an abstract number with nothing to
        // compare it against — same core/cache proportion bar Storage's
        // own header uses.
        SizeBar(
          coreBytes: store.coreBytes,
          cacheBytes: store.cacheBytes,
          totalBytes: store.totalBytes,
          height: 8,
        ),
      ],
    );
  }
}

// A fixed-height sticky header for a body section — stays pinned to the
// top of the viewport while that section's own content scrolls underneath
// it, rather than scrolling away with the rest of the section like a plain
// heading would.
class _SectionTitleDelegate extends SliverPersistentHeaderDelegate {
  _SectionTitleDelegate(this.title);

  final String title;

  static const _height = 44.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      // Opaque and matching the page background — this sits on top of the
      // section's own tiles as they scroll underneath it, so without this
      // it would read as transparent glass over whatever's currently
      // scrolled beneath.
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _SectionTitle(title),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionTitleDelegate oldDelegate) =>
      oldDelegate.title != title;
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: valueColor ?? colorScheme.onSurface,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }
}

class _PinnedProjectsSection extends StatelessObserverWidget {
  const _PinnedProjectsSection();

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();
    final favourites = store.projects.where((p) => p.favourite).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (favourites.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return _EmptyState(
        icon: CupertinoIcons.star,
        title: l10n.dashboardNoPinnedTitle,
        message: l10n.dashboardNoPinnedMessage,
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final project in favourites) _QuickLaunchTile(project: project),
      ],
    );
  }
}

// Reads ProjectRepo's own recently-opened-paths notifier directly rather
// than through ExplorerStore, since every place a project gets opened
// (this screen's own tiles, Explorer's rows, the project-details dialog,
// the right-click menu) needs to be able to record one — and a dialog
// route or context-menu overlay isn't necessarily a descendant of
// wherever ExplorerStore's own Provider is scoped, so it can't rely on
// context.read reaching it.
class _RecentlyOpenedSection extends StatelessObserverWidget {
  const _RecentlyOpenedSection();

  // ProjectRepo itself keeps a longer history (see _recentlyOpenedLimit) —
  // only the most recent handful are actually worth surfacing here.
  static const _maxShown = 6;

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();
    // Actually iterated here (in the enclosing Observer's own tracked
    // build(), not inside ValueListenableBuilder's nested callback below)
    // so this rebuilds once ExplorerStore's initial async loadProjects()
    // populates the list, and again whenever a recently-opened project's
    // own data changes (e.g. gets favourited) — merely holding a
    // reference to store.projects without reading its contents wouldn't
    // track either.
    final byPath = {
      for (final project in store.projects) project.path: project
    };

    return ValueListenableBuilder<int>(
      valueListenable: ProjectRepo.recentlyOpenedVersion,
      builder: (context, _, __) {
        final recent = [
          for (final path in ProjectRepo().getRecentlyOpenedProjectPaths())
            if (byPath[path] != null) byPath[path]!,
        ].take(_maxShown).toList();

        if (recent.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return _EmptyState(
            icon: CupertinoIcons.clock,
            title: l10n.dashboardNoRecentTitle,
            message: l10n.dashboardNoRecentMessage,
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final project in recent) _QuickLaunchTile(project: project),
          ],
        );
      },
    );
  }
}

const _distributionBarHeight = 8.0;
const _distributionBarMaxRows = 8;

class _LanguageBreakdownSection extends StatelessObserverWidget {
  const _LanguageBreakdownSection();

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();
    final counts = <ProjectLanguage, int>{};
    for (final project in store.projects) {
      counts.update(project.language, (n) => n + 1, ifAbsent: () => 1);
    }

    if (counts.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return _EmptyState(
        icon: CupertinoIcons.chart_bar,
        title: l10n.dashboardNoLanguagesTitle,
        message: l10n.dashboardNoLanguagesMessage,
      );
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = entries.take(_distributionBarMaxRows).toList();
    final maxCount = shown.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        for (final entry in shown)
          _DistributionBar(
            iconAsset: entry.key.iconAsset,
            fallbackIcon: CupertinoIcons.chevron_left_slash_chevron_right,
            label: entry.key.label,
            count: entry.value,
            fraction: entry.value / maxCount,
          ),
      ],
    );
  }
}

// Only counts projects with a detected framework — a plain-language
// project (no framework layered on top) isn't a meaningful "framework"
// category of its own, so it's left out rather than lumped under a
// generic "None" bar.
class _FrameworkBreakdownSection extends StatelessObserverWidget {
  const _FrameworkBreakdownSection();

  @override
  Widget build(BuildContext context) {
    final store = context.read<ExplorerStore>();
    final counts = <ProjectFramework, int>{};
    for (final project in store.projects) {
      final framework = project.framework;
      if (framework != null) {
        counts.update(framework, (n) => n + 1, ifAbsent: () => 1);
      }
    }

    if (counts.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return _EmptyState(
        icon: CupertinoIcons.square_stack_3d_up,
        title: l10n.dashboardNoFrameworksTitle,
        message: l10n.dashboardNoFrameworksMessage,
      );
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = entries.take(_distributionBarMaxRows).toList();
    final maxCount = shown.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        for (final entry in shown)
          _DistributionBar(
            iconAsset: entry.key.iconAsset,
            fallbackIcon: CupertinoIcons.app_badge,
            label: entry.key.label,
            count: entry.value,
            fraction: entry.value / maxCount,
          ),
      ],
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.iconAsset,
    required this.fallbackIcon,
    required this.label,
    required this.count,
    required this.fraction,
  });

  final String? iconAsset;
  final IconData fallbackIcon;
  final String label;
  final int count;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: iconAsset != null
                    ? Image.asset(iconAsset!)
                    : Icon(
                        fallbackIcon,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_distributionBarHeight / 2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: _distributionBarHeight,
              backgroundColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

const _tileWidth = 240.0;
const _tileHeight = 64.0;
const _tileIconSize = 36.0;

class _QuickLaunchTile extends StatefulWidget {
  const _QuickLaunchTile({required this.project});

  final ProjectModel project;

  @override
  State<_QuickLaunchTile> createState() => _QuickLaunchTileState();
}

class _QuickLaunchTileState extends State<_QuickLaunchTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: _tileWidth,
      height: _tileHeight,
      child: GestureDetector(
        onSecondaryTapUp: (details) =>
            showProjectContextMenu(context, project, details.globalPosition),
        child: Material(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => ProjectRepo().openInEditor(project),
            onDoubleTap: () => showProjectDetailsDialog(context, project),
            onHover: (hovering) => setState(() => _hovering = hovering),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  ProjectIcon(iconPath: project.iconPath, size: _tileIconSize),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        _hovering
                            ? Text(
                                AppLocalizations.of(context)!.openInIdeLabel(
                                  ProjectRepo().resolveIde(project).label,
                                ),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      fontSize: 11,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                              )
                            : ProjectLanguageBadge(
                                language: project.language,
                                framework: project.framework,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
