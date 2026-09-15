import 'dart:io';

import 'package:flutter/material.dart';

/// An on-disk image if one was found (a project's app icon, ...), falling
/// back to [fallbackIcon] otherwise. Always sits on a fixed [size]x[size]
/// surfaceContainerHighest badge — a real image fills it edge to edge (the
/// badge only shows through any transparent pixels in the image), while the
/// fallback glyph renders smaller and centered on it, the same way an app
/// icon sits on a backdrop tile rather than looking like a real one itself.
class EntryIcon extends StatelessWidget {
  const EntryIcon({
    super.key,
    required this.iconPath,
    required this.fallbackIcon,
    this.size = 40,
  });

  final String iconPath;
  final double size;
  final IconData fallbackIcon;

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
          ? Icon(fallbackIcon, size: glyphSize)
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(iconPath),
                width: size,
                height: size,
                fit: BoxFit.cover,
                // iconPath is a path cached at discovery time — the file
                // could since have been deleted, moved, or replaced with
                // something unreadable (e.g. a project rebuild), so
                // retrieval here has to be safe against that instead of
                // trusting the path is still good.
                errorBuilder: (context, error, stackTrace) =>
                    Icon(fallbackIcon, size: glyphSize),
              ),
            ),
    );
  }
}
