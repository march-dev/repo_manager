import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

/// The app's landing tab — a quick summary of everything Explorer/Storage
/// have found, and a one-tap launcher for whatever's been starred as a
/// favourite there or opened recently. Reads [DashboardState], which is
/// itself purely derived from ExplorerState/StorageState (see
/// _RootScaffold, which provides all three above this screen and
/// Explorer's/Storage's own), so starring a project or cleaning up cache
/// stays in sync between screens instantly.
///
/// The summary lives in four independent cards (Projects/Size overview,
/// Language/Framework distribution) rather than one combined header — each
/// reads only the state it needs, and there's no longer a page title above
/// them, since the nav rail already shows Dashboard as the selected tab.
/// The cards scroll away with the rest of the page (Pinned Projects/
/// Recently Opened) rather than staying pinned above it; only the section
/// titles below them stay pinned, as sticky sliver headers.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      // Wraps the whole scrollable page so any tile's right-click menu
      // has somewhere to open into — see showProjectContextMenu.
      body: ContextMenuRegion(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.spacing16,
                AppSizes.spacing16,
                AppSizes.spacing16,
                AppSizes.spacing20,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    _SummaryCardRow(
                      cards: [
                        _SummaryCard(
                          flex: 2,
                          title: l10n.dashboardProjectsOverviewTitle,
                          child: const _ProjectsOverviewContent(),
                        ),
                        _SummaryCard(
                          flex: 3,
                          title: l10n.dashboardSizeOverviewTitle,
                          child: const _SizeOverviewContent(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacing12),
                    _SummaryCardRow(
                      cards: [
                        _SummaryCard(
                          flex: 1,
                          title: l10n.dashboardLanguageDistributionTitle,
                          child: const _LanguageBreakdownSection(),
                        ),
                        _SummaryCard(
                          flex: 1,
                          title: l10n.dashboardFrameworkDistributionTitle,
                          child: const _FrameworkBreakdownSection(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
              sliver: SliverPersistentHeader(
                pinned: true,
                delegate: PinnedSectionHeaderDelegate(
                  child: _SectionTitle(l10n.dashboardPinnedProjectsTitle),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(AppSizes.spacing16,
                  AppSizes.spacing12, AppSizes.spacing16, 28),
              sliver: SliverToBoxAdapter(child: _PinnedProjectsSection()),
            ),
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
              sliver: SliverPersistentHeader(
                pinned: true,
                delegate: PinnedSectionHeaderDelegate(
                  child: _SectionTitle(l10n.dashboardRecentlyOpenedTitle),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(AppSizes.spacing16,
                  AppSizes.spacing12, AppSizes.spacing16, AppSizes.spacing16),
              sliver: SliverToBoxAdapter(child: _RecentlyOpenedSection()),
            ),
          ],
        ),
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
      style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }
}

/// One card in a [_SummaryCardRow] — the flex share of its row, its
/// [HeaderCard] title, and its own content widget.
class _SummaryCard {
  const _SummaryCard({
    required this.flex,
    required this.title,
    required this.child,
  });

  final int flex;
  final String title;
  final Widget child;
}

/// A row of equal-height [HeaderCard]s (the top-of-page summary cards),
/// each sized by its own [_SummaryCard.flex].
class _SummaryCardRow extends StatelessWidget {
  const _SummaryCardRow({required this.cards});

  final List<_SummaryCard> cards;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSizes.spacing12),
            Expanded(
              flex: cards[i].flex,
              child: HeaderCard(
                title: cards[i].title,
                margin: EdgeInsets.zero,
                child: cards[i].child,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectsOverviewContent extends StatelessObserverWidget {
  const _ProjectsOverviewContent();

  @override
  Widget build(BuildContext context) {
    final state = context.read<DashboardState>();
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: [
        StatText(label: l10n.statTotalLabel, value: '${state.projects.length}'),
        StatText(label: l10n.statPinnedLabel, value: '${state.favouriteCount}'),
        StatText(
          label: l10n.statMonorepoLabel,
          value: '${state.monorepoCount}',
        ),
      ],
    );
  }
}

class _SizeOverviewContent extends StatelessObserverWidget {
  const _SizeOverviewContent();

  @override
  Widget build(BuildContext context) {
    final state = context.read<DashboardState>();
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            StatText(
              label: l10n.statTotalLabel,
              value: formatBytes(state.totalBytes),
            ),
            StatText(
              label: l10n.statReclaimableLabel,
              value: formatBytes(state.cacheBytes),
              valueColor: ProjectSizeType.cache.color,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacing10),
        // Shows what cleaning up would actually do to the total, rather
        // than leaving "reclaimable" as an abstract number with nothing to
        // compare it against — same core/cache proportion bar Storage's
        // own header uses.
        SizeBar(
          leftValue: state.coreBytes,
          rightValue: state.cacheBytes,
          totalValue: state.totalBytes,
          leftColor: ProjectSizeType.core.color,
          rightColor: ProjectSizeType.cache.color,
          height: 8,
        ),
      ],
    );
  }
}

class _PinnedProjectsSection extends StatelessObserverWidget {
  const _PinnedProjectsSection();

  @override
  Widget build(BuildContext context) {
    final state = context.read<DashboardState>();
    final collectionsState = context.read<CollectionsState>();
    final actions = context.read<ProjectActionsState>();
    final favourites = state.pinnedProjects;

    if (favourites.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return EmptyPlaceholder(
        icon: CupertinoIcons.star,
        title: l10n.dashboardNoPinnedTitle,
        message: l10n.dashboardNoPinnedMessage,
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final project in favourites)
          QuickLaunchTile(
            project: project,
            collectionsState: collectionsState,
            actions: actions,
          ),
      ],
    );
  }
}

class _RecentlyOpenedSection extends StatelessObserverWidget {
  const _RecentlyOpenedSection();

  @override
  Widget build(BuildContext context) {
    final state = context.read<DashboardState>();
    final collectionsState = context.read<CollectionsState>();
    final actions = context.read<ProjectActionsState>();

    return ValueListenableBuilder<int>(
      // DashboardState.recentlyOpened depends on ProjectActionsState's
      // recently-opened-paths notifier, which isn't itself a MobX
      // observable — this is what actually triggers a rebuild whenever a
      // project gets (re)opened anywhere (this screen's own tiles,
      // Explorer's rows, the project-details dialog, the right-click
      // menu).
      valueListenable: state.recentlyOpenedVersion,
      builder: (context, _, __) {
        final recent = state.recentlyOpened;

        if (recent.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return EmptyPlaceholder(
            icon: CupertinoIcons.clock,
            title: l10n.dashboardNoRecentTitle,
            message: l10n.dashboardNoRecentMessage,
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final project in recent)
              QuickLaunchTile(
                project: project,
                collectionsState: collectionsState,
                actions: actions,
              ),
          ],
        );
      },
    );
  }
}

class _LanguageBreakdownSection extends StatelessObserverWidget {
  const _LanguageBreakdownSection();

  @override
  Widget build(BuildContext context) {
    final state = context.read<DashboardState>();
    final l10n = AppLocalizations.of(context)!;

    return RankedBreakdownList(
      counts: state.languageCounts,
      iconAssetOf: (language) => language.iconAsset,
      fallbackIcon: CupertinoIcons.chevron_left_slash_chevron_right,
      labelOf: (language) => language.label,
      emptyIcon: CupertinoIcons.chart_bar,
      emptyTitle: l10n.dashboardNoLanguagesTitle,
      emptyMessage: l10n.dashboardNoLanguagesMessage,
    );
  }
}

class _FrameworkBreakdownSection extends StatelessObserverWidget {
  const _FrameworkBreakdownSection();

  @override
  Widget build(BuildContext context) {
    final state = context.read<DashboardState>();
    final l10n = AppLocalizations.of(context)!;

    return RankedBreakdownList(
      counts: state.frameworkCounts,
      iconAssetOf: (framework) => framework.iconAsset,
      fallbackIcon: CupertinoIcons.app_badge,
      labelOf: (framework) => framework.label,
      emptyIcon: CupertinoIcons.square_stack_3d_up,
      emptyTitle: l10n.dashboardNoFrameworksTitle,
      emptyMessage: l10n.dashboardNoFrameworksMessage,
    );
  }
}
