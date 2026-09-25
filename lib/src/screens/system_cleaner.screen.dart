import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

/// Reclaimable dev-tool cache cleaner — scans real per-platform cache
/// locations (Xcode DerivedData, ~/.pub-cache, ~/.gradle/caches, ...) via
/// [SystemCleanerUseCases]/SystemCleanerRepo (see SystemCleanerState's own
/// doc).
///
/// [SystemCleanerState] is provided above this screen (see _RootScaffold in
/// app.dart) rather than here, the same way StorageState is — so it stays
/// mounted/scanned for the whole app session (not redone every time this
/// tab is opened) and so DashboardScreen can read its same live totals for
/// its own Size Overview, instead of duplicating SystemCleanerRepo's own
/// filesystem walk in a second store.
class SystemCleanerScreen extends StatelessWidget {
  // See explorer.screen.dart's own doc for why [selected] is needed at
  // all: _RootScaffold keeps every screen mounted at once (an IndexedStack,
  // not a Navigator swap), so F5 needs to know this is the actually-visible
  // tab before claiming the keyboard focus that makes its own binding fire.
  const SystemCleanerScreen({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => _Scaffold(selected: selected);
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

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        // Same rescan the header's own RefreshIconButton triggers.
        LogicalKeySet(LogicalKeyboardKey.f5): () =>
            context.read<SystemCleanerState>().rescan(),
      },
      // CallbackShortcuts only intercepts key events reaching a focused
      // descendant — this Focus's own requestFocus()/unfocus() calls
      // above are what keep that descendant correct as the tab is
      // switched to/away from, rather than a one-shot autofocus.
      child: Focus(
        focusNode: _focusNode,
        child: const AppScaffold(
          body: Column(
            children: [
              _Header(),
              Expanded(child: _Body()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessObserverWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final store = context.read<SystemCleanerState>();
    final l10n = AppLocalizations.of(context)!;

    return HeaderCard(
      title: l10n.systemCleanerTitle,
      actions: [
        RefreshIconButton(
          refreshing: store.isRefreshing,
          onPressed: store.rescan,
          tooltip: l10n.systemCleanerRescanTooltip,
        ),
      ],
      child: _HeaderSummaryRow(store: store, l10n: l10n),
    );
  }
}

class _HeaderSummaryRow extends StatelessObserverWidget {
  const _HeaderSummaryRow({required this.store, required this.l10n});

  final SystemCleanerState store;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        );

    return Row(
      children: [
        Text(
          l10n.systemCleanerTotalLabel(formatBytes(store.totalBytes)),
          style: mutedStyle,
        ),
        const SizedBox(width: AppSizes.spacing16),
        Text(
          l10n.systemCleanerSelectedLabel(formatBytes(store.selectedBytes)),
          style: mutedStyle,
        ),
        const Spacer(),
        if (store.selectedBytes > 0)
          PrimaryButton(
            loading: store.cleaning,
            // Sizes mid-recompute means the total/selected figures shown
            // right now may already be stale, and cleaning would race the
            // refresh's own filesystem walk — block it until that settles
            // (same reasoning as storage.screen.dart's own clean button).
            disabled: store.isRefreshing,
            onPressed: store.cleanSelected,
            backgroundColor: ProjectSizeType.cache.color,
            foregroundColor: Colors.black,
            icon: const Icon(CupertinoIcons.trash, size: AppSizes.iconMedium),
            label: Text(l10n.systemCleanerCleanSelectedButton),
          ),
      ],
    );
  }
}

class _Body extends StatelessObserverWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final store = context.read<SystemCleanerState>();

    if (store.scanning) return const _CategoryListSkeleton();

    if (store.categories.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: EmptyPlaceholder(
          centered: true,
          icon: Icons.cleaning_services_outlined,
          title: l10n.systemCleanerEmptyTitle,
          message: l10n.systemCleanerEmptyMessage,
        ),
      );
    }

    final sortedCategories = store.sortedCategories;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spacing16,
        0,
        AppSizes.spacing16,
        AppSizes.spacing16,
      ),
      itemCount: sortedCategories.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSizes.spacing16),
      itemBuilder: (context, index) =>
          _CategoryCard(category: sortedCategories[index]),
    );
  }
}

// Plain (non-reactive) on purpose — it only wires _CategoryHeaderRow/
// _EntryRow together, and doesn't read any observable itself; those two
// are the ones that actually read selection state, so they're the ones
// that need to be reactive (see their own StatelessObserverWidget).
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final CleanerCategory category;

  @override
  Widget build(BuildContext context) {
    final store = context.read<SystemCleanerState>();
    final entries = category.entries;

    return AppCard(
      // Zero/clipped, same as TableCard's own shell — lets the header
      // row's own tinted background reach the card's rounded edges
      // instead of sitting inset inside AppCard's default padding.
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CategoryHeaderRow(category: category, store: store),
          const HairlineDivider(),
          for (var i = 0; i < entries.length; i++) ...[
            _EntryRow(entry: entries[i], store: store),
            if (i != entries.length - 1) const HairlineDivider(),
          ],
        ],
      ),
    );
  }
}

class _CategoryHeaderRow extends StatelessObserverWidget {
  const _CategoryHeaderRow({required this.category, required this.store});

  final CleanerCategory category;
  final SystemCleanerState store;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      // Same tint TableHeaderRow/TableCard use for a column-header row —
      // reused here so a category's own header reads the same way a
      // table's header does, visually separating it from its entry rows
      // below rather than blending into the rest of the card.
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing4,
      ),
      child: Row(
        children: [
          AssetOrFallbackIcon(
            iconAsset: category.iconAssetPath ?? category.language?.iconAsset,
            fallbackIcon: category.icon,
            size: AppSizes.iconLarge,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: AppSizes.spacing10),
          Expanded(
            child: Text(
              category.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Text(
            formatBytes(category.totalBytes),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          Checkbox(
            tristate: true,
            value: store.isCategoryFullySelected(category)
                ? true
                : (store.isCategoryPartiallySelected(category) ? null : false),
            onChanged: (_) => store.toggleCategory(category),
            activeColor: ProjectSizeType.cache.color,
            checkColor: Colors.black,
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessObserverWidget {
  const _EntryRow({required this.entry, required this.store});

  final CleanerEntry entry;
  final SystemCleanerState store;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing8,
      ),
      child: Row(
        children: [
          // Reserves the same width as the category header's own icon +
          // gap above, so every entry's name aligns under the category
          // title whether or not this particular entry has its own icon.
          _EntryIconSlot(entry: entry),
          Expanded(child: _EntryNameAndPath(entry: entry)),
          const SizedBox(width: AppSizes.spacing12),
          Text(
            formatBytes(entry.sizeBytes),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          Checkbox(
            value: store.isEntrySelected(entry),
            onChanged: (_) => store.toggleEntry(entry),
            activeColor: ProjectSizeType.cache.color,
            checkColor: Colors.black,
          ),
        ],
      ),
    );
  }
}

class _EntryIconSlot extends StatelessWidget {
  const _EntryIconSlot({required this.entry});

  final CleanerEntry entry;

  @override
  Widget build(BuildContext context) {
    const width = AppSizes.iconLarge + AppSizes.spacing10;
    final icon = entry.icon;
    final iconAssetPath = entry.iconAssetPath;
    if (icon == null && iconAssetPath == null) {
      return const SizedBox(width: width);
    }

    return SizedBox(
      width: width,
      // Left-aligned at the same size as _CategoryHeaderRow's own icon,
      // rather than centered, so an entry's icon lines up exactly under
      // the category icon above it instead of sitting further right.
      child: Align(
        alignment: Alignment.centerLeft,
        child: AssetOrFallbackIcon(
          iconAsset: iconAssetPath,
          fallbackIcon: icon ?? Icons.circle,
          size: AppSizes.iconLarge,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _EntryNameAndPath extends StatelessWidget {
  const _EntryNameAndPath({required this.entry});

  final CleanerEntry entry;

  @override
  Widget build(BuildContext context) {
    // labelLarge is this app's smallest caption tier (see AppTypography's
    // own doc — the same one an IDE's name uses under an "Open In" hint),
    // matching how secondary this path line is meant to read next to the
    // entry's name above it.
    final mutedStyle = Theme.of(context).textTheme.labelLarge!.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(entry.name, overflow: TextOverflow.ellipsis),
        Text(
          collapseHomeDir(entry.path),
          style: mutedStyle,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// Mirrors _CategoryCard's own shape (checkbox + icon + title row, a
// divider, a few entry rows) with shimmering placeholder blocks in place
// of real text, matching this app's established "skeleton shaped like the
// real thing" loading convention (see project_details.screen.dart's
// composition cards/tree loading state).
class _CategoryListSkeleton extends StatelessWidget {
  const _CategoryListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.spacing16,
        0,
        AppSizes.spacing16,
        AppSizes.spacing16,
      ),
      children: const [
        _CategoryCardSkeleton(rowCount: 2),
        SizedBox(height: AppSizes.spacing16),
        _CategoryCardSkeleton(rowCount: 3),
        SizedBox(height: AppSizes.spacing16),
        _CategoryCardSkeleton(rowCount: 2),
      ],
    );
  }
}

class _CategoryCardSkeleton extends StatelessWidget {
  const _CategoryCardSkeleton({required this.rowCount});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SkeletonHeaderRow(),
          const HairlineDivider(),
          for (var i = 0; i < rowCount; i++) ...[
            const _SkeletonEntryRow(),
            if (i != rowCount - 1) const HairlineDivider(),
          ],
        ],
      ),
    );
  }
}

// Sized the same way _CategoryHeaderRow itself is (same padding, no
// explicit height — intrinsic, driven by its own tallest child) rather
// than a separate fixed height guessed to match it, which is what made
// the real header snap to a different height the moment it loaded. A
// real (disabled) Checkbox is used for the trailing placeholder for the
// same reason — it, not either shimmer bar, is this row's tallest child
// on both the skeleton and the real header, so matching it exactly is
// what keeps the two the same height.
class _SkeletonHeaderRow extends StatelessWidget {
  const _SkeletonHeaderRow();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.onSurface;

    return Container(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing4,
      ),
      child: Row(
        children: [
          Shimmer(
            child: Container(
              width: AppSizes.iconLarge,
              height: AppSizes.iconLarge,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacing10),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Shimmer(
                child: Container(
                  width: 160,
                  height: AppSizes.iconMedium,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                ),
              ),
            ),
          ),
          Shimmer(
            child: Container(
              width: 60,
              height: AppSizes.iconMedium,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
            ),
          ),
          IgnorePointer(
            child: Checkbox(value: false, onChanged: (_) {}),
          ),
        ],
      ),
    );
  }
}

// Same reasoning as _SkeletonHeaderRow's own doc — same padding/no fixed
// height as the real _EntryRow, a real disabled Checkbox as the trailing
// placeholder, and two stacked shimmer bars (not one) to mirror the real
// row's name-then-path two-line shape.
class _SkeletonEntryRow extends StatelessWidget {
  const _SkeletonEntryRow();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing8,
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSizes.iconLarge + AppSizes.spacing10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Shimmer(
                  child: Container(
                    width: 200,
                    height: AppSizes.spacing12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spacing4),
                Shimmer(
                  child: Container(
                    width: 140,
                    height: AppSizes.spacing10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          Shimmer(
            child: Container(
              width: 50,
              height: AppSizes.iconMedium,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
            ),
          ),
          IgnorePointer(
            child: Checkbox(value: false, onChanged: (_) {}),
          ),
        ],
      ),
    );
  }
}
