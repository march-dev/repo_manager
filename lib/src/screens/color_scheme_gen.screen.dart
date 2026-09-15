import 'package:flutter/material.dart';

import '../../repo_manager.dart';

/// Placeholder for a future color-scheme generator tool — not implemented
/// yet.
class ColorSchemeGenScreen extends StatelessWidget {
  const ColorSchemeGenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HeaderCard(title: 'Colour Scheme'),
            Expanded(
              child: Center(child: Text('Coming soon.')),
            ),
          ],
        ),
      ),
    );
  }
}
