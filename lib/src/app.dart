import 'package:flutter/material.dart';

import '../repo_manager.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF0A84FF),
      secondary: Color(0xFF0A84FF),
      error: Color(0xFFFF453A),
      surface: Color(0xFF2C2C2E),
      onSurface: Color(0xFFF5F5F7),
      surfaceContainerHighest: Color(0xFF3A3A3C),
      outline: Color(0xFF3A3A3C),
      outlineVariant: Color(0xFF3A3A3C),
    );

    return MaterialApp(
      title: 'MD UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        dividerColor: const Color(0xFF3A3A3C),
      ),
      home: const _RootScaffold(),
    );
  }
}

class _RootScaffold extends StatefulWidget {
  const _RootScaffold();

  @override
  State<_RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<_RootScaffold> {
  int _selectedIndex = 1;

  static const _screens = [
    ExplorerScreen(),
    StorageScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant, width: 1),
            ),
            child: NavigationRail(
              backgroundColor: Colors.transparent,
              // Settings lives outside this list (see `trailing`) so it can
              // be pinned to the bottom of the rail; only Explorer/Storage
              // are real, index-selectable destinations here.
              selectedIndex: _selectedIndex < 2 ? _selectedIndex : null,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.folder_open_outlined),
                  selectedIcon: Icon(Icons.folder_open),
                  label: Text('Explorer'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.storage_outlined),
                  selectedIcon: Icon(Icons.storage),
                  label: Text('Storage'),
                ),
              ],
              // Expanded forces this trailing widget to fill the rail's
              // remaining height, so aligning it to the bottom pins Settings
              // there instead of directly under the Storage destination.
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SettingsRailItem(
                      selected: _selectedIndex == 2,
                      onTap: () => setState(() => _selectedIndex = 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

// Mirrors the look of a NavigationRailDestination (icon in a pill-shaped
// selection indicator, label below) since Settings is rendered via
// NavigationRail's `trailing` slot rather than as a real destination, to
// pin it at the bottom of the rail instead of stacking under Storage.
class _SettingsRailItem extends StatelessWidget {
  const _SettingsRailItem({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Matches NavigationRail's own Material 3 defaults (_NavigationRailDefaultsM3)
    // exactly, since a real NavigationRailDestination isn't usable here — the
    // rail only lets destinations live in its top-aligned list, not pinned to
    // the bottom, so Settings is built by hand to look identical to one.
    final iconColor = selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;
    final labelStyle = Theme.of(context)
        .textTheme
        .labelMedium!
        .copyWith(color: colorScheme.onSurface);

    return Material(
      type: MaterialType.transparency,
      child: _PillInkResponse(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                selected ? Icons.settings : Icons.settings_outlined,
                size: 24,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text('Settings', style: labelStyle),
          ],
        ),
      ),
    );
  }
}

// A real NavigationRailDestination's ink response covers its whole tap
// target (icon + label) but visually confines its splash/highlight to the
// 56x32 indicator pill up top — otherwise a tap near the label paints a
// ripple across the text. This mirrors that (see the framework's own
// `_IndicatorInkWell` in navigation_rail.dart) via a fixed-size rect
// centered at the top of whatever bounds this response ends up with.
class _PillInkResponse extends InkResponse {
  const _PillInkResponse({required super.onTap, required super.child})
      : super(
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        );

  static const _indicatorWidth = 56.0;
  static const _indicatorHeight = 32.0;

  @override
  RectCallback? getRectCallback(RenderBox referenceBox) {
    final width = referenceBox.size.width;
    return () => Rect.fromLTWH(
          width / 2 - _indicatorWidth / 2,
          0,
          _indicatorWidth,
          _indicatorHeight,
        );
  }
}
