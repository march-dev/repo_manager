import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';

/// Packages a single source image into every launcher-icon size/format
/// Android and iOS expect — the mipmap set + adaptive-icon XML, and/or the
/// AppIcon.appiconset + Contents.json — the same assets this app's own
/// icon was produced as by hand.
///
/// [AppIconGenState] is provided locally here rather than in
/// _RootScaffold's MultiProvider (app.dart) — nothing outside this screen
/// needs it, the same way SettingsScreen scopes SettingsState to just
/// itself.
class AppIconGenScreen extends StatelessWidget {
  const AppIconGenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<AppIconGenState>(
      create: (_) => AppIconGenState(),
      child: const _Scaffold(),
    );
  }
}

class _Scaffold extends StatelessObserverWidget {
  const _Scaffold();

  Future<void> _pickImage(
    BuildContext context,
    ValueChanged<String> onPicked,
  ) async {
    final String? path;
    try {
      path = await pickImage();
    } catch (error, stackTrace) {
      logError('Pick app icon source image', error, stackTrace);
      if (context.mounted) {
        SnackbarManager.show(
          AppLocalizations.of(context)!.appIconGenPickImageErrorMessage,
        );
      }
      return;
    }
    if (path != null) onPicked(path);
  }

  Future<void> _generate(BuildContext context) async {
    final state = context.read<AppIconGenState>();
    final l10n = AppLocalizations.of(context)!;

    final String? dir;
    try {
      dir = await FilePicker.platform.getDirectoryPath();
    } catch (error, stackTrace) {
      logError('Open folder picker', error, stackTrace);
      if (context.mounted) SnackbarManager.show(l10n.errorOpenFolderPicker);
      return;
    }
    if (dir == null) return;

    try {
      await state.generate(dir);
    } catch (error, stackTrace) {
      logError('Generate app icons', error, stackTrace);
      if (context.mounted) {
        SnackbarManager.show(l10n.appIconGenGenerateErrorMessage);
      }
      return;
    }
    if (context.mounted) {
      SnackbarManager.show(l10n.appIconGenGeneratedMessage(dir));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppIconGenState>();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      body: Column(
        children: [
          HeaderCard(
            title: l10n.appIconGenTitle,
            actions: [
              PrimaryButton(
                onPressed: () => _generate(context),
                disabled: !state.canGenerate,
                loading: state.isGenerating,
                icon: const Icon(
                  CupertinoIcons.wand_stars,
                  size: AppSizes.iconMedium,
                ),
                label: Text(l10n.appIconGenGenerateButton),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.spacing16,
                0,
                AppSizes.spacing16,
                AppSizes.spacing16,
              ),
              children: [
                _PlatformsCard(
                  selected: state.type,
                  onChanged: state.setType,
                ),
                const SizedBox(height: AppSizes.spacing16),
                _SourceImagesCard(
                  type: state.type,
                  srcPath: state.srcPath,
                  srcABgPath: state.srcABgPath,
                  srcAFgPath: state.srcAFgPath,
                  onPickSrc: () => _pickImage(context, state.setSrcPath),
                  onPickABg: () => _pickImage(context, state.setSrcABgPath),
                  onPickAFg: () => _pickImage(context, state.setSrcAFgPath),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformsCard extends StatelessWidget {
  const _PlatformsCard({required this.selected, required this.onChanged});

  final GenerateIconsType selected;
  final ValueChanged<GenerateIconsType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return HeaderCard(
      title: l10n.appIconGenPlatformsCardTitle,
      margin: EdgeInsets.zero,
      child: AppSegmentedButton<GenerateIconsType>(
        selected: selected,
        onChanged: onChanged,
        segments: [
          ButtonSegment(
            value: GenerateIconsType.android,
            label: Text(l10n.appIconGenPlatformAndroid),
          ),
          ButtonSegment(
            value: GenerateIconsType.ios,
            label: Text(l10n.appIconGenPlatformIos),
          ),
          ButtonSegment(
            value: GenerateIconsType.both,
            label: Text(l10n.appIconGenPlatformBoth),
          ),
        ],
      ),
    );
  }
}

class _SourceImagesCard extends StatelessWidget {
  const _SourceImagesCard({
    required this.type,
    required this.srcPath,
    required this.srcABgPath,
    required this.srcAFgPath,
    required this.onPickSrc,
    required this.onPickABg,
    required this.onPickAFg,
  });

  final GenerateIconsType type;
  final String srcPath;
  final String srcABgPath;
  final String srcAFgPath;
  final VoidCallback onPickSrc;
  final VoidCallback onPickABg;
  final VoidCallback onPickAFg;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // The adaptive-icon background/foreground pair only ever gets baked
    // into an iOS-only export, so there's nothing useful to show for them
    // in that mode.
    final showAndroidAdaptive = type != GenerateIconsType.ios;

    return HeaderCard(
      title: l10n.appIconGenSourceImagesCardTitle,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ImageSourceRow(
            label: l10n.appIconGenIconSourceLabel,
            hint: l10n.appIconGenIconSourceHint,
            path: srcPath,
            onPick: onPickSrc,
          ),
          if (showAndroidAdaptive) ...[
            const HairlineDivider(),
            _ImageSourceRow(
              label: l10n.appIconGenAndroidBgLabel,
              hint: l10n.appIconGenAndroidBgHint,
              path: srcABgPath,
              onPick: onPickABg,
            ),
            const HairlineDivider(),
            _ImageSourceRow(
              label: l10n.appIconGenAndroidFgLabel,
              hint: l10n.appIconGenAndroidFgHint,
              path: srcAFgPath,
              onPick: onPickAFg,
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageSourceRow extends StatelessWidget {
  const _ImageSourceRow({
    required this.label,
    required this.hint,
    required this.path,
    required this.onPick,
  });

  final String label;
  final String hint;
  final String path;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing10),
      child: Row(
        children: [
          _Thumbnail(path: path),
          const SizedBox(width: AppSizes.spacing12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSizes.spacing2),
                Text(
                  path.isEmpty ? hint : path,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.spacing12),
          PrimaryButton(
            onPressed: onPick,
            icon: const Icon(CupertinoIcons.photo, size: AppSizes.iconMedium),
            label: Text(l10n.appIconGenChooseImageButton),
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundColor: colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: AppSizes.rowIconSize,
      height: AppSizes.rowIconSize,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: path.isEmpty
          ? Icon(
              CupertinoIcons.photo,
              size: AppSizes.iconLarge,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            )
          : Image.file(File(path), fit: BoxFit.cover),
    );
  }
}
