import 'package:flutter/cupertino.dart';

import '../ui_kit/icons/entry_icon.dart';

/// A project's app icon if one was found on disk, falling back to a plain
/// folder glyph otherwise.
class ProjectIcon extends StatelessWidget {
  const ProjectIcon({super.key, required this.iconPath, this.size = 40});

  final String iconPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return EntryIcon(
      iconPath: iconPath,
      size: size,
      fallbackIcon: CupertinoIcons.folder,
    );
  }
}
