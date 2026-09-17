import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../repo_manager.dart';

/// Every named [ColorScheme] role Material 3's `ColorScheme.fromSeed`
/// actually generates, grouped the way [ColorScheme]'s own API groups
/// them.
List<SwatchGroup> material3SwatchGroups(ColorScheme c) {
  return [
    (
      title: 'Primary',
      swatches: [
        (label: 'Primary', color: c.primary),
        (label: 'On Primary', color: c.onPrimary),
        (label: 'Primary Container', color: c.primaryContainer),
        (label: 'On Primary Container', color: c.onPrimaryContainer),
        (label: 'Primary Fixed', color: c.primaryFixed),
        (label: 'On Primary Fixed', color: c.onPrimaryFixed),
        (label: 'Primary Fixed Dim', color: c.primaryFixedDim),
        (label: 'On Primary Fixed Variant', color: c.onPrimaryFixedVariant),
      ],
    ),
    (
      title: 'Secondary',
      swatches: [
        (label: 'Secondary', color: c.secondary),
        (label: 'On Secondary', color: c.onSecondary),
        (label: 'Secondary Container', color: c.secondaryContainer),
        (label: 'On Secondary Container', color: c.onSecondaryContainer),
        (label: 'Secondary Fixed', color: c.secondaryFixed),
        (label: 'On Secondary Fixed', color: c.onSecondaryFixed),
        (label: 'Secondary Fixed Dim', color: c.secondaryFixedDim),
        (
          label: 'On Secondary Fixed Variant',
          color: c.onSecondaryFixedVariant,
        ),
      ],
    ),
    (
      title: 'Tertiary',
      swatches: [
        (label: 'Tertiary', color: c.tertiary),
        (label: 'On Tertiary', color: c.onTertiary),
        (label: 'Tertiary Container', color: c.tertiaryContainer),
        (label: 'On Tertiary Container', color: c.onTertiaryContainer),
        (label: 'Tertiary Fixed', color: c.tertiaryFixed),
        (label: 'On Tertiary Fixed', color: c.onTertiaryFixed),
        (label: 'Tertiary Fixed Dim', color: c.tertiaryFixedDim),
        (label: 'On Tertiary Fixed Variant', color: c.onTertiaryFixedVariant),
      ],
    ),
    (
      title: 'Error',
      swatches: [
        (label: 'Error', color: c.error),
        (label: 'On Error', color: c.onError),
        (label: 'Error Container', color: c.errorContainer),
        (label: 'On Error Container', color: c.onErrorContainer),
      ],
    ),
    (
      title: 'Surface',
      swatches: [
        (label: 'Surface', color: c.surface),
        (label: 'On Surface', color: c.onSurface),
        (label: 'On Surface Variant', color: c.onSurfaceVariant),
        (label: 'Surface Dim', color: c.surfaceDim),
        (label: 'Surface Bright', color: c.surfaceBright),
        (label: 'Surface Container Lowest', color: c.surfaceContainerLowest),
        (label: 'Surface Container Low', color: c.surfaceContainerLow),
        (label: 'Surface Container', color: c.surfaceContainer),
        (label: 'Surface Container High', color: c.surfaceContainerHigh),
        (
          label: 'Surface Container Highest',
          color: c.surfaceContainerHighest,
        ),
      ],
    ),
    (
      title: 'Inverse',
      swatches: [
        (label: 'Inverse Surface', color: c.inverseSurface),
        (label: 'On Inverse Surface', color: c.onInverseSurface),
        (label: 'Inverse Primary', color: c.inversePrimary),
      ],
    ),
    (
      title: 'Other',
      swatches: [
        (label: 'Outline', color: c.outline),
        (label: 'Outline Variant', color: c.outlineVariant),
        (label: 'Shadow', color: c.shadow),
        (label: 'Scrim', color: c.scrim),
        (label: 'Surface Tint', color: c.surfaceTint),
      ],
    ),
  ];
}

/// Apple's own system palette — fixed, not generated from any seed color
/// (Cupertino has no seed-based scheme generator the way Material does).
/// Each color is a [CupertinoDynamicColor], so it's resolved against the
/// current context rather than always showing its light-mode value.
List<SwatchGroup> cupertinoSwatchGroups(BuildContext context) {
  Color resolve(CupertinoDynamicColor color) => color.resolveFrom(context);

  return [
    (
      title: 'Text',
      swatches: [
        (label: 'Label', color: resolve(CupertinoColors.label)),
        (
          label: 'Secondary Label',
          color: resolve(CupertinoColors.secondaryLabel),
        ),
        (
          label: 'Tertiary Label',
          color: resolve(CupertinoColors.tertiaryLabel),
        ),
        (
          label: 'Quaternary Label',
          color: resolve(CupertinoColors.quaternaryLabel),
        ),
        (
          label: 'Placeholder Text',
          color: resolve(CupertinoColors.placeholderText),
        ),
      ],
    ),
    (
      title: 'Backgrounds',
      swatches: [
        (
          label: 'System Background',
          color: resolve(CupertinoColors.systemBackground),
        ),
        (
          label: 'Secondary System Background',
          color: resolve(CupertinoColors.secondarySystemBackground),
        ),
        (
          label: 'Tertiary System Background',
          color: resolve(CupertinoColors.tertiarySystemBackground),
        ),
        (
          label: 'System Grouped Background',
          color: resolve(CupertinoColors.systemGroupedBackground),
        ),
      ],
    ),
    (
      title: 'Fills',
      swatches: [
        (label: 'System Fill', color: resolve(CupertinoColors.systemFill)),
        (
          label: 'Secondary System Fill',
          color: resolve(CupertinoColors.secondarySystemFill),
        ),
        (
          label: 'Tertiary System Fill',
          color: resolve(CupertinoColors.tertiarySystemFill),
        ),
        (
          label: 'Quaternary System Fill',
          color: resolve(CupertinoColors.quaternarySystemFill),
        ),
      ],
    ),
    (
      title: 'System Colors',
      swatches: [
        (label: 'System Blue', color: resolve(CupertinoColors.systemBlue)),
        (label: 'System Green', color: resolve(CupertinoColors.systemGreen)),
        (
          label: 'System Indigo',
          color: resolve(CupertinoColors.systemIndigo),
        ),
        (
          label: 'System Orange',
          color: resolve(CupertinoColors.systemOrange),
        ),
        (label: 'System Pink', color: resolve(CupertinoColors.systemPink)),
        (
          label: 'System Purple',
          color: resolve(CupertinoColors.systemPurple),
        ),
        (label: 'System Red', color: resolve(CupertinoColors.systemRed)),
        (label: 'System Teal', color: resolve(CupertinoColors.systemTeal)),
        (
          label: 'System Yellow',
          color: resolve(CupertinoColors.systemYellow),
        ),
        (label: 'System Grey', color: resolve(CupertinoColors.systemGrey)),
      ],
    ),
    (
      title: 'Separators',
      swatches: [
        (label: 'Separator', color: resolve(CupertinoColors.separator)),
        (
          label: 'Opaque Separator',
          color: resolve(CupertinoColors.opaqueSeparator),
        ),
      ],
    ),
  ];
}

/// Every color this app's own UI code actually uses — not just the
/// ColorScheme roles it reads via `Theme.of(context).colorScheme` (found
/// by grepping every `colorScheme.*` access under lib/src; AppTheme.dark()
/// sets a few roles nothing ever reads — error, secondary, tertiary, ... —
/// purely because ColorScheme's own constructor requires a value for every
/// field, so those are left out here), but also AppColors' own constants
/// that live outside ColorScheme entirely (a Scaffold background, the
/// favourite/destructive semantic colors), plus the two features with a
/// fixed palette of their own: Storage's size bar and SnackbarManager's
/// notifications.
List<SwatchGroup> thisAppSwatchGroups(ColorScheme c) {
  return [
    (
      title: 'Primary',
      swatches: [
        (label: 'Primary', color: c.primary),
        (label: 'On Primary', color: c.onPrimary),
      ],
    ),
    (
      title: 'Secondary',
      swatches: [
        (label: 'Secondary Container', color: c.secondaryContainer),
        (label: 'On Secondary Container', color: c.onSecondaryContainer),
      ],
    ),
    (
      title: 'Surface',
      swatches: [
        (
          label: 'Surface Container Highest',
          color: c.surfaceContainerHighest,
        ),
        (label: 'On Surface', color: c.onSurface),
        (label: 'On Surface Variant', color: c.onSurfaceVariant),
      ],
    ),
    (
      title: 'Outline',
      swatches: [
        (label: 'Outline', color: c.outline),
        (label: 'Outline Variant', color: c.outlineVariant),
      ],
    ),
    // The rest of AppColors' own palette — not modeled as ColorScheme
    // roles at all (a Scaffold's background isn't a role ColorScheme
    // has, and favourite/destructive are this app's own semantic colors,
    // used directly rather than through a themed role).
    (
      title: 'App Colors',
      swatches: [
        (label: 'Scaffold Background', color: AppColors.scaffoldBackground),
        (label: 'Favourite', color: AppColors.favourite),
        (label: 'Destructive', color: AppColors.destructive),
      ],
    ),
    // Storage/Dashboard's SizeBar — how a project's disk usage splits
    // between its real content and reclaimable cache/build output.
    (
      title: 'Storage Size',
      swatches: [
        (label: 'Core', color: ProjectSizeType.core.color),
        (label: 'Cache', color: ProjectSizeType.cache.color),
      ],
    ),
    // SnackbarManager's own default background (see its _Toast) — kept
    // as a literal there, same as here, rather than a shared named
    // constant neither really needs elsewhere.
    (
      title: 'Notifications',
      swatches: [(label: 'Warning', color: Colors.orange)],
    ),
  ];
}

ColorScheme material2ColorScheme(Color seed) => ColorScheme.fromSwatch(
      primarySwatch: materialColorFromSeed(seed),
      accentColor: seed,
    );

/// Material 2 never had the M3-only roles [material3SwatchGroups] shows
/// (containers, tertiary, fixed variants, surface tiers, ...) —
/// `ColorScheme.fromSwatch` leaves every one of those at its `ColorScheme`
/// constructor default (most collapse to primary/secondary/surface
/// verbatim), so reusing that same grouping here would just show the same
/// few colors repeated under a dozen different labels. Material 2's own
/// generated artifact was always the swatch itself (its 10 tint/shade
/// steps), so that's shown directly instead, alongside the handful of
/// ColorScheme roles `fromSwatch` actually does set independently.
List<SwatchGroup> material2SwatchGroups(Color seed) {
  final swatch = materialColorFromSeed(seed);
  final scheme = material2ColorScheme(seed);

  return [
    (
      title: 'Primary Swatch',
      swatches: [
        (label: '50', color: swatch.shade50),
        (label: '100', color: swatch.shade100),
        (label: '200', color: swatch.shade200),
        (label: '300', color: swatch.shade300),
        (label: '400', color: swatch.shade400),
        (label: '500', color: swatch.shade500),
        (label: '600', color: swatch.shade600),
        (label: '700', color: swatch.shade700),
        (label: '800', color: swatch.shade800),
        (label: '900', color: swatch.shade900),
      ],
    ),
    (
      title: 'Roles',
      swatches: [
        (label: 'Primary', color: scheme.primary),
        (label: 'On Primary', color: scheme.onPrimary),
        (label: 'Secondary (Accent)', color: scheme.secondary),
        (label: 'On Secondary', color: scheme.onSecondary),
        (label: 'Surface', color: scheme.surface),
        (label: 'On Surface', color: scheme.onSurface),
        (label: 'Error', color: scheme.error),
        (label: 'On Error', color: scheme.onError),
      ],
    ),
  ];
}

/// The [SwatchGroup]s to show for [kind], given the currently picked seed
/// color. Cupertino/thisApp ignore [seedColor] entirely (see each
/// function's own doc for why).
List<SwatchGroup> swatchGroupsFor(
  SchemeKind kind,
  Color seedColor,
  BuildContext context,
) {
  return switch (kind) {
    SchemeKind.material3 =>
      material3SwatchGroups(ColorScheme.fromSeed(seedColor: seedColor)),
    SchemeKind.material2 => material2SwatchGroups(seedColor),
    SchemeKind.cupertino => cupertinoSwatchGroups(context),
    SchemeKind.thisApp => thisAppSwatchGroups(AppTheme.dark().colorScheme),
  };
}
