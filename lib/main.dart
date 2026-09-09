import 'package:flutter/material.dart';
import 'repo_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ProjectRepo.init();

  runApp(const App());
}
