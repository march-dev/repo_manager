import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

/// How the header's own collapse (see _collapseScrollThreshold) is
/// decided — scroll-driven by default, or pinned one way or the other via
/// the header's own toggle. Persisted (see ProjectRepo.getDashboardHeaderMode)
/// so a manual choice survives restarting the app.
enum DashboardHeaderMode { auto, expanded, collapsed }

/// The app's landing tab — a quick summary of everything Explorer/Storage
/// have found, and a one-tap launcher for whatever's been starred as a
/// favourite there or opened recently. Reads ExplorerStore/StorageStore
/// rather than owning its own copies of the project list/size data (see
/// _RootScaffold, which provides both above this screen and Explorer's/
/// Storage's own), so starring a project or cleaning up cache stays in
/// sync between screens instantly.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// A small threshold (rather than pixels > 0) so a tiny overscroll bounce at
// rest doesn't flicker the header between states.
const _collapseScrollThreshold = 8.0;

class _DashboardScreenState extends State<DashboardScreen> {
  // What the last scroll notification would decide on its own — only
  // actually used while _mode is DashboardHeaderMode.auto; kept tracking
  // regardless of mode so switching back to auto reflects the current
  // scroll position immediately rather than whatever it was when auto was
  // last active.
  bool _scrolledCollapsed = false;

  DashboardHeaderMode _mode = DashboardHeaderMode.auto;

  @override
  void initState() {
    super.initState();
    _mode = ProjectRepo().getDashboardHeaderMode();
  }

  bool get _collapsed => switch (_mode) {
        DashboardHeaderMode.auto => _scrolledCollapsed,
        DashboardHeaderMode.expanded => false,
        DashboardHeaderMode.collapsed => true,
      };

  void _setMode(DashboardHeaderMode mode) {
    setState(() => _mode = mode);
    ProjectRepo().setDashboardHeaderMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _DashboardHeader(
              collapsed: _collapsed,
              mode: _mode,
              onModeChanged: _setMode,
            ),
            Expanded(
              // Wraps the whole scrollable body so any tile's right-click
              // menu has somewhere to open into — see showProjectContextMenu.
              // The NotificationListener drives the header's own collapse —
              // simpler than plumbing a ScrollController down into
              // _DashboardBody just to read its offset back out.
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  final collapsed =
                      notification.metrics.pixels > _collapseScrollThreshold;
                  if (collapsed != _scrolledCollapsed) {
                    setState(() => _scrolledCollapsed = collapsed);
                  }
                  return false;
                },
                child: const ProjectContextMenuRegion(child: _DashboardBody()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessObserverWidget {
  const _DashboardHeader({
    required this.collapsed,
    required this.mode,
    required this.onModeChanged,
  });

  final bool collapsed;
  final DashboardHeaderMode mode;
  final ValueChanged<DashboardHeaderMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final explorerStore = context.read<ExplorerStore>();
    final storageStore = context.read<StorageStore>();
    final projects = explorerStore.projects;
    final favouriteCount = projects.where((p) => p.favourite).length;
    final monorepoCount = projects.where((p) => p.monorepoTool != null).length;
    final colorScheme = Theme.of(context).colorScheme;

    final statsGroups = [
      _StatGroup(
        title: 'Projects',
        child: Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _SummaryStat(label: 'Total', value: '${projects.length}'),
            _SummaryStat(label: 'Pinned', value: '$favouriteCount'),
            _SummaryStat(label: 'Monorepos', value: '$monorepoCount'),
          ],
        ),
      ),
      _StatGroup(
        title: 'Size',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _SummaryStat(
                  label: 'Total',
                  value: formatBytes(storageStore.totalBytes),
                ),
                _SummaryStat(
                  label: 'Reclaimable',
                  value: formatBytes(storageStore.cacheBytes),
                  valueColor: ProjectSizeType.cache.color,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Shows what cleaning up would actually do to the total,
            // rather than leaving "reclaimable" as an abstract number with
            // nothing to compare it against — same core/cache proportion
            // bar Storage's own header uses.
            SizeBar(
              coreBytes: storageStore.coreBytes,
              cacheBytes: storageStore.cacheBytes,
              totalBytes: storageStore.totalBytes,
              height: 8,
            ),
          ],
        ),
      ),
    ];

    return HeaderCard(
      title: 'Dashboard',
      actions: [
        _HeaderModeSelector(
          mode: mode,
          collapsed: collapsed,
          onChanged: onModeChanged,
        ),
      ],
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: collapsed
            // Scrolled past the top — a single compact row of the raw
            // numbers, no group titles/divider, no charts/distributions
            // (the same ones a scroll is presumably trying to get past in
            // the first place) and no SizeBar, which needs more width
            // than a single-line row leaves it.
            ? Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  _SummaryStat(label: 'Projects', value: '${projects.length}'),
                  _SummaryStat(label: 'Pinned', value: '$favouriteCount'),
                  _SummaryStat(label: 'Monorepos', value: '$monorepoCount'),
                  _SummaryStat(
                    label: 'Total Size',
                    value: formatBytes(storageStore.totalBytes),
                  ),
                  _SummaryStat(
                    label: 'Reclaimable',
                    value: formatBytes(storageStore.cacheBytes),
                    valueColor: ProjectSizeType.cache.color,
                  ),
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          statsGroups[0],
                          // Divider's own height is its full allotted
                          // vertical space (the line sits centered within
                          // it), so this alone guarantees a minimum gap on
                          // both sides — unlike relying only on
                          // spaceBetween, which only adds slack when the
                          // column is stretched taller than its content.
                          Divider(
                            height: 41,
                            color: colorScheme.outlineVariant,
                          ),
                          statsGroups[1],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    VerticalDivider(
                        width: 1, color: colorScheme.outlineVariant),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _StatGroup(
                            title: 'Language Distribution',
                            child: _LanguageBreakdownSection(),
                          ),
                          const SizedBox(height: 20),
                          Divider(
                            height: 1,
                            color: colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 20),
                          const _StatGroup(
                            title: 'Framework Distribution',
                            child: _FrameworkBreakdownSection(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// Cycles auto -> expanded -> collapsed -> auto on tap; the icon/tooltip
// always reflects the *current* mode (matching e.g. Explorer's own
// pin-favourites toggle), not the action a tap would perform.
// Cycles auto -> auto (peeked open) -> expanded -> collapsed -> auto on
// tap. The first tap while on auto only peeks — it doesn't touch the
// persisted mode, and scrolling at all cancels it on its own (see
// _DashboardScreenState's NotificationListener); a second tap while
// still peeked commits to persisted "expanded" instead.
// Every state directly selectable in one tap (matches Explorer's own
// grouping control) rather than encoding all three in a single icon
// button's tap-count/tooltip — easier to read at a glance than a cycling
// toggle, at the cost of a little more width in the header.
// Two controls: a plain "Auto" toggle, and a single button covering both
// forced states — its icon/action always reflects whatever the header is
// NOT currently showing, so one tap flips straight to the opposite forced
// state (leaving auto if that was active) instead of needing separate
// "always expanded"/"always collapsed" buttons.
class _HeaderModeSelector extends StatelessWidget {
  const _HeaderModeSelector({
    required this.mode,
    required this.collapsed,
    required this.onChanged,
  });

  final DashboardHeaderMode mode;
  final bool collapsed;
  final ValueChanged<DashboardHeaderMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final autoSelected = mode == DashboardHeaderMode.auto;
    final dimColor = colorScheme.onSurface.withValues(alpha: 0.5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Auto — follows scroll',
          icon: Icon(
            Icons.sync,
            size: 18,
            color: autoSelected ? colorScheme.onSurface : dimColor,
          ),
          onPressed: () => onChanged(DashboardHeaderMode.auto),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: collapsed ? 'Always expanded' : 'Always collapsed',
          icon: Icon(
            collapsed ? Icons.unfold_more : Icons.unfold_less,
            size: 18,
            color: autoSelected ? dimColor : colorScheme.onSurface,
          ),
          onPressed: () => onChanged(
            collapsed
                ? DashboardHeaderMode.expanded
                : DashboardHeaderMode.collapsed,
          ),
        ),
      ],
    );
  }
}

// The header's shared "small muted uppercase label + content" block — used
// for the stats groups (Projects/Size) as well as the Language/Framework
// Distribution sections, so every cluster in the header reads as the same
// kind of thing rather than stats using one title style and distributions
// another.
class _StatGroup extends StatelessWidget {
  const _StatGroup({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _tileHorizontalInset),
            child: _SectionTitle('Pinned Projects'),
          ),
          SizedBox(height: 12),
          _PinnedProjectsSection(),
          SizedBox(height: 28),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _tileHorizontalInset),
            child: _SectionTitle('Recently Opened'),
          ),
          SizedBox(height: 12),
          _RecentlyOpenedSection(),
        ],
      ),
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
      style: TextStyle(
        fontWeight: FontWeight.w600,
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
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: _tileHorizontalInset),
        child: _EmptyState(
          icon: CupertinoIcons.star,
          title: 'No pinned projects yet',
          message:
              'Star a project in Explorer to pin it here for quick launch.',
        ),
      );
    }

    // A tile's own card border sits flush at the section's edge, but its
    // content is already inset from that border by its own padding (see
    // _QuickLaunchTile) — without matching that here, the tiles' cards
    // read as flush against the page edge while every other section's
    // *text* reads as inset from it. Adding the same amount here keeps
    // the row's visual weight balanced with the rest of the page instead
    // of looking edge-to-edge.
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
        ];

        if (recent.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: _tileHorizontalInset),
            child: _EmptyState(
              icon: CupertinoIcons.clock,
              title: 'Nothing opened yet',
              message: 'Projects you open show up here for quick relaunch.',
            ),
          );
        }

        // Same reasoning as _PinnedProjectsSection: this leading/trailing
        // inset matches _QuickLaunchTile's own internal padding, so the
        // first/last card in this horizontally-scrolling row doesn't read
        // as flush against the page edge the way a tile's own bare border
        // otherwise would.
        return SizedBox(
          height: _tileHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _QuickLaunchTile(project: recent[index]),
          ),
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
      return const _EmptyState(
        icon: CupertinoIcons.chart_bar,
        title: 'Nothing to break down yet',
        message: 'Add a directory in Settings to start finding projects.',
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
      return const _EmptyState(
        icon: CupertinoIcons.square_stack_3d_up,
        title: 'No frameworks detected yet',
        message: 'Projects built on a recognised framework show up here.',
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
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
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
            style: TextStyle(
              fontSize: 12,
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
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(message, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

const _tileWidth = 240.0;
const _tileHeight = 64.0;
const _tileIconSize = 36.0;

// Matches _QuickLaunchTile's own internal horizontal padding — see
// _PinnedProjectsSection/_RecentlyOpenedSection.
const _tileHorizontalInset = 12.0;

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
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        _hovering
                            ? Text(
                                'Open in ${ProjectRepo().resolveIde(project).label}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
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
