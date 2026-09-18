import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
      ),
      child: const _Scaffold(),
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        children: const [
          _ProjectDirectoriesCard(),
          SizedBox(height: AppSizes.spacing16),
          _PreferredEditorCard(),
        ],
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
                for (var i = 0; i < dirs.length; i++) ...[
                  if (i > 0) const HairlineDivider(),
                  _DirectoryRow(path: dirs[i], commonPrefix: commonPrefix),
                ],
              ],
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
List<String> _iconAssetsFor(LanguageGroup group) {
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
    this.note,
  });

  final LanguageGroup group;
  final Ide? selected;
  final ValueChanged<Ide> onChanged;

  // Decided once, per _PreferredEditorCard, off the widest row across
  // every group — not by this row's own candidate count — so every row's
  // segmented button toggles between full-label and icon-only together,
  // rather than some rows collapsing before others at the same width.
  final bool showIdeLabels;

  final String? note;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Fixed width regardless of how many icons this group
              // actually stacks (1 for the newer single-language groups
              // vs. 2 for dartFlutter/javaKotlin/objectiveCSwift/
              // cppCsharp/jsTs) — IconStack's own width grows with icon
              // count, and without this the title's x-position would
              // shift group to group depending on that count.
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
                      tooltip: showIdeLabels ? null : ide.label,
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
