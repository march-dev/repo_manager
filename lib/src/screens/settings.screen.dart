import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

class SettingsScreen extends StatelessWidget {
  // See explorer.screen.dart's own doc for why [selected] is needed at
  // all: _RootScaffold keeps every screen mounted at once (an IndexedStack,
  // not a Navigator swap), so F5 needs to know this is the actually-visible
  // tab before claiming the keyboard focus that makes its own binding fire.
  const SettingsScreen({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Provider<SettingsState>(
      // Reads its use cases inside create (via its own context, not this
      // build()'s) so that ancestor lookup only actually runs once — when
      // the state is first requested — matching create's own lazy
      // contract, rather than paying for it on every rebuild of this
      // widget regardless of whether SettingsState is even needed yet.
      create: (context) => SettingsState(
        appSettingsUseCases: context.read<AppSettingsUseCases>(),
        projectDirectoryUseCases: context.read<ProjectDirectoryUseCases>(),
        ideLauncherUseCases: context.read<IdeLauncherUseCases>(),
      ),
      child: _Scaffold(selected: selected),
    );
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

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        // Rescans which IDEs are actually installed (and re-heals any
        // preference that's drifted onto one that isn't) — see
        // SettingsState.refreshNotInstalledIdes' own doc. Nothing else on
        // this screen has anything worth manually refreshing (dirs/
        // preferences are only ever changed by an explicit action of
        // their own), so unlike Explorer/Storage/project details this
        // has no matching header refresh button — F5 is its only trigger.
        LogicalKeySet(LogicalKeyboardKey.f5): () =>
            context.read<SettingsState>().refreshNotInstalledIdes(),
      },
      // CallbackShortcuts only intercepts key events reaching a focused
      // descendant — this Focus's own requestFocus()/unfocus() calls
      // above are what keep that descendant correct as the tab is
      // switched to/away from, rather than a one-shot autofocus.
      child: Focus(
        focusNode: _focusNode,
        child: AppScaffold(
          body: ListView(
            padding: const EdgeInsets.all(AppSizes.spacing16),
            children: const [
              _ProjectDirectoriesCard(),
              SizedBox(height: AppSizes.spacing16),
              _PreferredEditorCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectDirectoriesCard extends StatelessObserverWidget {
  const _ProjectDirectoriesCard();

  Future<void> _pickAndAddDirectory(
      BuildContext context, bool recursive) async {
    final store = context.read<SettingsState>();
    final String? path;
    try {
      path = await FilePicker.platform.getDirectoryPath();
    } catch (error, stackTrace) {
      logError('Open folder picker', error, stackTrace);
      if (context.mounted) {
        SnackbarManager.show(
            AppLocalizations.of(context)!.errorOpenFolderPicker);
      }
      return;
    }
    if (path == null) return;
    await store.addDir(path, recursive: recursive);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<SettingsState>();
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final dirs = store.dirs;
    final commonPrefix = commonDirPrefix(dirs);

    return HeaderCard(
      title: l10n.settingsProjectDirectoriesTitle,
      margin: EdgeInsets.zero,
      actions: [
        SplitButton<bool>(
          icon: CupertinoIcons.folder_badge_plus,
          label: l10n.settingsAddDirectoryButton,
          loading: store.isAdding,
          menuTooltip: l10n.settingsAddDirectoryMoreTooltip,
          onPressed: () => _pickAndAddDirectory(context, false),
          onMenuItemSelected: (recursive) =>
              _pickAndAddDirectory(context, recursive),
          menuItems: [
            SplitButtonMenuItem(
              value: false,
              label: l10n.settingsAddDirectoryButton,
            ),
            SplitButtonMenuItem(
              value: true,
              label: l10n.settingsAddDirectoryRecursiveMenuItem,
            ),
          ],
        ),
      ],
      child: dirs.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
              child: Text(
                l10n.settingsNoDirectoriesMessage,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < store.visibleDirs.length; i++) ...[
                  if (i > 0) const HairlineDivider(),
                  _DirectoryRow(
                    path: store.visibleDirs[i],
                    commonPrefix: commonPrefix,
                  ),
                ],
                if (store.dirsCollapsible) ...[
                  const HairlineDivider(),
                  _ShowMoreToggle(
                    expanded: store.dirsExpanded,
                    hiddenCount: store.hiddenDirsCount,
                    onTap: store.toggleDirsExpanded,
                  ),
                ],
              ],
            ),
    );
  }
}

class _ShowMoreToggle extends StatelessWidget {
  const _ShowMoreToggle({
    required this.expanded,
    required this.hiddenCount,
    required this.onTap,
  });

  final bool expanded;
  final int hiddenCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    // Muted, same as _DirectoryRow's own shared-prefix text/settingsNo
    // DirectoriesMessage above — this reads as another (understated) row
    // in the same list, not a standalone call-to-action.
    final mutedColor = colorScheme.onSurface.withValues(alpha: 0.6);

    return InkWell(
      // Only the bottom corners — this sits at the very bottom of
      // _ProjectDirectoriesCard's own AppCard, so its hover/press
      // highlight should echo that card's rounding there instead of
      // squaring off against it.
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(AppSizes.radiusLarge),
        bottomRight: Radius.circular(AppSizes.radiusLarge),
      ),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Matches _DirectoryRow's own leading icon size, so this row's
            // text lines up under the folder names above it.
            Icon(
              expanded
                  ? CupertinoIcons.chevron_up
                  : CupertinoIcons.chevron_down,
              size: AppSizes.iconMedium,
              color: mutedColor,
            ),
            const SizedBox(width: AppSizes.spacing8),
            Text(
              expanded
                  ? l10n.settingsShowLessDirectoriesButton
                  : l10n.settingsShowMoreDirectoriesButton(hiddenCount),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectoryRow extends StatelessWidget {
  const _DirectoryRow({required this.path, required this.commonPrefix});

  final String path;

  // The prefix shared with every other configured directory (see
  // explorer.screen.dart's _ProjectGroup, which shows the same distinction
  // for its group labels) — everything after it is what actually tells this
  // directory apart from the others, so that part is bolded.
  final String commonPrefix;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final distinguishing = stripCommonPrefix(path, commonPrefix);
    final shared = path.substring(0, path.length - distinguishing.length);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing10),
      child: Row(
        children: [
          Icon(CupertinoIcons.folder,
              size: AppSizes.iconMedium, color: colorScheme.onSurface),
          const SizedBox(width: AppSizes.spacing8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (shared.isNotEmpty)
                    TextSpan(
                      text: shared,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  TextSpan(
                    text: distinguishing,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Styled like storage.screen.dart's cleanup button (same filled
          // circular shape, same icon size/color), but red instead of the
          // cache color since removing a directory is destructive rather
          // than a cleanup.
          CircleIconButton(
            size: AppSizes.actionColumnSize,
            onPressed: () => context.read<SettingsState>().removeDir(path),
            backgroundColor: AppColors.destructive,
            color: Colors.white,
            tooltip:
                AppLocalizations.of(context)!.settingsRemoveDirectoryTooltip,
            icon: const Icon(CupertinoIcons.trash, size: AppSizes.iconLarge),
          ),
        ],
      ),
    );
  }
}

class _PreferredEditorCard extends StatelessObserverWidget {
  const _PreferredEditorCard();

  @override
  Widget build(BuildContext context) {
    final store = context.read<SettingsState>();
    final l10n = AppLocalizations.of(context)!;

    return HeaderCard(
      title: l10n.settingsPreferredEditorsTitle,
      margin: EdgeInsets.zero,
      // HeaderCard's title row has no actions here, so — with nothing to
      // stretch it — it's only as tall as the title text itself, shorter
      // than _ProjectDirectoriesCard's own title row (stretched to 32 by
      // its SplitButton). A zero-width spacer the same height as that
      // SplitButton keeps the two cards' titles vertically aligned to the
      // same rhythm, without actually showing anything in its place.
      actions: const [SizedBox(height: 32)],
      // One shared threshold for every row, rather than each row deciding
      // for itself off its own candidate count — otherwise, at some
      // widths, a 2-candidate row (full labels) and a 3-candidate row
      // (icon-only) would sit right on top of each other, looking like
      // two different kinds of control instead of one consistent list.
      // Sized off the widest row (the group with the most candidates), so
      // every row toggles to icon-only together, at the same width.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxCandidateCount = LanguageGroup.values
              .map((group) => group.candidatesOnHost.length)
              .reduce((a, b) => a > b ? a : b);
          final showIdeLabels = constraints.maxWidth >=
              _ideRowLeadingWidthEstimate +
                  maxCandidateCount * _ideSegmentWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < LanguageGroup.values.length; i++) ...[
                if (i > 0) const HairlineDivider(),
                _LanguageGroupIdeSelector(
                  group: LanguageGroup.values[i],
                  selected: store.preferredIdes[LanguageGroup.values[i]],
                  onChanged: (ide) =>
                      store.setPreferredIde(LanguageGroup.values[i], ide),
                  note: LanguageGroup.values[i] == LanguageGroup.cpp
                      ? l10n.settingsCppXcodeNote
                      : null,
                  showIdeLabels: showIdeLabels,
                  notInstalledIdes: store.notInstalledIdes,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// Every segment across every group is the same fixed width — regardless of
// how long that IDE's label is — so all three rows' controls line up as one
// column, like a native settings list.
const _ideSegmentWidth = 130.0;

// A rough, deliberately generous estimate for everything to the left of
// the segmented button in this row (the icon stack, its gap, the group's
// title text, the Spacer's own minimum) — not exact (the title's real
// width varies by group/locale), but exactness isn't the point here, only
// a reasonable point past which the full-label segments plus this
// leading content would visibly crowd/overflow a narrow window.
const _ideRowLeadingWidthEstimate = 272.0;

// Icon assets shown in a language group's icon stack: one per language in
// the group, plus Flutter's icon for the Dart & Flutter group specifically —
// Flutter has no ProjectLanguage of its own any more (it's a
// ProjectFramework tied to ProjectLanguage.dart), so its icon can't come
// from group.languages and has to be added here by hand for that one case.
//
// androidJavaKotlin is the odd one out: a single Android icon instead of
// its own languages' (Java/Kotlin's own icons already cover javaKotlin
// right below it in the card, so a second row repeating them would just
// look like a duplicate; Android's own icon is what actually distinguishes
// this row — see its own label/doc in language_group.enum.dart).
List<String> _iconAssetsFor(LanguageGroup group) {
  if (group == LanguageGroup.androidJavaKotlin) {
    return const ['assets/images/tool/android.png'];
  }

  return [
    for (final language in group.languages)
      if (language.iconAsset != null) language.iconAsset!,
    if (group == LanguageGroup.dartFlutter) ProjectFramework.flutter.iconAsset!,
  ];
}

class _LanguageGroupIdeSelector extends StatelessWidget {
  const _LanguageGroupIdeSelector({
    required this.group,
    required this.selected,
    required this.onChanged,
    required this.showIdeLabels,
    required this.notInstalledIdes,
    this.note,
  });

  final LanguageGroup group;
  final Ide? selected;
  final ValueChanged<Ide> onChanged;

  // Candidates SettingsState found not actually installed on this machine
  // (a subset of group.candidatesOnHost, which has already dropped one
  // this OS could never run at all) — disabled below rather than hidden.
  // SettingsState._reselectNotInstalledPreferences already moves a
  // preference that drifted onto one of these to the next installed
  // candidate, so `selected` itself is normally never a member of this set
  // by the time it's actually shown; the one case this still disables in
  // practice is every candidate in a group being not installed at once,
  // with nothing better left to fall back to.
  final Set<Ide> notInstalledIdes;

  // Decided once, per _PreferredEditorCard, off the widest row across
  // every group — not by this row's own candidate count — so every row's
  // segmented button toggles between full-label and icon-only together,
  // rather than some rows collapsing before others at the same width.
  final bool showIdeLabels;

  final String? note;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Fixed width regardless of how many icons this group
              // actually stacks (1 for the single-language groups — cpp,
              // csharp, python, go, rust, php — vs. 2 for dartFlutter/
              // androidJavaKotlin/javaKotlin/objectiveCSwift/jsTs) —
              // IconStack's own width grows with icon count, and without
              // this the title's x-position would shift group to group
              // depending on that count.
              SizedBox(
                width: AppSizes.iconLarge + AppSizes.spacing12,
                child: IconStack(iconAssets: _iconAssetsFor(group)),
              ),
              const SizedBox(width: AppSizes.spacing10),
              Text(group.label),
              const SizedBox(width: AppSizes.spacing10),
              const Spacer(),
              AppSegmentedButton<Ide>(
                selected: selected ?? group.defaultIde,
                onChanged: onChanged,
                segments: [
                  for (final ide in group.candidatesOnHost)
                    ButtonSegment(
                      value: ide,
                      enabled: !notInstalledIdes.contains(ide),
                      // A disabled segment always gets a tooltip — even in
                      // showIdeLabels mode, where every other segment's
                      // stays null (the label alone already says which IDE
                      // it is) — since disabled is the one state that isn't
                      // otherwise self-explanatory: nothing else on this
                      // row says why it can't be picked.
                      tooltip: notInstalledIdes.contains(ide)
                          ? l10n.settingsIdeNotInstalledTooltip(ide.label)
                          : (showIdeLabels ? null : ide.label),
                      // Collapsed, this is just the bare icon — no
                      // wrapping SizedBox/Row — so the segment's own
                      // (tightened, see padding above) horizontal
                      // padding is the only space around it, symmetric
                      // on both sides. A fixed-width box here previously
                      // left the icon pinned to its start, with unused
                      // width (and thus extra, lopsided padding) after
                      // it instead of before.
                      label: !showIdeLabels
                          ? Image(
                              image: AssetImage(ide.iconAsset),
                              width: AppSizes.iconMedium,
                              height: AppSizes.iconMedium,
                            )
                          : SizedBox(
                              width: _ideSegmentWidth,
                              // The icon stays pinned to the left across
                              // every segment regardless of label
                              // length; only the text centers itself
                              // within the remaining space.
                              child: Row(
                                children: [
                                  Image(
                                    image: AssetImage(ide.iconAsset),
                                    width: AppSizes.iconMedium,
                                    height: AppSizes.iconMedium,
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        ide.label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                ],
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: AppSizes.spacing6),
            Padding(
              // Lines up with the title above rather than the icon stack
              // to its left — same left offset the title's own Row gives
              // it (icon stack width + the gap before the title).
              padding: const EdgeInsets.only(
                left: AppSizes.iconLarge +
                    AppSizes.spacing12 +
                    AppSizes.spacing10,
              ),
              child: Text(
                note!,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
