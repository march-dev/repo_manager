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

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ProjectDirectoriesCard extends StatelessObserverWidget {
  const _ProjectDirectoriesCard();

  Future<void> _pickDirectory(BuildContext context) async {
    final store = context.read<SettingsStore>();
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    await store.addDir(path);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<SettingsStore>();
    final colorScheme = Theme.of(context).colorScheme;
    final dirs = store.dirs;

    return _Card(
      title: 'Project Directories',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dirs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No directories added yet.',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            )
          else
            for (final path in dirs) _DirectoryRow(path: path),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: store.recursiveAdd,
                onChanged: store.isAdding
                    ? null
                    : (value) => store.setRecursiveAdd(value ?? false),
              ),
              const Text('Include subdirectories with projects'),
              const Spacer(),
              FilledButton.icon(
                onPressed:
                    store.isAdding ? null : () => _pickDirectory(context),
                icon: store.isAdding
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(CupertinoIcons.folder_badge_plus, size: 18),
                label: const Text('Add Directory'),
              ),
            ],
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
          IconButton(
            onPressed: () => context.read<SettingsStore>().removeDir(path),
            visualDensity: VisualDensity.compact,
            tooltip: 'Remove directory',
            icon: const Icon(CupertinoIcons.trash, size: 18),
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

    return _Card(
      title: 'Preferred Editor',
      child: SegmentedButton<PreferredIde>(
        segments: const [
          ButtonSegment(
            value: PreferredIde.vscode,
            label: Text('VS Code'),
            icon: Icon(CupertinoIcons.chevron_left_slash_chevron_right),
          ),
          ButtonSegment(
            value: PreferredIde.androidStudio,
            label: Text('Android Studio'),
            icon: Icon(CupertinoIcons.app_badge),
          ),
        ],
        selected: {store.preferredIde},
        onSelectionChanged: (selection) =>
            store.setPreferredIde(selection.first),
      ),
    );
  }
}
