import 'package:flutter/material.dart';

// Sized close to a typical desktop icon-button (icon size 18) rather than
// Material's much roomier default menu rows — this menu is meant to read
// as a fast, dense desktop context menu.
const compactMenuIconSize = 16.0;
const compactMenuImageSize = 13.0;
const _compactMenuItemHeight = 32.0;

// White-ish rather than colorScheme.outlineVariant: outlineVariant reads
// too close to the (also-themed) background to actually show up against
// it, whereas a translucent white edge stays visible in both light and
// dark mode.
const menuBorderColor = Color(0x40FFFFFF);

// A little breathing room between a submenu and the button that opened it,
// rather than the submenu sitting flush against it.
const submenuGap = 4.0;

const menuDivider = Divider(height: 4, thickness: 1, color: menuBorderColor);

/// The shared button style for every item in a compact context menu built
/// from these primitives.
ButtonStyle compactMenuButtonStyle(BuildContext context) => ButtonStyle(
      visualDensity: VisualDensity.compact,
      minimumSize:
          const WidgetStatePropertyAll(Size(0, _compactMenuItemHeight)),
      padding:
          const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
      textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.bodyMedium),
    );

/// The shared surface style for a compact context menu (and its submenus):
/// same shape/fill as this app's cards (12px rounded corners,
/// surfaceContainerHighest as the fill) so the menu reads as another one of
/// the app's own cards, not Material's default elevated menu surface (a
/// plain white/dark card with a drop shadow). The border uses a white-ish
/// tint rather than the cards' outlineVariant, since outlineVariant sat too
/// close to this menu's own background to actually be visible against it.
MenuStyle compactMenuStyle(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return MenuStyle(
    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    visualDensity: VisualDensity.compact,
    elevation: const WidgetStatePropertyAll(0),
    // Material's default surfaceTint/shadow would otherwise blend into the
    // border and mute it relative to a plain Divider — kill both so the
    // border reads at the same full-strength color as the divider.
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    backgroundColor: WidgetStatePropertyAll(
      colorScheme.surfaceContainerHighest,
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: menuBorderColor, width: 1),
      ),
    ),
  );
}

// Image (unlike Icon) has no inherent size of its own — without an
// explicit width/height it renders at its source asset's actual pixel
// dimensions, which would blow up a menu row. menuIcon() is the one place
// that sizes every icon shown in a compact context menu, so nothing can
// skip it by accident.
Widget menuIcon(Widget child) {
  return Container(
    alignment: Alignment.center,
    width: compactMenuIconSize,
    height: compactMenuIconSize,
    child: child,
  );
}

/// Wraps a region of the app (a table, a dialog's row list, ...) so
/// [showContextMenu] can be called from anywhere inside it. Needed because
/// [MenuAnchor] — unlike the old `showMenu`, which this replaced — has to
/// already be mounted in the tree before it can be opened; there's no
/// one-shot "just show a menu here" call for it.
///
/// [MenuAnchor]'s own [SubmenuButton] is what actually buys the thing the
/// old showMenu-based version couldn't do: a submenu that cascades open on
/// hover, the way a native macOS context menu does, rather than requiring a
/// click to drill down and replace the current menu.
class ContextMenuRegion extends StatefulWidget {
  const ContextMenuRegion({super.key, required this.child});

  final Widget child;

  @override
  State<ContextMenuRegion> createState() => _ContextMenuRegionState();
}

class _ContextMenuRegionState extends State<ContextMenuRegion> {
  final _controller = MenuController();
  List<Widget> _menuChildren = const [];
  bool _isOpen = false;

  void _openAt(Offset globalPosition, List<Widget> menuChildren) {
    final box = context.findRenderObject()! as RenderBox;
    setState(() => _menuChildren = menuChildren);
    _controller.open(position: box.globalToLocal(globalPosition));
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      style: compactMenuStyle(context),
      // MenuAnchor's own consumeOutsideTap is meant to cover this same
      // "don't let the dismissing tap also hit whatever's underneath"
      // case, but it works by racing the tap into the gesture arena
      // against a dummy recognizer — in practice a row's own InkWell can
      // still end up winning that race and firing its onTap. The
      // Positioned.fill GestureDetector below is a blunter but reliable
      // fix: while the menu is open, it sits directly on top of the
      // anchor's own child (though still underneath the menu itself,
      // which renders in its own overlay entry above both), so a tap
      // outside the menu is guaranteed to hit *it* first, closing the
      // menu without ever reaching the row underneath.
      consumeOutsideTap: true,
      onOpen: () => setState(() => _isOpen = true),
      onClose: () => setState(() => _isOpen = false),
      menuChildren: _menuChildren,
      child: Stack(
        children: [
          widget.child,
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _controller.close,
                onSecondaryTap: _controller.close,
              ),
            ),
        ],
      ),
    );
  }
}

/// Opens [menuChildren] at [globalPosition], inside the nearest ancestor
/// [ContextMenuRegion].
void showContextMenu(
  BuildContext context,
  Offset globalPosition,
  List<Widget> menuChildren,
) {
  final state = context.findAncestorStateOfType<_ContextMenuRegionState>();
  assert(
    state != null,
    'showContextMenu needs a ContextMenuRegion ancestor to open into.',
  );
  state!._openAt(globalPosition, menuChildren);
}
