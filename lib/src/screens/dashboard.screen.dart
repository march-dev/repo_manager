import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// The cards scroll away with the rest of the page (Recently Opened/
/// Pinned Projects) rather than staying pinned above it; only the section
/// titles below them stay pinned, as sticky sliver headers. Recently
/// Opened comes first and pages through its (already small — see
/// DashboardState._maxRecentlyOpened) handful of projects a single row
/// at a time, via prev/next arrows in its own title row, rather than
/// wrapping to a second row; Pinned Projects can grow much larger, so it
/// gets the page's remaining space as a wrapping grid instead.
class DashboardScreen extends StatelessWidget {
  // _RootScaffold keeps every screen mounted at once (an IndexedStack, not
  // a Navigator swap — see its own doc), so a plain `autofocus: true`
  // here would compete with every other IndexedStack sibling for focus
  // the moment the app launches, regardless of which tab is actually
  // visible. [selected] — whether this is the currently-visible tab, from
  // _RootScaffold's own _selectedIndex — lets _Scaffold claim/release
  // focus only when it's actually true, so F5 refreshes this screen only
  // while looking at it.
  const DashboardScreen({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return _Scaffold(selected: selected);
  }
}

class _Scaffold extends StatefulWidget {
  const _Scaffold({required this.selected});

  final bool selected;

  @override
  State<_Scaffold> createState() => _ScaffoldState();
}

class _ScaffoldState extends State<_Scaffold> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.selected) _focusNode.requestFocus();
  }

  @override
  void didUpdateWidget(_Scaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) {
      _focusNode.requestFocus();
    } else if (!widget.selected && oldWidget.selected) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Dashboard has no project list/size data of its own — every card here
  // is derived straight from ExplorerState/StorageState (see this file's
  // own top doc) — so its own F5 refresh means refreshing both of those
  // rather than something Dashboard-specific. No visible button for this
  // yet (unlike Explorer/Storage's own header refresh button), just F5.
  void _refreshAll(BuildContext context) {
    context.read<ExplorerState>().refreshAll();
    context.read<StorageState>().refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.f5): () => _refreshAll(context),
      },
      // CallbackShortcuts only intercepts key events reaching a focused
      // descendant — this Focus's own requestFocus()/unfocus() calls
      // above are what keep that descendant correct as the tab is
      // switched to/away from, rather than a one-shot autofocus.
      child: Focus(
        focusNode: _focusNode,
        child: AppScaffold(
          // Wraps the whole scrollable page so any tile's right-click menu
          // has somewhere to open into — see showProjectContextMenu.
          body: ContextMenuRegion(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSizes.spacing16),
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
                              infoHeader:
                                  l10n.dashboardRecognisedLanguagesHeader,
                              infoItems: [
                                for (final language in ProjectLanguage.values)
                                  (
                                    iconAsset: language.iconAsset,
                                    label: language.label,
                                  ),
                              ],
                              child: const _LanguageBreakdownSection(),
                            ),
                            _SummaryCard(
                              flex: 1,
                              title: l10n.dashboardFrameworkDistributionTitle,
                              infoHeader:
                                  l10n.dashboardRecognisedFrameworksHeader,
                              infoItems: [
                                for (final framework in ProjectFramework.values)
                                  (
                                    iconAsset: framework.iconAsset,
                                    label: framework.label,
                                  ),
                              ],
                              child: const _FrameworkBreakdownSection(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                const _RecentlyOpenedSection(),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing16),
                  sliver: SliverPersistentHeader(
                    pinned: true,
                    delegate: PinnedSectionHeaderDelegate(
                      child: _SectionTitle(l10n.dashboardPinnedProjectsTitle),
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      AppSizes.spacing16,
                      AppSizes.spacing12,
                      AppSizes.spacing16,
                      AppSizes.spacing16),
                  sliver: SliverToBoxAdapter(child: _PinnedProjectsSection()),
                ),
              ],
            ),
          ),
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

// A recognised language/framework entry in an _InfoPopover's chip grid —
// iconAsset is nullable (AssetOrFallbackIcon's own contract) even though
// every current ProjectLanguage/ProjectFramework value happens to have
// one, since that's not guaranteed to stay true as either enum grows.
typedef _LabeledIcon = ({String? iconAsset, String label});

/// One card in a [_SummaryCardRow] — the flex share of its row, its
/// [HeaderCard] title (and optional trailing info icon, e.g. the
/// Language/Framework cards' "what does this app recognise" popover —
/// see [infoHeader]/[infoItems]), and its own content widget.
class _SummaryCard {
  const _SummaryCard({
    required this.flex,
    required this.title,
    required this.child,
    this.infoHeader,
    this.infoItems,
  });

  final int flex;
  final String title;
  final Widget child;

  /// Both null together, or both given together — see [_InfoPopover].
  final String? infoHeader;
  final List<_LabeledIcon>? infoItems;
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
                actions: [
                  if (cards[i].infoItems != null)
                    _InfoPopover(
                      header: cards[i].infoHeader!,
                      items: cards[i].infoItems!,
                    ),
                ],
                child: cards[i].child,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Each item's own slot width in _InfoPopover's grid — fixed, rather than
// sized to its label, so Wrap can safely fit a known number per row
// (two, at this width) without any single item ever being able to push
// the popover wider than intended; a label too long for it just
// ellipsizes instead. Wide enough that the longest label across both
// lists ("Unreal Engine") prints in full rather than ellipsizing.
const _infoPopoverItemWidth = 104.0;

// _InfoPopover's own Container needs an explicit width, not just its
// children's intrinsic sizing — an OverlayPortal's overlay content is
// laid out against the whole Overlay's (screen-sized) constraints, not
// this card's, so an unconstrained Wrap in there would keep packing
// items onto one row until it ran out of *screen* width rather than
// wrapping into a tidy 2-column grid; explicitly sizing this to fit
// exactly _infoPopoverItemWidth twice is what actually forces that.
//
// The +4 is deliberate slack, not decoration — content width works out
// to exactly _infoPopoverItemWidth * 2 + spacing8 without it, and Wrap
// needs a next item to strictly fit to keep it on the same row; with
// zero margin, any sub-pixel rounding tips the second column onto its
// own row instead, collapsing this back to one column.
const _infoPopoverWidth =
    _infoPopoverItemWidth * 2 + AppSizes.spacing8 + AppSizes.spacing12 * 2 + 4;

/// A small "(i)" icon baked directly into a [HeaderCard]'s title row —
/// hovering it shows [items] as a 2-column icon+label grid, via
/// [HoverPopover] rather than Flutter's own [Tooltip] (which only ever
/// renders plain text, too cramped for a full list of icons/names).
///
/// Each item sits in its own fixed-[_infoPopoverItemWidth] slot (rather
/// than a plain [Wrap] of intrinsically-sized chips, or one item per row)
/// — the former lets a long label like "Unreal Engine" push past the
/// popover's own width uncontrolled; the latter keeps the popover narrow
/// but makes it tall enough (13-16 rows, for every ProjectLanguage/
/// ProjectFramework value) to become its own problem. Fixed-width slots
/// bound both dimensions at once: width can't be exceeded (a long label
/// just ellipsizes), and two per row roughly halves the height a single
/// column would need.
class _InfoPopover extends StatelessWidget {
  const _InfoPopover({required this.header, required this.items});

  final String header;
  final List<_LabeledIcon> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HoverPopover(
      popoverBuilder: (context) => Container(
        width: _infoPopoverWidth,
        padding: const EdgeInsets.all(AppSizes.spacing12),
        // Same surface this app's context menus use (see
        // compactMenuStyle/menuBorderColor in context_menu.dart) — reads
        // as another one of the app's own floating panels rather than a
        // one-off popover style.
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          border: Border.all(color: menuBorderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              header,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: AppSizes.spacing8),
            Wrap(
              spacing: AppSizes.spacing8,
              runSpacing: AppSizes.spacing6,
              children: [
                for (final item in items)
                  SizedBox(
                    width: _infoPopoverItemWidth,
                    child: Row(
                      children: [
                        AssetOrFallbackIcon(
                          iconAsset: item.iconAsset,
                          fallbackIcon: CupertinoIcons.app,
                          size: AppSizes.iconXSmall,
                        ),
                        const SizedBox(width: AppSizes.spacing4),
                        Expanded(
                          child: Text(
                            item.label,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      child: Icon(
        CupertinoIcons.info_circle,
        size: AppSizes.iconMedium,
        color: colorScheme.onSurface.withValues(alpha: 0.5),
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
      // The section title above sits 12px further in than this content
      // area's own padding, via PinnedSectionHeaderDelegate's default
      // padding — matched here so the placeholder's text lines up with
      // the title's, rather than the tiles' own (unpadded-to-match) left
      // edge.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing12),
        child: EmptyPlaceholder(
          icon: CupertinoIcons.star,
          title: l10n.dashboardNoPinnedTitle,
          message: l10n.dashboardNoPinnedMessage,
        ),
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

// A source row's own fixed content shape — reused by both the tile-count
// computation and the page layout below, so the two can never disagree
// about how wide a "page" of tiles is.
const _recentTileWidth = 240.0;
const _recentTileSpacing = AppSizes.spacing12;

/// Recently Opened's own title row + content, as a single sliver — a
/// [SliverMainAxisGroup] rather than two separate entries in
/// [DashboardScreen]'s sliver list, since the prev/next arrows in the
/// (pinned) title row and the page of tiles below them share this widget's
/// page-index state.
class _RecentlyOpenedSection extends StatefulWidget {
  const _RecentlyOpenedSection();

  @override
  State<_RecentlyOpenedSection> createState() => _RecentlyOpenedSectionState();
}

class _RecentlyOpenedSectionState extends State<_RecentlyOpenedSection> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    setState(() => _page = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<DashboardState>();
    final collectionsState = context.read<CollectionsState>();
    final actions = context.read<ProjectActionsState>();
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<int>(
      // DashboardState.recentlyOpened depends on ProjectActionsState's
      // recently-opened-paths notifier, which isn't itself a MobX
      // observable — this is what actually triggers a rebuild whenever a
      // project gets (re)opened anywhere (this screen's own tiles,
      // Explorer's rows, the project-details dialog, the right-click
      // menu).
      valueListenable: state.recentlyOpenedVersion,
      builder: (context, _, __) {
        // state.recentlyOpened also cross-references DashboardState's own
        // (MobX) `projects` list — a path recorded as opened before
        // Explorer's scan had actually found it yet is otherwise silently
        // dropped from `recent` until *something* rebuilds this again, and
        // without Observer here that "something" was only ever the next
        // hot reload, not the scan actually finishing.
        return Observer(
          builder: (context) {
            final recent = state.recentlyOpened;

            // SliverLayoutBuilder rather than a plain LayoutBuilder — this
            // widget is itself a sliver (see the class doc comment), so it
            // only ever gets SliverConstraints, not the BoxConstraints a
            // regular LayoutBuilder needs.
            return SliverLayoutBuilder(
              builder: (context, sliverConstraints) {
                // Matches the content SliverPadding's own horizontal inset
                // below, so this predicts the exact width tiles will actually
                // have to lay out in.
                final contentWidth =
                    sliverConstraints.crossAxisExtent - AppSizes.spacing16 * 2;
                final perPage = recent.isEmpty
                    ? 1
                    : ((contentWidth + _recentTileSpacing) /
                            (_recentTileWidth + _recentTileSpacing))
                        .floor()
                        .clamp(1, recent.length);
                final pageCount =
                    recent.isEmpty ? 1 : (recent.length / perPage).ceil();
                final page = _page.clamp(0, pageCount - 1);

                // Whatever's left over after perPage's whole tiles — rather
                // than sit empty, it shows a sliver of the next tile clipped
                // to fit, hinting there's more to page to. Below
                // _minPeekWidth it'd be too thin a hint to read as a card at
                // all, so it's left empty instead.
                const minPeekWidth = 24.0;
                final usedWidth = perPage * _recentTileWidth +
                    (perPage - 1) * _recentTileSpacing;
                final peekWidth =
                    (contentWidth - usedWidth - _recentTileSpacing)
                        .clamp(0.0, _recentTileWidth);

                return SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacing16,
                      ),
                      sliver: SliverPersistentHeader(
                        pinned: true,
                        delegate: PinnedSectionHeaderDelegate(
                          // Only the left inset matches the title text below
                          // (see _PinnedProjectsSection's placeholder comment)
                          // — the arrows are their own trailing edge, so they
                          // sit flush against the section's own right padding
                          // instead of adding another gap after them.
                          padding: const EdgeInsets.only(
                            left: AppSizes.spacing12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _SectionTitle(
                                  l10n.dashboardRecentlyOpenedTitle,
                                ),
                              ),
                              // Hidden rather than merely disabled once
                              // everything already fits on one page — with
                              // nothing to page through, arrows here would
                              // just be visual noise.
                              if (pageCount > 1) ...[
                                _PageArrowButton(
                                  icon: CupertinoIcons.chevron_left,
                                  onPressed: page > 0
                                      ? () => _goToPage(page - 1)
                                      : null,
                                ),
                                const SizedBox(width: AppSizes.spacing4),
                                _PageArrowButton(
                                  icon: CupertinoIcons.chevron_right,
                                  onPressed: page < pageCount - 1
                                      ? () => _goToPage(page + 1)
                                      : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.spacing16,
                        AppSizes.spacing8,
                        AppSizes.spacing16,
                        AppSizes.spacing12,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: recent.isEmpty
                            // Matches _PinnedProjectsSection's own placeholder
                            // padding — see its comment for why.
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.spacing12,
                                ),
                                child: EmptyPlaceholder(
                                  icon: CupertinoIcons.clock,
                                  title: l10n.dashboardNoRecentTitle,
                                  message: l10n.dashboardNoRecentMessage,
                                ),
                              )
                            : SizedBox(
                                height: 64,
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: pageCount,
                                  onPageChanged: (i) =>
                                      setState(() => _page = i),
                                  itemBuilder: (context, pageIndex) {
                                    final start = pageIndex * perPage;
                                    final end = (start + perPage)
                                        .clamp(0, recent.length);
                                    final hasPeek = end < recent.length &&
                                        peekWidth >= minPeekWidth;

                                    return Row(
                                      children: [
                                        for (var i = start; i < end; i++) ...[
                                          if (i > start)
                                            const SizedBox(
                                              width: _recentTileSpacing,
                                            ),
                                          QuickLaunchTile(
                                            project: recent[i],
                                            collectionsState: collectionsState,
                                            actions: actions,
                                          ),
                                        ],
                                        if (hasPeek) ...[
                                          const SizedBox(
                                            width: _recentTileSpacing,
                                          ),
                                          _PeekTile(
                                            width: peekWidth,
                                            project: recent[end],
                                            collectionsState: collectionsState,
                                            actions: actions,
                                            onTap: () =>
                                                _goToPage(pageIndex + 1),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

/// A clipped sliver of the next page's first tile, shown in whatever
/// leftover width a page didn't need for its own whole tiles — a hint
/// that there's more to page to, beyond what [_PageArrowButton] alone
/// (easy to miss up in the title row) already offers. Purely a visual
/// hint and a shortcut to the next page: [QuickLaunchTile]'s own
/// tap/hover handling is suppressed (via [IgnorePointer]) since only part
/// of it is ever visible here, and [onTap] pages forward instead of
/// opening the barely-visible project underneath.
class _PeekTile extends StatelessWidget {
  const _PeekTile({
    required this.width,
    required this.project,
    required this.collectionsState,
    required this.actions,
    required this.onTap,
  });

  final double width;
  final ProjectModel project;
  final CollectionsState collectionsState;
  final ProjectActionsState actions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: width,
        height: 64,
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          maxWidth: _recentTileWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: IgnorePointer(
              child: QuickLaunchTile(
                project: project,
                collectionsState: collectionsState,
                actions: actions,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small, compact prev/next control for [_RecentlyOpenedSection]'s title
/// row — fades out (via [CircleIconButton]'s own disabled styling) at
/// whichever end of the page range it's currently on.
class _PageArrowButton extends StatelessWidget {
  const _PageArrowButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      size: 32,
      backgroundColor: Colors.transparent,
      color: Theme.of(context).colorScheme.onSurface,
      onPressed: onPressed,
      icon: Icon(icon, size: AppSizes.iconMedium),
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
