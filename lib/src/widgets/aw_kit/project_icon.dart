import 'package:flutter/cupertino.dart';

import '../../theme/app_sizes.dart';
import '../ui_kit/icons/entry_icon.dart';

/// A project's app icon if one was found on disk, falling back to a plain
/// folder glyph otherwise.
class ProjectIcon extends StatelessWidget {
  const ProjectIcon({
    super.key,
    required this.iconPath,
    this.size = AppSizes.rowIconSize,
  });

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
