import 'package:flinq/flinq.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../repo_manager.dart';

/// Placeholder for a future color-scheme generator tool — not implemented
/// yet.
class ColorSchemeGenScreen extends StatelessWidget {
  const ColorSchemeGenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      body: Column(
        children: [
          HeaderCard(title: l10n.navColourScheme),
          Expanded(
            child: Center(child: Text(l10n.comingSoonMessage)),
          ),
        ],
      ),
    );
  }
}

String toHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

class ColorSchemeGeneratorApp extends StatefulWidget {
  const ColorSchemeGeneratorApp({super.key});

  @override
  State<ColorSchemeGeneratorApp> createState() =>
      _ColorSchemeGeneratorAppState();
}

class _ColorSchemeGeneratorAppState extends State<ColorSchemeGeneratorApp> {
  Color seedColor = const Color(0xFF204080);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: seedColor);

    return MaterialApp(
      title: 'Color Scheme Viewer',
      theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: ColorSchemeDisplayScreen(
        colorScheme: colorScheme,
        seedColor: seedColor,
        onSeedColorPicked: (color) => setState(() => seedColor = color),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ColorSchemeDisplayScreen extends StatelessWidget {
  const ColorSchemeDisplayScreen({
    super.key,
    required this.colorScheme,
    required this.seedColor,
    required this.onSeedColorPicked,
  });

  final ColorScheme colorScheme;
  final Color seedColor;
  final ValueChanged<Color> onSeedColorPicked;

  Map<String, List<MapEntry<String, Color>>> _groupedColorProperties() {
    return {
      'Primary Colors': [
        MapEntry('Primary', colorScheme.primary),
        MapEntry('On Primary', colorScheme.onPrimary),
        MapEntry('Primary Container', colorScheme.primaryContainer),
        MapEntry('On Primary Container', colorScheme.onPrimaryContainer),
      ],
      'Primary Colors (Material 3)': [
        MapEntry('Primary Fixed', colorScheme.primaryFixed),
        MapEntry('On Primary Fixed', colorScheme.onPrimaryFixed),
        MapEntry('Primary Fixed Dim', colorScheme.primaryFixedDim),
        MapEntry('On Primary Fixed Variant', colorScheme.onPrimaryFixedVariant),
      ],
      'Secondary Colors': [
        MapEntry('Secondary', colorScheme.secondary),
        MapEntry('On Secondary', colorScheme.onSecondary),
        MapEntry('Secondary Container', colorScheme.secondaryContainer),
        MapEntry('On Secondary Container', colorScheme.onSecondaryContainer),
      ],
      'Secondary Colors (Material 3)': [
        MapEntry('Secondary Fixed', colorScheme.secondaryFixed),
        MapEntry('On Secondary Fixed', colorScheme.onSecondaryFixed),
        MapEntry('Secondary Fixed Dim', colorScheme.secondaryFixedDim),
        MapEntry(
          'On Secondary Fixed Variant',
          colorScheme.onSecondaryFixedVariant,
        ),
      ],
      'Tertiary Colors': [
        MapEntry('Tertiary', colorScheme.tertiary),
        MapEntry('On Tertiary', colorScheme.onTertiary),
        MapEntry('Tertiary Container', colorScheme.tertiaryContainer),
        MapEntry('On Tertiary Container', colorScheme.onTertiaryContainer),
      ],
      'Tertiary Colors (Material 3)': [
        MapEntry('Tertiary Fixed', colorScheme.tertiaryFixed),
        MapEntry('On Tertiary Fixed', colorScheme.onTertiaryFixed),
        MapEntry('Tertiary Fixed Dim', colorScheme.tertiaryFixedDim),
        MapEntry(
          'On Tertiary Fixed Variant',
          colorScheme.onTertiaryFixedVariant,
        ),
      ],
      'Error Colors': [
        MapEntry('Error', colorScheme.error),
        MapEntry('On Error', colorScheme.onError),
        MapEntry('Error Container', colorScheme.errorContainer),
        MapEntry('On Error Container', colorScheme.onErrorContainer),
      ],
      'Surface Colors': [
        MapEntry('Surface', colorScheme.surface),
        MapEntry('On Surface', colorScheme.onSurface),
        MapEntry('Surface Variant', colorScheme.surfaceContainerHighest),
        MapEntry('On Surface Variant', colorScheme.onSurfaceVariant),
      ],
      'Surface Elevation Colors': [
        MapEntry('Surface Dim', colorScheme.surfaceDim),
        MapEntry('Surface Bright', colorScheme.surfaceBright),
        MapEntry(
          'Surface Container Lowest',
          colorScheme.surfaceContainerLowest,
        ),
        MapEntry('Surface Container Low', colorScheme.surfaceContainerLow),
        MapEntry('Surface Container', colorScheme.surfaceContainer),
        MapEntry('Surface Container High', colorScheme.surfaceContainerHigh),
        MapEntry(
          'Surface Container Highest',
          colorScheme.surfaceContainerHighest,
        ),
      ],
      'Inverse Colors': [
        MapEntry('Inverse Surface', colorScheme.inverseSurface),
        MapEntry('On Inverse Surface', colorScheme.onInverseSurface),
        MapEntry('Inverse Primary', colorScheme.inversePrimary),
      ],
      'Other Colors': [
        MapEntry('Outline', colorScheme.outline),
        MapEntry('Outline Variant', colorScheme.outlineVariant),
        MapEntry('Shadow', colorScheme.shadow),
        MapEntry('Scrim', colorScheme.scrim),
        MapEntry('Surface Tint', colorScheme.surfaceTint),
      ],
    };
  }

  void _pickSeedColor(BuildContext context) async {
    Color pickedColor = seedColor;

    final color = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Seed Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              onColorChanged: (color) => pickedColor = color,
              pickerColor: seedColor,
              enableAlpha: false,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, pickedColor),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );

    if (color != null && color is Color) {
      onSeedColorPicked(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedColors = _groupedColorProperties();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Scheme Details'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickSeedColor(context),
        icon: const Icon(Icons.color_lens),
        label: const Text('Seed Color'),
        backgroundColor: seedColor,
        foregroundColor:
            useWhiteForeground(seedColor) ? Colors.white : Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: groupedColors.entries.mapList(
          (group) => _Group(group: group),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.group});

  final MapEntry<String, List<MapEntry<String, Color>>> group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.key,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
        ),
        const SizedBox(height: 8),
        ...group.value.mapList((entry) => _GroupColors(entry: entry)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _GroupColors extends StatelessWidget {
  const _GroupColors({required this.entry});

  final MapEntry<String, Color> entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: entry.value,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  toHex(entry.value),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
