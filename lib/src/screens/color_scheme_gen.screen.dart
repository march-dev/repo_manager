import 'package:flutter/material.dart';

import '../../repo_manager.dart';

/// Placeholder for a future color-scheme generator tool — not implemented
/// yet.
class ColorSchemeGenScreen extends StatelessWidget {
  const ColorSchemeGenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HeaderCard(title: l10n.navColourScheme),
            Expanded(
              child: Center(child: Text(l10n.comingSoonMessage)),
            ),
          ],
        ),
      ),
    );
  }
}
