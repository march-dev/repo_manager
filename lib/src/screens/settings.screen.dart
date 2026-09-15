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
    return Provider<SettingsStore>(
      create: (_) => SettingsStore(),
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
    final store = context.read<SettingsStore>();
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    await store.addDir(path, recursive: recursive);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<SettingsStore>();
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
                  if (i > 0)
                    Divider(
                        height: AppSizes.borderWidth,
                        color: colorScheme.outlineVariant),
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
            onPressed: () => context.read<SettingsStore>().removeDir(path),
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
    final store = context.read<SettingsStore>();
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return HeaderCard(
      title: l10n.settingsPreferredEditorsTitle,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < LanguageGroup.values.length; i++) ...[
            if (i > 0)
              Divider(
                  height: AppSizes.borderWidth,
                  color: colorScheme.outlineVariant),
            _LanguageGroupIdeSelector(
              group: LanguageGroup.values[i],
              selected: store.preferredIdes[LanguageGroup.values[i]],
              onChanged: (ide) =>
                  store.setPreferredIde(LanguageGroup.values[i], ide),
              note: LanguageGroup.values[i] == LanguageGroup.cppCsharp
                  ? l10n.settingsCppXcodeNote
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

// Every segment across every group is the same fixed width — regardless of
// how long that IDE's label is — so all three rows' controls line up as one
// column, like a native settings list.
const _ideSegmentWidth = 130.0;

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
    this.note,
  });

  final LanguageGroup group;
  final Ide? selected;
  final ValueChanged<Ide> onChanged;
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
              IconStack(iconAssets: _iconAssetsFor(group)),
              const SizedBox(width: AppSizes.spacing10),
              Text(group.label),
              const Spacer(),
              SegmentedButton<Ide>(
                showSelectedIcon: false,
                segments: [
                  for (final ide in group.candidateIdes)
                    ButtonSegment(
                      value: ide,
                      label: SizedBox(
                        width: _ideSegmentWidth,
                        // The icon stays pinned to the left across every
                        // segment regardless of label length; only the text
                        // centers itself within the remaining space.
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
                selected: {selected ?? group.defaultIde},
                onSelectionChanged: (selection) => onChanged(selection.first),
                // Unselected segments otherwise pick up the theme's default
                // surface tint, which reads as a separate panel floating over
                // the header card rather than sitting flush with the page
                // behind it — matching the app's own background instead makes
                // the selected segment the only thing that stands out.
                style: SegmentedButton.styleFrom(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: AppSizes.spacing6),
            Text(
              note!,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
