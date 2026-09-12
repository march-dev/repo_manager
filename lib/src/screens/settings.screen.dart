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
              children: [for (final path in dirs) _DirectoryRow(path: path)],
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
  const _DirectoryRow({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(CupertinoIcons.folder, size: 18, color: colorScheme.onSurface),
          const SizedBox(width: 8),
          Expanded(
            child: Text(path, overflow: TextOverflow.ellipsis),
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

class _LanguageGroupIdeSelector extends StatelessWidget {
  const _LanguageGroupIdeSelector({
    required this.group,
    required this.selected,
    required this.onChanged,
  });

  final LanguageGroup group;
  final Ide? selected;
  final ValueChanged<Ide> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image(
                          image: AssetImage(ide.iconAsset),
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(ide.label, overflow: TextOverflow.ellipsis),
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
    );
  }
}
