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
              selectedIndex: _selectedIndex,
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
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
