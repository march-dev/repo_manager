import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../repo_manager.dart';
import 'colour_scheme_gen_swatch_groups.dart';

/// A live preview of the color scheme a given seed color would produce,
/// under Material 3, Material 2, or Cupertino (or this app's own real,
/// fixed scheme) — every named color role, grouped the way that design
/// system's own docs group them, with its resolved hex value alongside
/// it. Purely a reference tool: picking a seed color or switching design
/// system only recomputes this preview, it has no effect on the app's
/// own (fixed dark, Material 3) theme.
///
/// [ColourSchemeGenState] (which design system, which seed color) is
/// provided locally here rather than in _RootScaffold's MultiProvider
/// (app.dart) — nothing outside this screen needs it, the same way
/// SettingsScreen scopes SettingsState to just itself.
class ColourSchemeGenScreen extends StatelessWidget {
  const ColourSchemeGenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<ColourSchemeGenState>(
      create: (_) => ColourSchemeGenState(),
      child: const _Scaffold(),
    );
  }
}

// Below this available width, the title/segmented toggle/seed button no
// longer comfortably fit on one line together — an estimate for this
// screen's own current content.
const _headerBreakpoint = 700.0;

class _Scaffold extends StatelessObserverWidget {
  const _Scaffold();

  Future<void> _pickSeedColor(BuildContext context) async {
    final state = context.read<ColourSchemeGenState>();
    final picked = await _showSeedColorPickerDialog(context, state.seedColor);
    if (picked != null) state.setSeedColor(picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<ColourSchemeGenState>();
    final l10n = AppLocalizations.of(context)!;
    final groups = swatchGroupsFor(state.kind, state.seedColor, context);
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      body: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final oneRow = constraints.maxWidth >= _headerBreakpoint;

              final schemeToggle = AppSegmentedButton<SchemeKind>(
                selected: state.kind,
                onChanged: state.setKind,
                segments: const [
                  ButtonSegment(
                    value: SchemeKind.material3,
                    label: Text('Material 3'),
                  ),
                  ButtonSegment(
                    value: SchemeKind.material2,
                    label: Text('Material 2'),
                  ),
                  ButtonSegment(
                    value: SchemeKind.cupertino,
                    label: Text('Cupertino'),
                  ),
                  ButtonSegment(
                    value: SchemeKind.thisApp,
                    label: Text('This App'),
                  ),
                ],
              );

              return HeaderCard(
                title: l10n.colourSchemeGenTitle,
                actions: [
                  if (oneRow) ...[
                    schemeToggle,
                    const SizedBox(width: AppSizes.spacing12),
                  ],
                  PrimaryButton(
                    onPressed: () => _pickSeedColor(context),
                    disabled: state.seedPickerDisabled,
                    icon: const Icon(
                      CupertinoIcons.paintbrush_fill,
                      size: AppSizes.iconMedium,
                    ),
                    label: Text(l10n.colourSchemeGenPickSeedButton),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ],
                // Not enough room — the toggle drops to its own centered
                // row below the title instead of crowding the seed button
                // in the title row itself.
                child: oneRow ? null : Center(child: schemeToggle),
              );
            },
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.spacing16,
                0,
                AppSizes.spacing16,
                AppSizes.spacing16,
              ),
              itemCount: groups.length,
              separatorBuilder: (context, _) =>
                  const SizedBox(height: AppSizes.spacing16),
              itemBuilder: (context, index) =>
                  _SwatchGroupCard(group: groups[index]),
            ),
          ),
        ],
      ),
    );
  }
}

Future<Color?> _showSeedColorPickerDialog(
  BuildContext context,
  Color initialColor,
) {
  final l10n = AppLocalizations.of(context)!;
  var pickedColor = initialColor;

  return showDialog<Color>(
    context: context,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;

      // ColorPicker's side-by-side layout wants ~660 of width for its own
      // content (colorPickerWidth + hue ring/indicator + slider column +
      // internal padding) — comfortably fits most desktop windows, but
      // not every one, so this falls back to its narrower stacked layout
      // (and a narrower dialog to match) rather than clipping/overflowing
      // on a smaller screen. Checked against the window's actual width
      // (minus Dialog's own insetPadding), not just its orientation —
      // ColorPicker's own default portrait/landscape switch only looks at
      // aspect ratio, which a narrow-but-landscape window would still
      // fail.
      final availableWidth = MediaQuery.sizeOf(context).width - 96;
      final useWideLayout = availableWidth >= 700;
      final dialogWidth =
          useWideLayout ? 720.0 : availableWidth.clamp(280.0, 400.0);

      return DialogShell(
        title: l10n.colourSchemeGenPickerDialogTitle,
        width: dialogWidth,
        actions: [
          PrimaryButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(CupertinoIcons.xmark, size: AppSizes.iconMedium),
            label: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundColor: colorScheme.onSurface,
          ),
          PrimaryButton(
            onPressed: () => Navigator.of(context).pop(pickedColor),
            icon: const Icon(
              CupertinoIcons.checkmark_alt,
              size: AppSizes.iconMedium,
            ),
            label: Text(l10n.colourSchemeGenPickerConfirm),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        ],
        // DialogShell's own Column sizes to its content (mainAxisSize.min)
        // rather than the available screen height, so an unbounded
        // ColorPicker here would just push the whole dialog taller than
        // the window and get clipped at the bottom instead of scrolling.
        // Bounding this box's height is what actually makes the
        // SingleChildScrollView below able to scroll at all — an
        // unbounded scroll view sizes to its child's full height instead
        // of the space available, same reason as the width fix above.
        child: SizedBox(
          height: useWideLayout ? 300 : 400,
          child: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initialColor,
              onColorChanged: (color) => pickedColor = color,
              enableAlpha: false,
              // Forces ColorPicker's narrower single-column layout when
              // there isn't room for its side-by-side one — see
              // useWideLayout above.
              portraitOnly: !useWideLayout,
              // Taller picking area now that the wide layout gives it
              // room to breathe; shrunk back down for the narrow stacked
              // layout so its total height still fits within the box
              // above without scrolling in the common case.
              pickerAreaHeightPercent: useWideLayout ? 0.85 : 0.7,
            ),
          ),
        ),
      );
    },
  );
}

class _SwatchGroupCard extends StatelessWidget {
  const _SwatchGroupCard({required this.group});

  final SwatchGroup group;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSizes.spacing12),
          Wrap(
            spacing: AppSizes.spacing12,
            runSpacing: AppSizes.spacing12,
            children: [
              for (final swatch in group.swatches) _SwatchTile(swatch: swatch),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwatchTile extends StatelessWidget {
  const _SwatchTile({required this.swatch});

  final Swatch swatch;

  static const _width = 180.0;

  Future<void> _copyHex(BuildContext context) async {
    final hex = toHex(swatch.color);
    await Clipboard.setData(ClipboardData(text: hex));
    if (!context.mounted) return;
    SnackbarManager.show(
      AppLocalizations.of(context)!.colourSchemeGenCopiedMessage(hex),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: _width,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        onTap: () => _copyHex(context),
        child: Row(
          children: [
            Container(
              width: AppSizes.rowIconSize,
              height: AppSizes.rowIconSize,
              decoration: BoxDecoration(
                color: swatch.color,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
            ),
            const SizedBox(width: AppSizes.spacing10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    swatch.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    toHex(swatch.color),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
