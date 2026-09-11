import 'package:flutter/material.dart';

const _tableCardRadius = 12.0;

/// The rounded, bordered card shell shared by storage.screen.dart's project
/// table and explorer.screen.dart's project list: an optional header row
/// above a scrollable body, with an always-visible themed scrollbar.
///
/// The caller owns the header content and the body's own list/columns (they
/// differ per screen); this only provides the shared chrome, the
/// [ScrollController] lifecycle, and the scrollbar styling so both screens
/// don't duplicate them.
class TableCard extends StatefulWidget {
  const TableCard({super.key, this.header, required this.bodyBuilder});

  /// The row shown above the body, e.g. sortable column labels. Omit for a
  /// body-only card.
  final Widget? header;

  /// Builds the scrollable body. The given [ScrollController] must be
  /// attached to whatever [Scrollable] this builds (a `ListView`, typically)
  /// so the wrapping scrollbar can track it — including for an empty state,
  /// since a scrollbar with `thumbVisibility: true` asserts that its
  /// controller has an attached [ScrollPosition].
  final Widget Function(BuildContext context, ScrollController controller)
      bodyBuilder;

  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(_tableCardRadius),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      // A local Material ancestor, clipped to the same rounded rect as the
      // card itself: InkWell splashes (e.g. a sortable column header) paint
      // onto the nearest ancestor Material, which without this would be
      // Scaffold's own full-screen Material — unclipped by this Container's
      // clipBehavior, since that only clips this Container's own child
      // subtree, not a separate ink layer owned by an ancestor render object.
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(_tableCardRadius),
        child: Column(
          children: [
            if (widget.header != null) ...[
              widget.header!,
              Divider(height: 1, color: colorScheme.outlineVariant),
            ],
            Expanded(
              child: ScrollbarTheme(
                data: ScrollbarThemeData(
                  trackVisibility: const WidgetStatePropertyAll(true),
                  trackColor: WidgetStatePropertyAll(
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  ),
                  trackBorderColor:
                      WidgetStatePropertyAll(colorScheme.outlineVariant),
                  thumbColor: WidgetStatePropertyAll(
                    colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  radius: const Radius.circular(6),
                  thickness: const WidgetStatePropertyAll(8),
                ),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: widget.bodyBuilder(context, _scrollController),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
