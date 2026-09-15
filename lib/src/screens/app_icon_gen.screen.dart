import 'package:flutter/material.dart';

import '../../repo_manager.dart';

/// Placeholder for a future app-icon generator tool — not implemented yet.
class AppIconGenScreen extends StatelessWidget {
  const AppIconGenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      body: Column(
        children: [
          HeaderCard(title: l10n.navAppIcon),
          Expanded(
            child: Center(child: Text(l10n.comingSoonMessage)),
          ),
        ],
      ),
    );
  }
}
