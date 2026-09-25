import 'package:flutter/material.dart';
import 'repo_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();

  final dependencies = await DependencyResolver.create();

  // The 3 global (Provider-free) stores that also need an AppLocalizations
  // aren't built here — there's no BuildContext yet. See
  // _RootScaffoldState.build() (app.dart), the first point one exists.
  runApp(App(dependencies: dependencies));
}
