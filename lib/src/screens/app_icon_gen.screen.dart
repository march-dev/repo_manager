import 'package:flutter/material.dart';

import '../../repo_manager.dart';

/// Placeholder for a future app-icon generator tool — not implemented yet.
class AppIconGenScreen extends StatelessWidget {
  const AppIconGenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HeaderCard(title: 'App Icon'),
            Expanded(
              child: Center(child: Text('Coming soon.')),
            ),
          ],
        ),
      ),
    );
  }
}
