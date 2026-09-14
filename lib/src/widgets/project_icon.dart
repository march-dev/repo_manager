import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A project's app icon if one was found on disk, falling back to a plain
/// folder glyph otherwise. Always sits on a fixed [size]x[size]
/// surfaceContainerHighest badge — a real icon fills it edge to edge (the
/// badge only shows through any transparent pixels in the image), while
/// the folder-glyph fallback renders smaller and centered on it, the same
/// way an app icon sits on a backdrop tile rather than looking like a
/// real one itself.
class ProjectIcon extends StatelessWidget {
  const ProjectIcon({super.key, required this.iconPath, this.size = 40});

  final String iconPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final glyphSize = size * 0.55;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: iconPath.isEmpty
          ? Icon(CupertinoIcons.folder, size: glyphSize)
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(iconPath),
                width: size,
                height: size,
                fit: BoxFit.cover,
                // iconPath is a path cached at project-discovery time — the
                // file could since have been deleted, moved, or replaced
                // with something unreadable (e.g. a project rebuild), so
                // retrieval here has to be safe against that instead of
                // trusting the path is still good.
                errorBuilder: (context, error, stackTrace) =>
                    Icon(CupertinoIcons.folder, size: glyphSize),
              ),
            ),
    );
  }
}
