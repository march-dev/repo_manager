import 'package:flutter/material.dart';
import 'repo_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dependencies = await DependencyResolver.create();
  initGlobalStores(dependencies);

  runApp(App(dependencies: dependencies));
}
