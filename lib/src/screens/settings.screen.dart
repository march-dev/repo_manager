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
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProjectDirectoriesCard(),
              SizedBox(height: 16),
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
    final store = context.read<SettingsStore>();
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    await store.addDir(path, recursive: recursive);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<SettingsStore>();
    final colorScheme = Theme.of(context).colorScheme;
    final dirs = store.dirs;
    final commonPrefix = commonDirPrefix(dirs);

    return HeaderCard(
      title: 'Project Directories',
      margin: EdgeInsets.zero,
      actions: [
        _AddDirectoryButton(
          isAdding: store.isAdding,
          onAdd: (recursive) => _pickAndAddDirectory(context, recursive),
        ),
      ],
      child: dirs.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No directories added yet.',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < dirs.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: colorScheme.outlineVariant),
                  _DirectoryRow(path: dirs[i], commonPrefix: commonPrefix),
                ],
              ],
            ),
    );
  }
}

// A split button: the main body adds a directory as-is, while the chevron
// opens a menu offering the recursive variant — this scopes the "include
// subdirectories" choice to the action it modifies instead of it floating
// as an unrelated checkbox elsewhere in the card.
class _AddDirectoryButton extends StatelessWidget {
  const _AddDirectoryButton({required this.isAdding, required this.onAdd});

  final bool isAdding;
  final ValueChanged<bool> onAdd;

  static const _height = 32.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = colorScheme.onPrimary;

    return Material(
      color: colorScheme.primary,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(_height / 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: isAdding ? null : () => onAdd(false),
            child: SizedBox(
              height: _height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAdding)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    else
                      Icon(
                        CupertinoIcons.folder_badge_plus,
                        size: 18,
                        color: foreground,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Directory',
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: _height * 0.6,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: foreground.withValues(alpha: 0.35),
            ),
          ),
          PopupMenuButton<bool>(
            enabled: !isAdding,
            tooltip: 'More ways to add',
            onSelected: onAdd,
            itemBuilder: (context) => const [
              PopupMenuItem(value: false, child: Text('Add Directory')),
              PopupMenuItem(
                value: true,
                child: Text('Add Directory (with subdirectories)'),
              ),
            ],
            child: SizedBox(
              height: _height,
              width: 36,
              child: Center(
                child: Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: foreground,
                ),
              ),
            ),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(CupertinoIcons.folder, size: 18, color: colorScheme.onSurface),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  if (shared.isNotEmpty)
                    TextSpan(
                      text: shared,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  TextSpan(
                    text: distinguishing,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _RemoveDirectoryButton(
            onPressed: () => context.read<SettingsStore>().removeDir(path),
          ),
        ],
      ),
    );
  }
}

// Styled like storage.screen.dart's _ProjectCleanupButton (same filled
// circular shape, same icon size/color), but red instead of the cache color
// since removing a directory is destructive rather than a cleanup.
class _RemoveDirectoryButton extends StatelessWidget {
  const _RemoveDirectoryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: Colors.red,
          shape: const CircleBorder(),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        color: Colors.white,
        visualDensity: VisualDensity.compact,
        tooltip: 'Remove directory',
        icon: const Icon(CupertinoIcons.trash, size: 20),
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

    return HeaderCard(
      title: 'Preferred Editors',
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < LanguageGroup.values.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colorScheme.outlineVariant),
            _LanguageGroupIdeSelector(
              group: LanguageGroup.values[i],
              selected: store.preferredIdes[LanguageGroup.values[i]],
              onChanged: (ide) =>
                  store.setPreferredIde(LanguageGroup.values[i], ide),
              note: LanguageGroup.values[i] == LanguageGroup.cppCsharp
                  ? 'A C++ project already set up for Xcode (has its own '
                      '.xcodeproj/.xcworkspace) always opens in Xcode '
                      'instead, regardless of this setting.'
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

// Overlapping "avatar stack" of a group's language icons — the familiar way
// UIs show a small cluster of related things as one badge, rather than a
// row of separately-gapped icons that reads as an arbitrary list.
class _LanguageIconStack extends StatelessWidget {
  const _LanguageIconStack({required this.languages});

  final Set<ProjectLanguage> languages;

  static const _size = 20.0;
  static const _overlap = 12.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final languages = this.languages.toList();

    return SizedBox(
      width: _size + (languages.length - 1) * _overlap,
      height: _size,
      child: Stack(
        children: [
          for (var i = 0; i < languages.length; i++)
            Positioned(
              left: i * _overlap,
              child: Container(
                width: _size,
                height: _size,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: colorScheme.surfaceContainerHighest,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Image(
                    image: AssetImage(languages[i].iconAsset!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LanguageIconStack(languages: group.languages),
              const SizedBox(width: 10),
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
                              width: 18,
                              height: 18,
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
              ),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(
              note!,
              style: TextStyle(
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
