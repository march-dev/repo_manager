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
      home: const DashboardScreen(),
    );
  }
}
