import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

/// Shows a project's details as a full-screen page — its own row (same as
/// Explorer's), a separate General/Internal Projects/Git tab switcher card,
/// and whichever tab's own content below that: General is a scrollable
/// column of cards (the language/framework composition breakdown, then
/// storage size), Internal Projects is a single card holding the
/// member-package tree for a monorepo (or a "nothing here" placeholder
/// otherwise), and Git is a single card holding a placeholder for now —
/// pushed on top of the whole app (rail included, replaced here by a
/// single rail-styled back button) rather than a modal, so there's room
/// for all of that without it feeling cramped into a dialog.
Future<void> showProjectDetailsPage(
  BuildContext context,
  ProjectModel project, {
  required CollectionsState collectionsState,
  required ProjectActionsState actions,
  // Only known/passed when [project] was reached by drilling into another
  // project's own Internal Projects tree — the root of the workspace
  // that drill-down came from, shown in the Other Info card as this
  // project's "Workspace Root" when [project] is itself a workspace
  // member (see ProjectModel.workspaceTool's own doc). Null for every
  // other way this page gets opened (Explorer/Dashboard/a right-click
  // menu's own "View Details", all direct opens with no such context in
  // scope) — this app has no reverse lookup from an arbitrary project
  // back to whichever root's subPackages tree contains it, so those
  // opens simply don't know the root and the Other Info card leaves that
  // field out rather than guessing.
  ProjectModel? owningProject,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ProjectDetailsPage(
        project: project,
        collectionsState: collectionsState,
        actions: actions,
        owningProject: owningProject,
      ),
    ),
  );
}

class ProjectDetailsPage extends StatelessWidget {
  const ProjectDetailsPage({
    super.key,
    required this.project,
    required this.collectionsState,
    required this.actions,
    this.owningProject,
  });

  final ProjectModel project;
  // A pushed MaterialPageRoute becomes a new sibling route in the same
  // Navigator's Overlay, not a descendant of whichever Provider-reachable
  // screen pushed it — so, same as the dialog this replaced, it can't
  // reach these via context.read and needs them passed in explicitly.
  final CollectionsState collectionsState;
  final ProjectActionsState actions;

  // See showProjectDetailsPage's own doc.
  final ProjectModel? owningProject;

  @override
  Widget build(BuildContext context) {
    return Provider<ProjectDetailsState>(
      create: (_) => ProjectDetailsState(
        initialProject: project,
        actions: actions,
        owningProject: owningProject,
      ),
      child: _ProjectDetailsView(
        collectionsState: collectionsState,
        actions: actions,
      ),
    );
  }
}

// Just wires up the page's own keyboard shortcuts/focus scope and hands
// off to _PageScaffold for everything actually on screen — kept shallow
// deliberately, rather than nesting the whole page's layout (rail, cards,
// tab content) inside one build() method.
class _ProjectDetailsView extends StatelessWidget {
  const _ProjectDetailsView({
    required this.collectionsState,
    required this.actions,
  });

  final CollectionsState collectionsState;
  final ProjectActionsState actions;

  @override
  Widget build(BuildContext context) {
    final state = context.read<ProjectDetailsState>();

    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
        // Same F5-refreshes-the-current-screen convention Explorer/
        // Storage/Dashboard already use — refreshEverything() is this
        // page's one refresh action (size + language/framework
        // composition + subpackages together), same as its own header
        // button already triggers.
        LogicalKeySet(LogicalKeyboardKey.f5): state.refreshEverything,
      },
      // CallbackShortcuts only intercepts key events reaching a focused
      // descendant — without this, Escape wouldn't do anything unless
      // some other focusable widget already held focus.
      child: Focus(
        autofocus: true,
        child: _PageScaffold(
          state: state,
          actions: actions,
          collectionsState: collectionsState,
        ),
      ),
    );
  }
}

// The page's actual chrome — the back rail beside the scrollable content
// column. Split out from _ProjectDetailsView so each build() method here
// only has to reason about one layer of the page at a time.
class _PageScaffold extends StatelessWidget {
  const _PageScaffold({
    required this.state,
    required this.actions,
    required this.collectionsState,
  });

  final ProjectDetailsState state;
  final ProjectActionsState actions;
  final CollectionsState collectionsState;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // ContextMenuRegion wraps everything below so any row's right-click
      // menu (project or folder) has somewhere to open into — see
      // showProjectContextMenu/showFolderContextMenu.
      body: ContextMenuRegion(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BackRail(onTap: () => Navigator.of(context).pop()),
            Expanded(
              child: _ContentColumn(
                state: state,
                actions: actions,
                collectionsState: collectionsState,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Same rail-shaped shell/pill item the real nav rail uses (see
// RailContainer/RailItem) — a single, always-unselected "Back" entry
// rather than the full rail, since this page replaces it entirely while
// open.
class _BackRail extends StatelessWidget {
  const _BackRail({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RailContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing12),
        child: RailItem(
          icon: Icons.arrow_back,
          selectedIcon: Icons.arrow_back,
          label: l10n.projectDetailsBackTooltip,
          selected: false,
          onTap: onTap,
        ),
      ),
    );
  }
}

// The page's own top-to-bottom card stack — project summary, the tab
// switcher, then whichever tab's content. A StatelessObserverWidget of
// its own (rather than _ProjectDetailsView reading state.project itself)
// since that's the only observable actually read on this page's outer
// layers — see _ProjectSummaryCard, which needs the current [project]
// to redraw when favouriting/a background rescan changes it.
class _ContentColumn extends StatelessObserverWidget {
  const _ContentColumn({
    required this.state,
    required this.actions,
    required this.collectionsState,
  });

  final ProjectDetailsState state;
  final ProjectActionsState actions;
  final CollectionsState collectionsState;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSizes.spacing16),
        _ProjectSummaryCard(
          project: state.project,
          actions: actions,
          notInstalledIdes: state.notInstalledIdes,
          collectionsState: collectionsState,
          onToggleFavourite: state.toggleOwnFavourite,
          // Same reasoning as the Internal Projects tree rows' own
          // removed favourite button — a member project
          // (state.owningProject != null, see its own doc) isn't
          // something you'd favourite on its own the way a real
          // top-level project is.
          showFavourite: state.owningProject == null,
        ),
        _TabsCard(state: state),
        Expanded(
          child: _TabContent(
            state: state,
            actions: actions,
            collectionsState: collectionsState,
          ),
        ),
      ],
    );
  }
}

// The project summary row's own card shell — split out from
// _ProjectSummaryRow itself so a caller doesn't have to know it needs
// wrapping in an AppCard with this specific margin/padding/clip, the same
// way _TabsCard already wraps _TabHeaderRow.
class _ProjectSummaryCard extends StatelessWidget {
  const _ProjectSummaryCard({
    required this.project,
    required this.actions,
    required this.notInstalledIdes,
    required this.collectionsState,
    required this.onToggleFavourite,
    required this.showFavourite,
  });

  final ProjectModel project;
  final ProjectActionsState actions;
  final Set<Ide> notInstalledIdes;
  final CollectionsState collectionsState;
  final VoidCallback onToggleFavourite;
  final bool showFavourite;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: _cardMargin,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: _ProjectSummaryRow(
        project: project,
        actions: actions,
        notInstalledIdes: notInstalledIdes,
        collectionsState: collectionsState,
        onToggleFavourite: onToggleFavourite,
        showFavourite: showFavourite,
      ),
    );
  }
}

// Every card below the page's own top (project summary) card uses top:0
// so adjacent cards read as one consistent AppSizes.spacing16 rhythm
// rather than doubling up — the same margin TableCard already hardcodes
// for itself.
const _cardMargin = EdgeInsets.fromLTRB(
  AppSizes.spacing16,
  0,
  AppSizes.spacing16,
  AppSizes.spacing16,
);

// The project's own identity row — icon, name, language/monorepo badge —
// built from the exact same ProjectRow content widget Explorer's own
// table rows use, wrapped in the same HoverableRow shell (hover/tap/
// secondary-tap) rather than a bespoke header layout, so this reads and
// behaves like any other project row in the app: tap opens it in its
// resolved IDE, right-click gets the full context menu (Open With,
// Collections, ...), and the trailing favourite star is visible the same
// way Explorer's own action column is — except for a member project (see
// [showFavourite]), which has no favourite star here any more than it
// does in its own Internal Projects tree row.
class _ProjectSummaryRow extends StatelessWidget {
  const _ProjectSummaryRow({
    required this.project,
    required this.actions,
    required this.notInstalledIdes,
    required this.collectionsState,
    required this.onToggleFavourite,
    required this.showFavourite,
  });

  final ProjectModel project;
  final ProjectActionsState actions;
  final Set<Ide> notInstalledIdes;
  final CollectionsState collectionsState;
  final VoidCallback onToggleFavourite;

  // False for a project reached by drilling into another project's
  // Internal Projects tree — see _ContentColumn's own call site.
  final bool showFavourite;

  @override
  Widget build(BuildContext context) {
    // Null when nothing installed can actually open this project (see
    // IdeLauncherRepo.resolveInstalledIde's own doc) — the row then shows
    // no hover hint and ignores a tap, rather than promising an IDE
    // tapping it won't actually reach.
    final resolvedIde = actions.resolveInstalledIde(project, notInstalledIdes);

    return HoverableRow(
      height: AppSizes.rowHeight,
      onTap: resolvedIde == null ? null : () => actions.openInEditor(project),
      onSecondaryTapUp: (context, position) => showProjectContextMenu(
        context,
        project,
        position,
        collectionsState: collectionsState,
        actions: actions,
        // This row already *is* the project's own View Details page —
        // offering it again here would just reopen this same page on
        // top of itself.
        showViewDetails: false,
      ),
      // Left padding only — ProjectRow's own trailing gap (below) already
      // provides a matching margin on the right; padding both sides here
      // too would double up into a noticeably wider empty gap after the
      // favourite button than before the icon.
      builder: (context, isHovered) => Padding(
        padding: const EdgeInsets.only(left: AppSizes.spacing16),
        child: ProjectRow(
          project: project,
          trailingGap: AppSizes.spacing6,
          trailing: _SummaryRowTrailing(
            project: project,
            resolvedIde: resolvedIde,
            isHovered: isHovered,
            showFavourite: showFavourite,
            onToggleFavourite: onToggleFavourite,
          ),
        ),
      ),
    );
  }
}

// The summary row's own trailing cluster — the hover-only "Open In" hint,
// then the favourite star — split out so _ProjectSummaryRow's own
// build() doesn't have to nest through it just to reach ProjectRow's own
// trailing slot.
class _SummaryRowTrailing extends StatelessWidget {
  const _SummaryRowTrailing({
    required this.project,
    required this.resolvedIde,
    required this.isHovered,
    required this.showFavourite,
    required this.onToggleFavourite,
  });

  final ProjectModel project;

  // Null when nothing installed can actually open this project — see
  // _ProjectSummaryRow's own doc.
  final Ide? resolvedIde;

  final bool isHovered;
  final bool showFavourite;
  final VoidCallback onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isHovered && resolvedIde != null) ...[
          OpenInHint(ide: resolvedIde!),
          const SizedBox(width: AppSizes.spacing12),
        ],
        if (showFavourite)
          ProjectFavouriteButton(
            project: project,
            size: AppSizes.actionColumnSize,
            onPressed: onToggleFavourite,
          ),
      ],
    );
  }
}

// A StatelessObserverWidget of its own (rather than relying on
// _ProjectDetailsView's own Observer cascading a rebuild down to this)
// — same reasoning as _TabsCard/_TabContent: state.languageComposition/
// frameworkComposition need to be read inside some Observer's own
// tracked build call to react at all, not merely handed a `state`
// reference that happens to also get rebuilt for other reasons.
class _CompositionRow extends StatelessObserverWidget {
  const _CompositionRow({required this.state});

  final ProjectDetailsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final frameworks = state.frameworkComposition;
    final frameworksLoading =
        state.frameworkCompositionLoading || state.refreshing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _CompositionCard(
            title: l10n.projectDetailsLanguageCompositionTitle,
            info: l10n.projectDetailsLanguageCompositionInfo,
            // A real filesystem walk — worth a loading indicator in place
            // of the bar/legend for however long that takes, on the very
            // first load and again on every
            // ProjectDetailsState.refreshEverything() rescan, rather than
            // silently popping the real numbers in over whatever was
            // there before (or the "nothing to break down yet" empty
            // state, on a first load that hasn't resolved yet at all).
            loading: state.languageCompositionLoading || state.refreshing,
            child: CompositionBar<ProjectLanguage>(
              counts: state.languageComposition,
              colorOf: (language) => language.color,
              labelOf: (language) => language.label,
              emptyIcon: CupertinoIcons.chart_bar,
              emptyTitle: l10n.projectDetailsNoLanguagesTitle,
              emptyMessage: l10n.projectDetailsNoLanguagesMessage,
            ),
          ),
        ),
        // Shown once loading while there's still a chance this tree has a
        // framework somewhere in it, or once loaded and it actually does
        // — a plain collection of Dart/Java/... packages with no
        // framework anywhere still has nothing to break down here, so
        // hide it again rather than leave a confirmed-empty card up.
        if (frameworksLoading || frameworks.isNotEmpty) ...[
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child: _CompositionCard(
              title: l10n.projectDetailsFrameworkCompositionTitle,
              info: l10n.projectDetailsFrameworkCompositionInfo,
              loading: frameworksLoading,
              child: CompositionBar<ProjectFramework>(
                counts: frameworks,
                colorOf: (framework) => framework.color,
                labelOf: (framework) => framework.label,
                emptyIcon: CupertinoIcons.square_stack_3d_up,
                emptyTitle: l10n.projectDetailsNoFrameworksTitle,
                emptyMessage: l10n.projectDetailsNoFrameworksMessage,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CompositionCard extends StatelessWidget {
  const _CompositionCard({
    required this.title,
    required this.info,
    required this.child,
    this.loading = false,
  });

  final String title;

  // Shown in a HoverPopover behind an info icon next to the title — same
  // "(i)" pattern dashboard.screen.dart's own _InfoPopover uses for its
  // Language/Framework Distribution cards, just a plain sentence here
  // instead of that one's icon+label chip grid.
  final String info;
  final Widget child;

  // True while whatever [child] would otherwise chart is still being
  // gathered — a filesystem walk for Language Composition, the
  // subPackages tree still loading/rescanning for Framework Composition
  // — see _CompositionRow's own doc for each card's exact condition.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompositionCardHeader(title: title, info: info),
          const SizedBox(height: AppSizes.spacing8),
          // In place of the real chart (left untouched — see [child])
          // while [loading] — rather than a spinner replacing the whole
          // card's content, a skeleton shaped like the real thing (the
          // bar, plus a couple of fake legend rows) so this reads as
          // "the same chart, just not ready yet" rather than a completely
          // different loading affordance. Only the chart shimmers — the
          // title above is real, static content, not a placeholder.
          if (loading) const _CompositionLoadingChart() else child,
        ],
      ),
    );
  }
}

class _CompositionCardHeader extends StatelessWidget {
  const _CompositionCardHeader({required this.title, required this.info});

  final String title;

  // Shown in a HoverPopover behind an info icon next to the title — same
  // "(i)" pattern dashboard.screen.dart's own _InfoPopover uses for its
  // Language/Framework Distribution cards, just a plain sentence here
  // instead of that one's icon+label chip grid.
  final String info;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(width: AppSizes.spacing6),
        _DescriptionPopover(description: info),
      ],
    );
  }
}

class _CompositionLoadingChart extends StatelessWidget {
  const _CompositionLoadingChart();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompositionLoadingBar(),
        SizedBox(height: AppSizes.spacing12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendEntrySkeleton(width: 70),
            SizedBox(width: AppSizes.spacing12),
            _LegendEntrySkeleton(width: 56),
          ],
        ),
      ],
    );
  }
}

class _CompositionLoadingBar extends StatelessWidget {
  const _CompositionLoadingBar();

  static const _barHeight = 10.0;
  static const _outerHeight = _barHeight + SizeBar.framePadding * 2;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      // The inner DecoratedBox has no child/intrinsic size of its own —
      // without forcing this outer Container's width explicitly, it (and
      // everything inside it) collapses to a sliver instead of filling
      // the card, the same way an un-stretched Column child would.
      width: double.infinity,
      height: _outerHeight,
      padding: const EdgeInsets.all(SizeBar.framePadding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(_outerHeight / 2),
      ),
      child: Shimmer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.onSurface,
            borderRadius: BorderRadius.circular(_barHeight / 2),
          ),
        ),
      ),
    );
  }
}

// Mimics one real legend row from composition_bar.dart's own
// _LegendEntry — a dot plus a name/percentage label — but as shimmering
// placeholder shapes instead of real data, at a fixed [width] per entry
// (real labels vary in length; this just needs to read as "a legend row
// is coming", not match any specific language's own name).
class _LegendEntrySkeleton extends StatelessWidget {
  const _LegendEntrySkeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shimmer(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.onSurface,
              shape: BoxShape.circle,
            ),
            child: const SizedBox(width: 10, height: 10),
          ),
          const SizedBox(width: AppSizes.spacing6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.onSurface,
              borderRadius: BorderRadius.circular(AppSizes.spacing4),
            ),
            child: SizedBox(width: width, height: 12),
          ),
        ],
      ),
    );
  }
}

// A small "(i)" icon — hovering it shows [description] in a floating
// panel, via HoverPopover, the same way dashboard.screen.dart's own
// _InfoPopover explains its Language/Framework Distribution cards.
class _DescriptionPopover extends StatelessWidget {
  const _DescriptionPopover({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return HoverPopover(
      popoverBuilder: (context) => Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.all(AppSizes.spacing12),
        // Same floating-panel surface this app's context menus/dashboard's
        // own info popover use, so this reads as another one of the app's
        // own panels rather than a one-off style.
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          border: Border.all(color: menuBorderColor),
        ),
        child: Text(
          description,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
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

class _StorageSection extends StatelessWidget {
  const _StorageSection({
    required this.size,
    required this.loading,
    required this.cleaning,
    required this.onCleanup,
    required this.refreshing,
    required this.onRefresh,
  });

  final ProjectSizeModel? size;
  final bool loading;
  final bool cleaning;
  final VoidCallback onCleanup;
  // This page's one refresh action (size + subpackages together) lives
  // here rather than up in the project summary row, since this card is
  // the one actually showing numbers that go stale. Distinct from
  // [loading] — see ProjectDetailsState.refreshing's own doc.
  final bool refreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = this.size;
    final total = size?.totalBytes ?? 0;
    final core = size?.baseBytes ?? 0;
    final cache = size?.cacheBytes ?? 0;

    return HeaderCard(
      margin: _cardMargin,
      title: l10n.projectDetailsStorageSectionTitle,
      actions: [
        Text(
          l10n.storageTotalLabel(formatBytes(total)),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
        RefreshIconButton(
          refreshing: refreshing,
          onPressed: onRefresh,
          tooltip: l10n.storageRefreshTooltip,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizeBar(
            leftValue: core,
            rightValue: cache,
            totalValue: total,
            leftColor: ProjectSizeType.core.color,
            rightColor: ProjectSizeType.cache.color,
            height: 14,
          ),
          const SizedBox(height: AppSizes.spacing12),
          Row(
            children: [
              SizeSummary(
                label: l10n.storageCoreLabel,
                bytes: core,
                color: ProjectSizeType.core.color,
                // Matches CompositionBar's own legend dot size above, so
                // both legends on this page read as one visual language.
                dotSize: 10,
              ),
              const SizedBox(width: AppSizes.spacing16),
              SizeSummary(
                label: l10n.storageCacheLabel,
                bytes: cache,
                color: ProjectSizeType.cache.color,
                dotSize: 10,
              ),
              const Spacer(),
              if (cache > 0)
                PrimaryButton(
                  loading: cleaning,
                  // Sizes mid-recompute means the cache/core split shown
                  // right now may already be stale, and cleaning would
                  // race that refresh's own filesystem walk — block it
                  // until that settles.
                  disabled: loading,
                  onPressed: onCleanup,
                  backgroundColor: ProjectSizeType.cache.color,
                  foregroundColor: Colors.black,
                  icon: const Icon(CupertinoIcons.trash,
                      size: AppSizes.iconMedium),
                  label: Text(l10n.projectDetailsCleanButton),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// The page's own General/Internal Projects/Git tab switcher, in its own
// card directly under the project summary card — a StatelessObserverWidget
// of its own (rather than a plain StatelessWidget reading `state` handed
// down from _ProjectDetailsView's own Observer) since state.tab isn't read
// anywhere in _ProjectDetailsView's own build(); without this, switching
// tabs wouldn't highlight the newly-selected one at all — MobX only reacts
// to an observable actually being read inside some Observer's own tracked
// call, not merely handed to it as a value.
class _TabsCard extends StatelessObserverWidget {
  const _TabsCard({required this.state});

  final ProjectDetailsState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: _cardMargin,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: _TabHeaderRow(tab: state.tab, onChanged: state.setTab),
    );
  }
}

// Whichever tab is selected fills the rest of the page below _TabsCard —
// General is a scrollable column of cards (see _GeneralTabContent);
// Internal Projects/Git are each a single card of their own, same reasons
// as _TabsCard for being its own StatelessObserverWidget rather than a
// plain StatelessWidget.
class _TabContent extends StatelessObserverWidget {
  const _TabContent({
    required this.state,
    required this.actions,
    required this.collectionsState,
  });

  final ProjectDetailsState state;
  final ProjectActionsState actions;
  final CollectionsState collectionsState;

  @override
  Widget build(BuildContext context) {
    return switch (state.tab) {
      ProjectDetailsTab.general => _GeneralTabContent(
          state: state,
          collectionsState: collectionsState,
        ),
      ProjectDetailsTab.subpackages => AppCard(
          margin: _cardMargin,
          padding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: state.isMonorepo
              ? _MonorepoTree(
                  state: state,
                  actions: actions,
                  collectionsState: collectionsState,
                )
              : const _NoInternalProjectsPlaceholder(),
        ),
      ProjectDetailsTab.git => const AppCard(
          margin: _cardMargin,
          padding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: _GitPlaceholder(),
        ),
    };
  }
}

// General tab's own content — this page's "about the project as a whole"
// cards (info, composition breakdown, then storage size) stacked in a
// scrollable column, rather than always being visible above the tab
// switcher the way they used to be. A StatelessObserverWidget of its own
// so state.size/sizeLoading/cleaning/refreshing (read directly here for
// _StorageSection, which is itself a plain StatelessWidget) actually
// react — same reasoning as _TabsCard/_TabContent.
class _GeneralTabContent extends StatelessObserverWidget {
  const _GeneralTabContent({
    required this.state,
    required this.collectionsState,
  });

  final ProjectDetailsState state;
  final CollectionsState collectionsState;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _CompositionSection(state: state),
          _StorageSection(
            size: state.size,
            loading: state.sizeLoading,
            cleaning: state.cleaning,
            onCleanup: state.cleanup,
            refreshing: state.refreshing,
            onRefresh: state.refreshEverything,
          ),
          _OtherInfoCard(
            project: state.project,
            owningProject: state.owningProject,
            collectionsState: collectionsState,
          ),
        ],
      ),
    );
  }
}

// Just the composition row's own margin/IntrinsicHeight wrapper, split
// out so _GeneralTabContent's own build() doesn't have to nest through
// it to reach _CompositionRow.
class _CompositionSection extends StatelessWidget {
  const _CompositionSection({required this.state});

  final ProjectDetailsState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _cardMargin,
      child: IntrinsicHeight(child: _CompositionRow(state: state)),
    );
  }
}

// General tab's own "about this project" card — its full path (selectable,
// so it can be copied) and which collections it's currently in, if any.
// A StatelessObserverWidget of its own — collectionsState.
// getProjectCollections is a plain method, not itself observable, so
// reading collectionsState.membershipVersion here (see its own doc) is
// what actually makes this react to a collection being toggled elsewhere
// (e.g. via this same project's right-click menu) while this card is on
// screen; without it, this would only ever show membership as of first
// build.
class _OtherInfoCard extends StatelessObserverWidget {
  const _OtherInfoCard({
    required this.project,
    required this.owningProject,
    required this.collectionsState,
  });

  final ProjectModel project;

  // See showProjectDetailsPage's own doc — only known when this page was
  // reached by drilling into another project's Internal Projects tree.
  final ProjectModel? owningProject;

  final CollectionsState collectionsState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Read purely to establish the MobX dependency — see this class's own
    // doc, same reasoning as ExplorerState.groupedByCollection.
    collectionsState.membershipVersion;
    final collections = collectionsState.getProjectCollections(project.path);
    // MonorepoBadge's own text style — every plain PillBadge on this card
    // (Workspace Root, each collection) is styled to match it, so they
    // all read as one consistent visual language.
    final badgeTextStyle = Theme.of(context).textTheme.labelLarge!.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        );

    return AppCard(
      margin: _cardMargin,
      padding: const EdgeInsets.all(AppSizes.spacing16),
      child: Column(
        // stretch, not start — none of this Column's own children (Text,
        // LabeledField, ...) claim the full available width themselves
        // the way e.g. _CompositionCard's title Row does, so a Column
        // shrink-wraps to its widest child's own natural width by
        // default, leaving the card narrower than the card next to it
        // rather than filling it. Each child still reads left-aligned —
        // stretch only widens the box each one is given, not how it
        // aligns its own content within that box.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.projectDetailsOtherInfoTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          // Only when this project is itself a member of some *outer*
          // workspace — distinct from project.monorepoTool (a workspace
          // this project manages, shown via the row's own MonorepoBadge
          // instead), see ProjectModel.workspaceTool's own doc.
          if (project.workspaceTool case final workspaceTool?) ...[
            const SizedBox(height: AppSizes.spacing12),
            _WorkspaceRow(
              workspaceTool: workspaceTool,
              owningProject: owningProject,
              badgeTextStyle: badgeTextStyle,
            ),
          ],
          // Hidden rather than showing an explicit "not in any collection"
          // message — same convention Framework Composition's own card
          // uses for hiding itself when there's nothing to report, rather
          // than every possible field always being visible.
          if (collections.isNotEmpty) ...[
            const SizedBox(height: AppSizes.spacing12),
            LabeledField(
              label: l10n.collectionsLabel,
              child: _CollectionBadges(
                collections: collections,
                style: badgeTextStyle,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.spacing12),
          LabeledField(
            label: l10n.pathLabel,
            child: _PathText(project: project),
          ),
        ],
      ),
    );
  }
}

// The Workspace Tool/Workspace Root pair — split out from _OtherInfoCard
// so that card's own build() doesn't have to nest through a Row+Expanded
// pair just to reach these two fields.
class _WorkspaceRow extends StatelessWidget {
  const _WorkspaceRow({
    required this.workspaceTool,
    required this.owningProject,
    required this.badgeTextStyle,
  });

  final MonorepoTool workspaceTool;

  // See _OtherInfoCard.owningProject's own doc for why this isn't always
  // known.
  final ProjectModel? owningProject;
  final TextStyle badgeTextStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LabeledField(
            label: l10n.projectDetailsWorkspaceToolLabel,
            child: MonorepoBadge(tool: workspaceTool, count: null),
          ),
        ),
        if (owningProject case final owningProject?) ...[
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: LabeledField(
              label: l10n.projectDetailsWorkspaceRootLabel,
              // Plain PillBadge, not MonorepoBadge — this names a project,
              // not a MonorepoTool — but styled to match it exactly (see
              // badgeTextStyle) so the two badges in this row read as one
              // consistent visual language.
              child: PillBadge(
                // owningProject is exactly the project whose tree this
                // page was drilled into from (see its own doc) — that
                // page is already the previous route on the stack, so
                // popping back to it is correct rather than pushing a
                // second, identical page on top.
                onTap: () => Navigator.of(context).pop(),
                child: Text(owningProject.name, style: badgeTextStyle),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Every collection [collections] names, as a PillBadge each — split out
// from _OtherInfoCard so that card's own build() doesn't have to nest
// through a Wrap of however many collections just to reach LabeledField's
// own child slot.
class _CollectionBadges extends StatelessWidget {
  const _CollectionBadges({required this.collections, required this.style});

  final List<String> collections;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.spacing8,
      runSpacing: AppSizes.spacing8,
      children: [
        for (final collection in collections)
          PillBadge(child: Text(collection, style: style)),
      ],
    );
  }
}

// project.path with its project.sourceDir prefix (the configured search
// directory it was found under) shaded, so the part that's actually this
// project's own — everything after that prefix — reads as the visually
// prominent part of the path instead of the whole string competing
// equally for attention.
class _PathText extends StatelessWidget {
  const _PathText({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium!;
    final shadedStyle = style.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
    );
    final path = project.path;
    final sourceDir = project.sourceDir;

    // Falls back to the whole path in its normal colour if it doesn't
    // actually start with sourceDir (shouldn't happen, but a path that
    // can't be split this way is still fully readable this way rather
    // than silently dropping part of it).
    if (!path.startsWith(sourceDir)) {
      return SelectableText(path, style: style);
    }

    return SelectableText.rich(
      TextSpan(
        children: [
          TextSpan(text: sourceDir, style: shadedStyle),
          TextSpan(text: path.substring(sourceDir.length), style: style),
        ],
      ),
    );
  }
}

// A full-width tab switcher — each tab an InkWell filling an equal share
// of the header's own space, rather than a compact segmented control
// sitting off to one side with empty header space next to it.
class _TabHeaderRow extends StatelessWidget {
  const _TabHeaderRow({required this.tab, required this.onChanged});

  final ProjectDetailsTab tab;
  final ValueChanged<ProjectDetailsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TableHeaderRow(
      children: [
        Expanded(
          child: _TabHeaderButton(
            label: l10n.projectDetailsGeneralTab,
            selected: tab == ProjectDetailsTab.general,
            onTap: () => onChanged(ProjectDetailsTab.general),
          ),
        ),
        Expanded(
          child: _TabHeaderButton(
            label: l10n.projectDetailsInternalProjectsTab,
            selected: tab == ProjectDetailsTab.subpackages,
            onTap: () => onChanged(ProjectDetailsTab.subpackages),
          ),
        ),
        Expanded(
          child: _TabHeaderButton(
            label: l10n.projectDetailsGitTab,
            selected: tab == ProjectDetailsTab.git,
            onTap: () => onChanged(ProjectDetailsTab.git),
          ),
        ),
      ],
    );
  }
}

class _TabHeaderButton extends StatelessWidget {
  const _TabHeaderButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.secondaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: selected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ),
      ),
    );
  }
}

class _GitPlaceholder extends StatelessWidget {
  const _GitPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: EmptyPlaceholder(
        icon: CupertinoIcons.arrow_branch,
        title: l10n.projectDetailsGitPlaceholderTitle,
        message: l10n.comingSoonMessage,
        centered: true,
      ),
    );
  }
}

// Shown in place of the member-package tree for a plain, non-monorepo
// project — there's nothing to browse, so this replaces the tree with an
// explicit "nothing here" message instead of an empty table.
class _NoInternalProjectsPlaceholder extends StatelessWidget {
  const _NoInternalProjectsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: EmptyPlaceholder(
        icon: CupertinoIcons.cube_box,
        title: l10n.projectDetailsNoInternalProjectsTitle,
        message: l10n.projectDetailsNoInternalProjectsMessage,
        centered: true,
      ),
    );
  }
}

// The sort header + scrollable member-package tree shown for a monorepo
// project — a loading spinner in place of the tree until its subpackages
// (cached or freshly scanned) are known. Owns its own ScrollController
// (like TableCard does) rather than the page above threading one down,
// since nothing outside this widget needs it. Sits directly inside the
// Internal Projects tab's own AppCard (see _TabContent) — no nested card
// of its own (that's what a TableCard would add here, redundant since the
// outer card already provides the rounded/margined shell).
class _MonorepoTree extends StatefulWidget {
  const _MonorepoTree({
    required this.state,
    required this.actions,
    required this.collectionsState,
  });

  final ProjectDetailsState state;
  final ProjectActionsState actions;
  final CollectionsState collectionsState;

  @override
  State<_MonorepoTree> createState() => _MonorepoTreeState();
}

class _MonorepoTreeState extends State<_MonorepoTree> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A State (unlike StatelessObserverWidget) has no automatic Observer
    // of its own — without wrapping the actual reads below, changing
    // sortAscending/expanded/project wouldn't trigger a rebuild here at
    // all, since nothing would be subscribed to them.
    return Observer(
      builder: (context) {
        final state = widget.state;
        final project = state.project;
        final zebra = _ZebraCounter();
        final rows = _buildRows(
          context: context,
          state: state,
          actions: widget.actions,
          collectionsState: widget.collectionsState,
          entries: project.subPackages,
          depth: 0,
          zebra: zebra,
        );

        return Column(
          children: [
            _TreeHeaderRow(
              ascending: state.sortAscending,
              onToggle: state.toggleSort,
            ),
            const HairlineDivider(),
            Expanded(
              child: _TreeListArea(
                loaded: project.subPackagesLoaded,
                rows: rows,
                scrollController: _scrollController,
              ),
            ),
          ],
        );
      },
    );
  }
}

// The tree's own sortable "Name" header — split out so
// _MonorepoTreeState's own build() doesn't have to nest through a
// TableHeaderRow+Expanded pair just to reach it.
class _TreeHeaderRow extends StatelessWidget {
  const _TreeHeaderRow({required this.ascending, required this.onToggle});

  // A resolved value, not the raw ProjectDetailsState — this widget isn't
  // itself reactive, so reading state.sortAscending directly here
  // wouldn't do anything when it changes; _MonorepoTreeState's own
  // Observer already reads it (via state.sorted()) to build the rows
  // this header sits above, and hands the current value down instead.
  final bool ascending;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TableHeaderRow(
      // Matches _TreeRowContent's own depth-0 offset before its title
      // (padding + chevron slot + icon slot + gap — see its own layout),
      // so "Name" lines up with a row's actual title text rather than its
      // reserved chevron/icon slots.
      padding: const EdgeInsets.only(
        left: AppSizes.spacing16 * 2 +
            AppSizes.spacing20 +
            AppSizes.spacing6 +
            AppSizes.rowIconSize,
      ),
      children: [
        Expanded(
          child: HeaderSortableButton(
            text: AppLocalizations.of(context)!.nameColumnHeader,
            ascending: ascending,
            onChanged: (_) => onToggle(),
          ),
        ),
      ],
    );
  }
}

// Either the tree's own scrollable rows, or a loading spinner while
// [loaded] is still false — split out so _MonorepoTreeState's own
// build() doesn't have to nest through the Scrollbar/ListView pair (or
// the ternary picking between that and the spinner) itself.
class _TreeListArea extends StatelessWidget {
  const _TreeListArea({
    required this.loaded,
    required this.rows,
    required this.scrollController,
  });

  final bool loaded;
  final List<Widget> rows;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const _TreeLoadingSkeleton();

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: ListView(controller: scrollController, children: rows),
    );
  }
}

// A handful of shimmering placeholder rows, shaped like the real tree's
// own rows (an icon, a name) — same "skeleton shaped like the real
// thing" convention project_details.screen.dart's own composition cards
// use while loading, rather than a plain spinner unrelated to what's
// about to appear.
class _TreeLoadingSkeleton extends StatelessWidget {
  const _TreeLoadingSkeleton();

  // Varied so the skeleton doesn't read as one repeated row — same reason
  // _LegendEntrySkeleton uses two different widths rather than one.
  static const _nameWidths = [180.0, 140.0, 200.0, 120.0, 160.0, 130.0];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final width in _nameWidths) _TreeRowSkeleton(nameWidth: width),
      ],
    );
  }
}

class _TreeRowSkeleton extends StatelessWidget {
  const _TreeRowSkeleton({required this.nameWidth});

  final double nameWidth;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      height: AppSizes.rowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
        child: Row(
          children: [
            Shimmer(
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const SizedBox(
                  width: AppSizes.rowIconSize,
                  height: AppSizes.rowIconSize,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            Shimmer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSizes.spacing4),
                ),
                child: SizedBox(width: nameWidth, height: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A running index across the *whole* flattened tree (not reset per
// level), so alternating row shading reads the same way AppTable's own
// zebra striping does — continuous down the visible list, regardless of
// how deep any particular row is nested. A tiny mutable counter (rather
// than threading an updated index through every recursive call's return
// value) reset fresh at the start of each build.
class _ZebraCounter {
  var _index = 0;

  bool next() {
    final isOdd = _index.isOdd;
    _index++;
    return isOdd;
  }
}

List<Widget> _buildRows({
  required BuildContext context,
  required ProjectDetailsState state,
  required ProjectActionsState actions,
  required CollectionsState collectionsState,
  required List<WorkspaceEntry> entries,
  required int depth,
  required _ZebraCounter zebra,
}) {
  final rows = <Widget>[];
  for (final entry in state.sorted(entries)) {
    final expanded = state.expanded.contains(entry.path);
    final isZebra = zebra.next();

    switch (entry) {
      case WorkspaceProjectEntry(:final project):
        final hasChildren = project.subPackages.isNotEmpty;
        // Null when nothing installed can actually open this project (see
        // IdeLauncherRepo.resolveInstalledIde's own doc) — the row then
        // shows no hover hint and ignores a tap, rather than promising an
        // IDE tapping it won't actually reach.
        final resolvedIde = actions.resolveInstalledIde(
          project,
          state.notInstalledIdes,
        );
        rows.add(
          _SubPackageRow(
            zebra: isZebra,
            depth: depth,
            icon: ProjectIcon(
                iconPath: project.iconPath, size: AppSizes.rowIconSize),
            title: project.name,
            subtitle: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProjectLanguageBadge(
                  language: project.language,
                  framework: project.framework,
                ),
                if (project.workspaceTool case final workspaceTool?) ...[
                  const SizedBox(width: AppSizes.spacing6),
                  MonorepoBadge(tool: workspaceTool, count: null),
                ],
              ],
            ),
            ide: resolvedIde,
            expandable: hasChildren,
            expanded: expanded,
            onToggle:
                hasChildren ? () => state.toggleExpanded(entry.path) : null,
            onTap: resolvedIde == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    actions.openInEditor(project);
                  },
            // Same drill-down double-tap as Explorer's own project rows
            // (see showProjectDetailsPage's other call sites) — pushes a
            // fresh page for this member on top of the current one,
            // rather than popping it, so the outer tree stays put
            // underneath.
            onDoubleTap: () => showProjectDetailsPage(
              context,
              project,
              collectionsState: collectionsState,
              actions: actions,
              // The root of the tree this member was actually found in —
              // see showProjectDetailsPage's own doc. Not necessarily
              // *this* member's own immediate workspace root if it's
              // nested several workspaces deep, but the closest context
              // this page actually has.
              owningProject: state.project,
            ),
            onSecondaryTapUp: (context, position) => showProjectContextMenu(
              context,
              project,
              position,
              collectionsState: collectionsState,
              actions: actions,
              // A member's own row, reached only through its parent —
              // collections are a top-level organizing feature for
              // Explorer's own project list, not something this needs
              // separately (see showProjectContextMenu's own doc).
              showCollections: false,
            ),
          ),
        );
        if (hasChildren && expanded) {
          rows.addAll(_buildRows(
            context: context,
            state: state,
            actions: actions,
            collectionsState: collectionsState,
            entries: project.subPackages,
            depth: depth + 1,
            zebra: zebra,
          ));
        }
      case WorkspaceFolderEntry(:final children):
        rows.add(
          _SubPackageRow(
            zebra: isZebra,
            depth: depth,
            // FolderIcon's "stack of packages" glyph reads as "a grouping
            // of packages" rather than a real project that simply has no
            // discovered icon — and doesn't need an expanded/collapsed
            // variant since the chevron already shows that state.
            icon: const FolderIcon(size: AppSizes.rowIconSize),
            title: entry.name,
            // Same slot a project row fills with its ProjectLanguageBadge
            // — a folder has no language of its own, so this reports how
            // many real projects it groups (recursively) instead, same
            // as Explorer's own folder/collection section headers do.
            subtitle: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.workspaceFolderProjectCount(
                    children.projectCount,
                  ),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
                // Only when every project under this folder (recursively)
                // agrees on one workspace tool — a folder straddling a
                // nested monorepo's own members (a different workspace
                // than this one) doesn't get a badge, since there'd be
                // no single tool honest to put on it.
                if (entry.sharedWorkspaceTool case final workspaceTool?) ...[
                  const SizedBox(width: AppSizes.spacing6),
                  MonorepoBadge(tool: workspaceTool, count: null),
                ],
              ],
            ),
            expandable: true,
            expanded: expanded,
            onToggle: () => state.toggleExpanded(entry.path),
            // Folders aren't openable in an IDE — no language to resolve
            // one from — tapping the row just does what the chevron does.
            onTap: () => state.toggleExpanded(entry.path),
            onSecondaryTapUp: (context, position) => showFolderContextMenu(
              context,
              entry.path,
              position,
              actions: actions,
            ),
          ),
        );
        if (expanded) {
          rows.addAll(_buildRows(
            context: context,
            state: state,
            actions: actions,
            collectionsState: collectionsState,
            entries: children,
            depth: depth + 1,
            zebra: zebra,
          ));
        }
    }
  }
  return rows;
}

class _SubPackageRow extends StatelessWidget {
  const _SubPackageRow({
    required this.zebra,
    required this.depth,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ide,
    required this.expandable,
    required this.expanded,
    this.onToggle,
    required this.onTap,
    this.onDoubleTap,
    required this.onSecondaryTapUp,
  });

  final bool zebra;
  final int depth;
  final Widget icon;
  final String title;
  final Widget? subtitle;

  // Only set for project rows — a folder has no language to resolve an
  // IDE from, so it never gets the hover "Open In" hint.
  final Ide? ide;

  final bool expandable;
  final bool expanded;
  final VoidCallback? onToggle;

  // Null for a project row nothing installed can actually open (see
  // IdeLauncherRepo.resolveInstalledIde's own doc) — HoverableRow then
  // ignores a tap on it entirely, the same as [ide] being null already
  // hides its hover hint.
  final VoidCallback? onTap;

  // Only set for project rows — a folder has no details of its own to
  // drill into (see project_details.screen.dart's showFolderContextMenu
  // sibling branch, which also has no such concept).
  final VoidCallback? onDoubleTap;

  // Right-click menu — showProjectContextMenu for a project row,
  // showFolderContextMenu for a folder.
  final void Function(BuildContext context, Offset globalPosition)
      onSecondaryTapUp;

  @override
  Widget build(BuildContext context) {
    return HoverableRow(
      height: AppSizes.rowHeight,
      zebra: zebra,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onSecondaryTapUp: onSecondaryTapUp,
      builder: (context, isHovered) => _TreeRowContent(
        depth: depth,
        icon: icon,
        title: title,
        subtitle: subtitle,
        ide: ide,
        expandable: expandable,
        expanded: expanded,
        onToggle: onToggle,
        isHovered: isHovered,
      ),
    );
  }
}

class _TreeRowContent extends StatelessWidget {
  const _TreeRowContent({
    required this.depth,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ide,
    required this.expandable,
    required this.expanded,
    required this.onToggle,
    required this.isHovered,
  });

  final int depth;
  final Widget icon;
  final String title;
  final Widget? subtitle;
  final Ide? ide;
  final bool expandable;
  final bool expanded;
  final VoidCallback? onToggle;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.spacing16 + depth * AppSizes.spacing20,
        0,
        AppSizes.spacing16,
        0,
      ),
      child: Row(
        children: [
          _ExpandChevronSlot(
            expandable: expandable,
            expanded: expanded,
            onToggle: onToggle,
            color: color,
          ),
          const SizedBox(width: AppSizes.spacing6),
          // A fixed-size slot rather than the icon's own natural size — a
          // folder's smaller glyph would otherwise shift the name/badge
          // column left compared to a project row's larger one, breaking
          // the alignment between them.
          SizedBox(
            width: AppSizes.rowIconSize,
            height: AppSizes.rowIconSize,
            child: Center(child: icon),
          ),
          // Same AppSizes.spacing16 gap explorer.screen.dart/
          // storage.screen.dart's own rows use here.
          const SizedBox(width: AppSizes.spacing16),
          Expanded(
            child: _RowTitleAndSubtitle(
              title: title,
              subtitle: subtitle,
              color: color,
            ),
          ),
          // Same hover-only "Open In" hint as Explorer's own rows.
          if (isHovered && ide != null) ...[
            const SizedBox(width: AppSizes.spacing16),
            OpenInHint(ide: ide!),
          ],
        ],
      ),
    );
  }
}

// Every row reserves this slot (chevron or blank) regardless of whether
// it's expandable, so icons still line up within their own depth level.
class _ExpandChevronSlot extends StatelessWidget {
  const _ExpandChevronSlot({
    required this.expandable,
    required this.expanded,
    required this.onToggle,
    required this.color,
  });

  final bool expandable;
  final bool expanded;
  final VoidCallback? onToggle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.spacing20,
      height: AppSizes.spacing20,
      // A plain GestureDetector rather than an InkWell — this chevron sits
      // right next to (and, for a folder, right under) a much bigger ink
      // splash from the row's own InkWell, so its own tiny ripple just
      // reads as visual noise rather than useful feedback. The nested
      // detector still claims the tap before it reaches the row's own
      // onTap.
      child: expandable
          ? GestureDetector(
              // Opaque so the whole reserved box is tappable, not just the
              // icon glyph's own painted pixels.
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: Icon(
                expanded
                    ? CupertinoIcons.chevron_down
                    : CupertinoIcons.chevron_right,
                size: AppSizes.iconXSmall,
                color: color.withValues(alpha: 0.7),
              ),
            )
          : null,
    );
  }
}

class _RowTitleAndSubtitle extends StatelessWidget {
  const _RowTitleAndSubtitle({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final Widget? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: color,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSizes.spacing2),
          subtitle!,
        ],
      ],
    );
  }
}
