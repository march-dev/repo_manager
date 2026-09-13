import 'dart:io';

import 'package:flutter/cupertino.dart';

/// A project's app icon if one was found on disk, falling back to a plain
/// folder glyph otherwise.
class ProjectIcon extends StatelessWidget {
  const ProjectIcon({super.key, required this.iconPath, this.size = 40});

  final String iconPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (iconPath.isEmpty) {
      return Icon(CupertinoIcons.folder, size: size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(iconPath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        // iconPath is a path cached at project-discovery time — the file
        // could since have been deleted, moved, or replaced with something
        // unreadable (e.g. a project rebuild), so retrieval here has to be
        // safe against that instead of trusting the path is still good.
        errorBuilder: (context, error, stackTrace) =>
            Icon(CupertinoIcons.folder, size: size),
      ),
    );
  }
}
