import 'package:flutter/material.dart';

/// The plain `Scaffold(body: SafeArea(child: ...))` shell every top-level
/// screen in the app starts from — pulled out only so that shape is
/// declared once instead of repeated verbatim in each screen file.
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: body));
  }
}
