import 'dart:io';

import 'package:flutter/cupertino.dart';

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
      ),
    );
  }
}
