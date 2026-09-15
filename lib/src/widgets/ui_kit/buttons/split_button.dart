import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import '../indicators/loading_spinner.dart';

/// One entry in a [SplitButton]'s dropdown.
class SplitButtonMenuItem<T> {
  const SplitButtonMenuItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// A split button: the main body triggers [onPressed], while the chevron
/// opens a menu of [menuItems] — e.g. a primary action alongside a less
/// common variant of it (a recursive add, a "save as", ...), scoping that
/// choice to the action it modifies rather than it floating as an
/// unrelated control elsewhere on the page.
class SplitButton<T> extends StatelessWidget {
  const SplitButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.menuItems,
    required this.onMenuItemSelected,
    this.loading = false,
    this.menuTooltip,
    this.height = 32,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final List<SplitButtonMenuItem<T>> menuItems;
  final ValueChanged<T> onMenuItemSelected;

  /// Swaps [icon] for a spinner and disables both the main body and the
  /// menu, for an action currently in flight.
  final bool loading;
  final String? menuTooltip;
  final double height;

  /// Both default to the theme's primary color pairing.
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = backgroundColor ?? colorScheme.primary;
    final foreground = foregroundColor ?? colorScheme.onPrimary;

    return Material(
      color: background,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(height / 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: loading ? null : onPressed,
            child: SizedBox(
              height: height,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      LoadingSpinner(color: foreground)
                    else
                      Icon(icon, size: AppSizes.iconMedium, color: foreground),
                    const SizedBox(width: AppSizes.spacing8),
                    Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall!
                          .copyWith(color: foreground),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: height * 0.6,
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              color: foreground.withValues(alpha: 0.35),
            ),
          ),
          PopupMenuButton<T>(
            enabled: !loading,
            tooltip: menuTooltip,
            onSelected: onMenuItemSelected,
            itemBuilder: (context) => [
              for (final item in menuItems)
                PopupMenuItem(value: item.value, child: Text(item.label)),
            ],
            child: SizedBox(
              height: height,
              width: 36,
              child: Center(
                child: Icon(
                  CupertinoIcons.chevron_down,
                  size: AppSizes.iconSmall,
                  color: foreground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
