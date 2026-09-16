import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../repo_manager.dart';
import '../utils/icon_generator.util.dart';
import '../utils/image.util.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GenerateIconsType selectedType = GenerateIconsType.both;
  String srcPath = '';
  String srcABgPath = '';
  String srcAFgPath = '';

  bool get canGenerate =>
      srcPath.isNotEmpty && srcABgPath.isEmpty && srcAFgPath.isEmpty ||
      srcPath.isNotEmpty && srcABgPath.isNotEmpty && srcAFgPath.isNotEmpty;

  Future<void> selectImage() async {
    final result = await pickImage();

    if (result != null) {
      srcPath = result;
      setState(() {});
    }
  }

  Future<void> selectABgImage() async {
    final result = await pickImage();

    if (result != null) {
      srcABgPath = result;
      setState(() {});
    }
  }

  Future<void> selectAFgImage() async {
    final result = await pickImage();

    if (result != null) {
      srcAFgPath = result;
      setState(() {});
    }
  }

  Future<void> generate() async {
    final dir = await FilePicker.platform.getDirectoryPath();

    await generateIcons(
      srcPath: srcPath,
      srcABgPath: srcABgPath,
      srcAFgPath: srcAFgPath,
      dirToSave: dir ?? '',
      type: selectedType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(child: Text('Select generator type')),
          const SizedBox(height: 12),
          for (final type in GenerateIconsType.values)
            SizedBox(
              width: 420,
              child: RadioListTile(
                onChanged: (value) {
                  selectedType = value!;
                  setState(() {});
                },
                toggleable: false,
                groupValue: selectedType,
                value: type,
                title: Text(type.name),
              ),
            ),
          const SizedBox(height: 36),
          SizedBox(
            width: 420,
            child: ElevatedButton(
              onPressed: selectImage,
              child: const Text('Select source image (at least 192px)'),
            ),
          ),
          if (srcPath.isNotEmpty) Center(child: Text(srcPath)),
          const SizedBox(height: 12),
          SizedBox(
            width: 420,
            child: ElevatedButton(
              onPressed: selectABgImage,
              child: const Text(
                'Select android background source image (at least 432px)',
              ),
            ),
          ),
          if (srcABgPath.isNotEmpty) Center(child: Text(srcABgPath)),
          const SizedBox(height: 12),
          SizedBox(
            width: 420,
            child: ElevatedButton(
              onPressed: selectAFgImage,
              child: const Text(
                'Select android foreground source image (at least 432px)',
              ),
            ),
          ),
          if (srcAFgPath.isNotEmpty) Center(child: Text(srcAFgPath)),
          const SizedBox(height: 36),
          SizedBox(
            width: 400,
            child: FilledButton(
              onPressed: canGenerate ? generate : null,
              child: const Text('Generate'),
            ),
          ),
        ],
      ),
    );
  }
}
