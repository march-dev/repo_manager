import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repo_manager.dart';

class App extends StatelessWidget {
  const App({super.key, required this.dependencies});

  final DependencyResolver dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Lets SnackbarManager (and anything else with no BuildContext of
      // its own, e.g. a repo/store reporting a failed operation) reach
      // the root Overlay without needing one passed in.
      navigatorKey: SnackbarManager.navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.dark(),
      home: _RootScaffold(dependencies: dependencies),
    );
  }
}

class _RootScaffold extends StatefulWidget {
  const _RootScaffold({required this.dependencies});

  final DependencyResolver dependencies;

  @override
  State<_RootScaffold> createState() => _RootScaffoldState();
}

// One entry in the rail: a real destination (an index into _screens), a
// group title (rendered as a small muted heading), a plain divider line,
// or an action (like "Other"/"Back" below — a row that runs a callback
// instead of switching _screens) — plain NavigationRail has no notion of
// sectioning destinations at all, so the whole rail is hand-built from
// this list instead (see _RailItem/_RailGroupTitle below), the way
// _SettingsRailItem already had to be for the same reason (pinning it
// below everything else).
class _RailEntry {
  const _RailEntry.destination({
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  })  : title = null,
        isDivider = false,
        onAction = null,
        actionSelected = false;

  const _RailEntry.groupTitle(this.title)
      : index = null,
        icon = null,
        selectedIcon = null,
        label = null,
        isDivider = false,
        onAction = null,
        actionSelected = false;

  const _RailEntry.divider()
      : index = null,
        icon = null,
        selectedIcon = null,
        label = null,
        title = null,
        isDivider = true,
        onAction = null,
        actionSelected = false;

  // "Other" (swaps the rail to its secondary Tools page) and that page's
  // own "Back" (swaps it back) — neither is a real screen index, so
  // selection/tap are driven by [onAction]/[actionSelected] instead of
  // [index].
  const _RailEntry.action({
    required this.icon,
    required this.label,
    required VoidCallback this.onAction,
    this.actionSelected = false,
  })  : index = null,
        selectedIcon = icon,
        title = null,
        isDivider = false;

  final int? index;
  final IconData? icon;
  final IconData? selectedIcon;
  final String? label;
  final String? title;
  final bool isDivider;
  final VoidCallback? onAction;
  final bool actionSelected;
}

class _RootScaffoldState extends State<_RootScaffold> {
  int _selectedIndex = 0;

  // Which of the rail's two pages is showing — independent of
  // _selectedIndex, so switching pages never changes (or is changed by)
  // which screen is actually on-screen; only tapping a real destination
  // does that. Starts back on the main page every time "Other" is
  // entered fresh (see _railEntries' onAction below) rather than being
  // remembered, since it's a drill-down, not a real destination of its
  // own.
  var _showingOtherPage = false;

  // Not a static const list any more — Storage/System Cleaner/Settings all
  // need to know whether they're the actually-visible tab (see their own
  // `selected` param's doc) to safely bind F5 without every other
  // IndexedStack-mounted-but-hidden screen racing it for keyboard focus.
  // Rebuilding this list on every _selectedIndex change is cheap (plain
  // StatelessWidget constructor calls); IndexedStack still reuses each
  // screen's own Element/State by position, so this doesn't tear anything
  // down.
  List<Widget> get _screens => [
        DashboardScreen(selected: _selectedIndex == _dashboardIndex),
        ExplorerScreen(selected: _selectedIndex == _explorerIndex),
        StorageScreen(selected: _selectedIndex == _storageIndex),
        const ColourSchemeGenScreen(),
        const AppIconGenScreen(),
        SystemCleanerScreen(selected: _selectedIndex == _systemCleanerIndex),
        SettingsScreen(selected: _selectedIndex == _settingsIndex),
      ];

  // Each screen's own index — see their only uses above.
  static const _dashboardIndex = 0;
  static const _explorerIndex = 1;
  static const _storageIndex = 2;
  static const _colourSchemeIndex = 3;
  static const _appIconIndex = 4;
  static const _systemCleanerIndex = 5;

  // Settings is pinned below the rest of the rail (see the Column split
  // below) rather than living in either list, so it doesn't need its own
  // index here. Methods rather than static const lists — the labels come
  // from AppLocalizations, which needs a BuildContext, so these can no
  // longer be built once at compile time.
  //
  // The rail's main page — everything except the two generator screens,
  // which stay behind their own "Other" drill-down page (see
  // _otherRailEntries); System Cleaner sits directly in Tools instead,
  // an everyday utility rather than a one-off generator.
  List<_RailEntry> _railEntries(AppLocalizations l10n) => [
        _RailEntry.destination(
          index: _dashboardIndex,
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          label: l10n.navDashboard,
        ),
        const _RailEntry.divider(),
        _RailEntry.groupTitle(l10n.navProjectGroup),
        _RailEntry.destination(
          index: _explorerIndex,
          icon: Icons.folder_open_outlined,
          selectedIcon: Icons.folder_open,
          label: l10n.navExplorer,
        ),
        _RailEntry.destination(
          index: _storageIndex,
          icon: Icons.storage_outlined,
          selectedIcon: Icons.storage,
          label: l10n.navStorage,
        ),
        const _RailEntry.divider(),
        _RailEntry.groupTitle(l10n.navToolsGroup),
        _RailEntry.destination(
          index: _systemCleanerIndex,
          icon: Icons.cleaning_services_outlined,
          selectedIcon: Icons.cleaning_services,
          label: l10n.navSystemCleaner,
        ),
        _RailEntry.action(
          icon: Icons.more_horiz,
          label: l10n.navOther,
          onAction: () => setState(() => _showingOtherPage = true),
          // Highlighted whenever the screen actually on-screen is one of
          // this page's own destinations, even though the rail itself is
          // back showing the main page — the same way a parent nav item
          // stays highlighted while a nested route under it is active.
          actionSelected: _selectedIndex == _colourSchemeIndex ||
              _selectedIndex == _appIconIndex,
        ),
      ];

  // The rail's secondary page, entered via "Other" above — a plain "back
  // to the main page" action, then the two generator screens that used to
  // sit directly in Tools.
  List<_RailEntry> _otherRailEntries(AppLocalizations l10n) => [
        _RailEntry.action(
          icon: Icons.arrow_back,
          label: l10n.navBack,
          onAction: () => setState(() => _showingOtherPage = false),
        ),
        const _RailEntry.divider(),
        _RailEntry.groupTitle(l10n.navGeneratorsGroup),
        _RailEntry.destination(
          index: _colourSchemeIndex,
          icon: Icons.palette_outlined,
          selectedIcon: Icons.palette,
          label: l10n.navColourScheme,
        ),
        _RailEntry.destination(
          index: _appIconIndex,
          icon: Icons.image_outlined,
          selectedIcon: Icons.image,
          label: l10n.navAppIcon,
        ),
      ];

  // Settings' own index — the last screen in _screens, one past every
  // real destination above.
  static const _settingsIndex = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Provided here (rather than inside ExplorerScreen/StorageScreen) so
    // DashboardScreen — a sibling in the IndexedStack below, not a
    // descendant of either — can read the same live project list/
    // favourites and size data for its own quick-launch/reclaimable-
    // storage sections, instead of each screen scanning the filesystem
    // into its own separate copy.
    final dependencies = widget.dependencies;

    return MultiProvider(
      providers: [
        Provider<DependencyResolver>.value(value: dependencies),
        // Domain layer: one use-case class per feature area, each wired to
        // the repo(s) it needs plus the AppLocalizations its own failure
        // messages use (see each use case's own doc). Registered above
        // every screen state below, since every one of them delegates its
        // actual business logic to one or more of these.
        Provider<CollectionsUseCases>(
          create: (_) =>
              CollectionsUseCases(dependencies.collectionsRepo, l10n),
        ),
        Provider<FavouritesUseCases>(
          create: (_) => FavouritesUseCases(dependencies.favouritesRepo, l10n),
        ),
        Provider<IdeLauncherUseCases>(
          create: (_) =>
              IdeLauncherUseCases(dependencies.ideLauncherRepo, l10n),
        ),
        Provider<ProjectScannerUseCases>(
          create: (_) =>
              ProjectScannerUseCases(dependencies.projectScanner, l10n),
        ),
        Provider<ProjectSizeUseCases>(
          create: (_) =>
              ProjectSizeUseCases(dependencies.projectSizeRepo, l10n),
        ),
        Provider<ProjectCompositionUseCases>(
          create: (_) => ProjectCompositionUseCases(
            dependencies.projectCompositionRepo,
            l10n,
          ),
        ),
        Provider<AppSettingsUseCases>(
          create: (_) => AppSettingsUseCases(dependencies.appSettingsRepo),
        ),
        Provider<ProjectDirectoryUseCases>(
          create: (_) => ProjectDirectoryUseCases(
            dependencies.projectDirectoryRepo,
            l10n,
          ),
        ),
        Provider<SystemCleanerUseCases>(
          create: (_) => SystemCleanerUseCases(const SystemCleanerRepo(), l10n),
        ),
        // Screen state: reactive, UI-facing observable data, each backed by
        // the use cases above rather than holding any business logic of its
        // own.
        Provider<CollectionsState>(
          create: (context) =>
              CollectionsState(context.read<CollectionsUseCases>()),
        ),
        // State for the shared "project actions" widget group (right-click
        // menu, quick-launch tile, details page) — see its own doc for
        // why that's a widget-oriented state of its own rather than one
        // tied to Explorer/Storage/Dashboard specifically, even though all
        // three read it to hand off to that group.
        Provider<ProjectActionsState>(
          create: (context) => ProjectActionsState(
            ideLauncherUseCases: context.read<IdeLauncherUseCases>(),
            projectScannerUseCases: context.read<ProjectScannerUseCases>(),
            favouritesUseCases: context.read<FavouritesUseCases>(),
            projectSizeUseCases: context.read<ProjectSizeUseCases>(),
            projectCompositionUseCases:
                context.read<ProjectCompositionUseCases>(),
          ),
        ),
        Provider<ExplorerState>(
          create: (context) => ExplorerState(
            projectScannerUseCases: context.read<ProjectScannerUseCases>(),
            favouritesUseCases: context.read<FavouritesUseCases>(),
            appSettingsUseCases: context.read<AppSettingsUseCases>(),
            collectionsState: context.read<CollectionsState>(),
            ideLauncherUseCases: context.read<IdeLauncherUseCases>(),
            projectDirectoryUseCases: context.read<ProjectDirectoryUseCases>(),
          ),
        ),
        Provider<StorageState>(
          create: (context) => StorageState(
            projectScannerUseCases: context.read<ProjectScannerUseCases>(),
            appSettingsUseCases: context.read<AppSettingsUseCases>(),
            projectSizeUseCases: context.read<ProjectSizeUseCases>(),
            ideLauncherUseCases: context.read<IdeLauncherUseCases>(),
            projectDirectoryUseCases: context.read<ProjectDirectoryUseCases>(),
          ),
        ),
        // Provided here (rather than locally, the way AppIconGenScreen/
        // ColourSchemeGenScreen scope their own one-off state) for the same
        // reason StorageState is: so it stays mounted/scanned for the whole
        // app session instead of redoing its filesystem walk every time
        // System Cleaner's tab is opened, and so DashboardState below can
        // read its same live totals for Size Overview.
        Provider<SystemCleanerState>(
          create: (context) => SystemCleanerState(
            useCases: context.read<SystemCleanerUseCases>(),
          ),
        ),
        Provider<DashboardState>(
          create: (context) => DashboardState(
            explorerState: context.read<ExplorerState>(),
            storageState: context.read<StorageState>(),
            systemCleanerState: context.read<SystemCleanerState>(),
            projectActionsState: context.read<ProjectActionsState>(),
          ),
        ),
      ],
      child: Scaffold(
        body: Row(
          children: [
            _NavigationRail(
              entries: _showingOtherPage
                  ? _otherRailEntries(l10n)
                  : _railEntries(l10n),
              selectedIndex: _selectedIndex,
              settingsIndex: _settingsIndex,
              settingsLabel: l10n.navSettings,
              onSelect: (index) => setState(() => _selectedIndex = index),
            ),
            // An IndexedStack (rather than just swapping in _screens[index])
            // keeps every screen — and the Provider/store it owns — mounted
            // for the whole app session, so switching tabs doesn't tear down
            // and recreate e.g. StorageState, which would otherwise reload
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

class _NavigationRail extends StatelessWidget {
  const _NavigationRail({
    required this.entries,
    required this.selectedIndex,
    required this.settingsIndex,
    required this.settingsLabel,
    required this.onSelect,
  });

  final List<_RailEntry> entries;
  final int selectedIndex;
  final int settingsIndex;
  final String settingsLabel;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return RailContainer(
      child: Column(
        children: [
          Expanded(
            child: _RailEntryList(
              entries: entries,
              selectedIndex: selectedIndex,
              onSelect: onSelect,
            ),
          ),
          _RailDivider(color: colorScheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing12),
            child: RailItem(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: settingsLabel,
              selected: selectedIndex == settingsIndex,
              onTap: () => onSelect(settingsIndex),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailEntryList extends StatelessWidget {
  const _RailEntryList({
    required this.entries,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_RailEntry> entries;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // This narrow 88px rail has no room for a scrollbar without it
    // crowding the icons/labels next to it — ScrollConfiguration.copyWith
    // is needed on top of just not wrapping this in a Scrollbar, since
    // desktop platforms otherwise add one of their own by default.
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          if (entry.isDivider) {
            return _RailDivider(color: colorScheme.outlineVariant);
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing4),
            child: entry.title != null
                ? _RailGroupTitle(entry.title!)
                : RailItem(
                    icon: entry.icon!,
                    selectedIcon: entry.selectedIcon!,
                    label: entry.label!,
                    selected: entry.onAction != null
                        ? entry.actionSelected
                        : selectedIndex == entry.index,
                    onTap: entry.onAction ?? () => onSelect(entry.index!),
                  ),
          );
        },
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
    return Divider(
      height: 17,
      indent: AppSizes.spacing16,
      endIndent: AppSizes.spacing16,
      color: color,
    );
  }
}

class _RailGroupTitle extends StatelessWidget {
  const _RailGroupTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing4),
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

// RailItem/RailContainer used to live here, hand-built for this rail —
// now shared with project_details.screen.dart's own back button (styled
// to match this rail's "Other" page's own Back row), see
// widgets/ui_kit/scaffold/rail_item.dart and rail_container.dart.
