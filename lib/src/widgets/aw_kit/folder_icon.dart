import 'package:flutter/cupertino.dart';

import '../../theme/app_sizes.dart';
import '../ui_kit/icons/entry_icon.dart';

/// A container-directory entry's icon — e.g. a workspace folder that groups
/// several packages but isn't a package itself. Never has an icon of its
/// own to show (there's no file on disk for it to come from), so this
/// always renders as [EntryIcon]'s fallback glyph, using a "stack of
/// packages" icon rather than a plain folder glyph so it doesn't read as
/// indistinguishable from a real project that simply has no discovered
/// icon (see [ProjectIcon]).
class FolderIcon extends StatelessWidget {
  const FolderIcon({super.key, this.size = AppSizes.rowIconSize});

  final double size;

  @override
  Widget build(BuildContext context) {
    return EntryIcon(
      iconPath: '',
      size: size,
      fallbackIcon: CupertinoIcons.square_stack_3d_up,
    );
  }
}
