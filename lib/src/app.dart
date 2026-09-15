import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repo_manager.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.dark(),
      home: const _RootScaffold(),
    );
  }
}

class _RootScaffold extends StatefulWidget {
  const _RootScaffold();

  @override
  State<_RootScaffold> createState() => _RootScaffoldState();
}

// One entry in the rail: a real destination (an index into _screens), a
// group title (rendered as a small muted heading), or a plain divider
// line — plain NavigationRail has no notion of sectioning destinations at
// all, so the whole rail is hand-built from this list instead (see
// _RailItem/_RailGroupTitle below), the way _SettingsRailItem already had
// to be for the same reason (pinning it below everything else).
class _RailEntry {
  const _RailEntry.destination({
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  })  : title = null,
        isDivider = false;

  const _RailEntry.groupTitle(this.title)
      : index = null,
        icon = null,
        selectedIcon = null,
        label = null,
        isDivider = false;

  const _RailEntry.divider()
      : index = null,
        icon = null,
        selectedIcon = null,
        label = null,
        title = null,
        isDivider = true;

  final int? index;
  final IconData? icon;
  final IconData? selectedIcon;
  final String? label;
  final String? title;
  final bool isDivider;
}

class _RootScaffoldState extends State<_RootScaffold> {
  int _selectedIndex = 0;

  static const _screens = [
    DashboardScreen(),
    ExplorerScreen(),
    StorageScreen(),
    ColorSchemeGenScreen(),
    AppIconGenScreen(),
    SettingsScreen(),
  ];

  // Settings is pinned below the rest of the rail (see the Column split
  // below) rather than living in this list, so it doesn't need its own
  // index here. A method rather than a static const list — the labels come
  // from AppLocalizations, which needs a BuildContext, so this can no
  // longer be built once at compile time.
  List<_RailEntry> _railEntries(AppLocalizations l10n) => [
        _RailEntry.destination(
          index: 0,
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: l10n.navDashboard,
        ),
        const _RailEntry.divider(),
        _RailEntry.groupTitle(l10n.navProjectGroup),
        _RailEntry.destination(
          index: 1,
          icon: Icons.folder_open_outlined,
          selectedIcon: Icons.folder_open,
          label: l10n.navExplorer,
        ),
        _RailEntry.destination(
          index: 2,
          icon: Icons.storage_outlined,
          selectedIcon: Icons.storage,
          label: l10n.navStorage,
        ),
        const _RailEntry.divider(),
        _RailEntry.groupTitle(l10n.navToolsGroup),
        _RailEntry.destination(
          index: 3,
          icon: Icons.palette_outlined,
          selectedIcon: Icons.palette,
          label: l10n.navColourScheme,
        ),
        _RailEntry.destination(
          index: 4,
          icon: Icons.image_outlined,
          selectedIcon: Icons.image,
          label: l10n.navAppIcon,
        ),
      ];

  // Settings' own index — the last screen in _screens, one past every
  // real _railEntries destination.
  static const _settingsIndex = 5;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Provided here (rather than inside ExplorerScreen/StorageScreen) so
    // DashboardScreen — a sibling in the IndexedStack below, not a
    // descendant of either — can read the same live project list/
    // favourites and size data for its own quick-launch/reclaimable-
    // storage sections, instead of each screen scanning the filesystem
    // into its own separate copy.
    return MultiProvider(
      providers: [
        Provider<ExplorerStore>(create: (_) => ExplorerStore()),
        Provider<StorageStore>(create: (_) => StorageStore()),
      ],
      child: Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 88,
              child: AppCard(
                margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                padding: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            for (final entry in _railEntries(l10n))
                              if (entry.isDivider)
                                _RailDivider(color: colorScheme.outlineVariant)
                              else
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: entry.title != null
                                      ? _RailGroupTitle(entry.title!)
                                      : _RailItem(
                                          icon: entry.icon!,
                                          selectedIcon: entry.selectedIcon!,
                                          label: entry.label!,
                                          selected:
                                              _selectedIndex == entry.index,
                                          onTap: () => setState(
                                            () => _selectedIndex = entry.index!,
                                          ),
                                        ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    _RailDivider(color: colorScheme.outlineVariant),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _RailItem(
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings,
                        label: l10n.navSettings,
                        selected: _selectedIndex == _settingsIndex,
                        onTap: () =>
                            setState(() => _selectedIndex = _settingsIndex),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // An IndexedStack (rather than just swapping in _screens[index])
            // keeps every screen — and the Provider/store it owns — mounted
            // for the whole app session, so switching tabs doesn't tear down
            // and recreate e.g. StorageStore, which would otherwise reload
            // and rescan everything from scratch on every visit.
            Expanded(
              child: IndexedStack(index: _selectedIndex, children: _screens),
            ),
          ],
        ),
      ),
    );
  }
}

// A small muted uppercase heading between groups of rail items — plain
// NavigationRail has no equivalent, since it only supports a flat
// destinations list.
// A plain section-break line — indented off the rail's own edges so it
// doesn't visually collide with the outer Container's own border.
class _RailDivider extends StatelessWidget {
  const _RailDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Divider(height: 17, indent: 16, endIndent: 16, color: color);
  }
}

class _RailGroupTitle extends StatelessWidget {
  const _RailGroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontSize: 10,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
      ),
    );
  }
}

// Mirrors the look of a NavigationRailDestination (icon in a pill-shaped
// selection indicator, label below) — the whole rail is built from these
// by hand (see _RootScaffoldState) rather than a real NavigationRail,
// since that widget has no way to interleave group titles between
// destinations or pin one below a scrollable list of them.
class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Matches NavigationRail's own Material 3 defaults (_NavigationRailDefaultsM3)
    // exactly, since a real NavigationRailDestination isn't usable here.
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
                selected ? selectedIcon : icon,
                size: 24,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: labelStyle, textAlign: TextAlign.center),
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
