import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'table_card.dart';
import 'table_header_row.dart';

/// A column in an [AppTable]'s scheme. [FlexColumn]/[FixedColumn] each
/// reserve one cell (filled by [AppTable.headerBuilder]/[AppTable.rowBuilder]
/// in the same order they appear here); [DividerColumn] reserves none — it
/// renders as a real `VerticalDivider` in the header and an invisible 1px
/// gap in body rows (matching header/row alignment without cluttering every
/// row with vertical lines).
sealed class AppTableColumn {
  const AppTableColumn();
}

class FlexColumn extends AppTableColumn {
  const FlexColumn({this.flex = 1});
  final int flex;
}

class FixedColumn extends AppTableColumn {
  const FixedColumn(this.width);
  final double width;
}

// Named distinctly from Flutter's own Divider (used internally to render
// this) to avoid a same-name collision for any file importing both.
class DividerColumn extends AppTableColumn {
  const DividerColumn();
}

/// One section of an [AppTable.sectioned] table: [section] is whatever data
/// [AppTable.sectionBuilder] needs to render that section's header (a
/// folder path, a date bucket, ...), and [items] are the rows under it.
class AppTableSection<S, T> {
  const AppTableSection({required this.section, required this.items});

  final S section;
  final List<T> items;
}

/// Base type for anything an [AppTable.headerBuilder] can return — the four
/// standard cells below cover most columns, but a table can also extend
/// this directly for a one-off custom header cell (e.g. an icon-only
/// toggle button) that still fits the same `List<AppTableHeaderCell>`
/// contract as everything else.
abstract class AppTableHeaderCell extends StatelessWidget {
  const AppTableHeaderCell({super.key});
}

/// A blank header cell — for a column with no label (e.g. an actions
/// column), so its reserved width still lines up with the rows below it.
class HeaderEmpty extends AppTableHeaderCell {
  const HeaderEmpty({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

const _headerTextStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.4,
);

/// A plain, non-interactive header label.
class HeaderText extends AppTableHeaderCell {
  const HeaderText(
    this.text, {
    super.key,
    this.alignment = Alignment.centerLeft,
    this.padding = EdgeInsets.zero,
  });

  final String text;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Padding(
      padding: padding,
      child: Align(
        alignment: alignment,
        child: Text(
          text.toUpperCase(),
          style: _headerTextStyle.copyWith(color: color),
        ),
      ),
    );
  }
}

/// A tappable header label with no sort arrow (e.g. a column with a "Clear"
/// action rather than a sort order).
class HeaderButton extends AppTableHeaderCell {
  const HeaderButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.alignment = Alignment.centerLeft,
    this.padding = EdgeInsets.zero,
  });

  final String text;
  final VoidCallback onPressed;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final color =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    // InkWell must be the outer widget so it inherits the full column size
    // from its parent (Expanded/SizedBox) rather than shrinking to the
    // label's own content; ClipRect confines the splash to this column.
    return ClipRect(
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: padding,
          child: Align(
            alignment: alignment,
            child: Text(
              text.toUpperCase(),
              style: _headerTextStyle.copyWith(color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// A sortable header label with an arrow reflecting the current sort order.
/// [ascending] is the *active* state — null means this column isn't the
/// current sort column, so no arrow is shown (the default look, since only
/// one sortable column is normally active at a time); a table with several
/// sortable columns just passes null for every one except whichever the
/// caller's own sort state currently points at.
///
/// Tapping calls [onChanged] with the value this button should become:
/// `true` if it wasn't the active column yet, otherwise the opposite of its
/// current [ascending] — the caller decides what that actually means (e.g.
/// making this the new active sort column, or just flipping direction).
class HeaderSortableButton extends AppTableHeaderCell {
  const HeaderSortableButton({
    super.key,
    required this.text,
    required this.ascending,
    required this.onChanged,
    this.alignment = Alignment.centerLeft,
    this.padding = EdgeInsets.zero,
  });

  final String text;
  final bool? ascending;
  final ValueChanged<bool> onChanged;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final active = ascending != null;
    final colorScheme = Theme.of(context).colorScheme;
    final color = active
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.6);

    return ClipRect(
      child: InkWell(
        onTap: () => onChanged(active ? !ascending! : true),
        child: Padding(
          padding: padding,
          child: Align(
            alignment: alignment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text.toUpperCase(),
                  style: _headerTextStyle.copyWith(color: color),
                ),
                if (active) ...[
                  const SizedBox(width: 2),
                  Icon(
                    ascending!
                        ? CupertinoIcons.arrow_up
                        : CupertinoIcons.arrow_down,
                    size: 12,
                    color: color,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A themed, bordered table card (see [TableCard]) with a column-scheme
/// driven header and body, reused across explorer.screen.dart and
/// storage.screen.dart so the two never again drift out of alignment from
/// hand-copied header/row layout formulas.
///
/// Use the default constructor for a flat list of [T] rows, or
/// [AppTable.sectioned] for rows grouped under [AppTableSection] headers
/// (e.g. Explorer's "group by folder" view) — sections are still flattened
/// into one recyclable list under the hood (see [_buildEntries]), not built as
/// separate ListViews per section, so the whole table stays one lazily
/// built/recycled scrollable regardless of how many sections there are.
class AppTable<T, S> extends StatelessWidget {
  const AppTable({
    super.key,
    required this.columns,
    required this.headerBuilder,
    required this.rowBuilder,
    required List<T> items,
    this.rowHeight = _defaultRowHeight,
    this.scrollbarGutter = _defaultScrollbarGutter,
    this.onRowTap,
    this.onRowSecondaryTapUp,
    this.rowKey,
    this.emptyMessage = _defaultEmptyMessage,
  })  : _items = items,
        _sections = null,
        sectionBuilder = null,
        sectionGap = defaultSectionGap;

  const AppTable.sectioned({
    super.key,
    required this.columns,
    required this.headerBuilder,
    required this.rowBuilder,
    required List<AppTableSection<S, T>> sections,
    required Widget Function(BuildContext context, S section)
        this.sectionBuilder,
    this.sectionGap = defaultSectionGap,
    this.rowHeight = _defaultRowHeight,
    this.scrollbarGutter = _defaultScrollbarGutter,
    this.onRowTap,
    this.onRowSecondaryTapUp,
    this.rowKey,
    this.emptyMessage = _defaultEmptyMessage,
  })  : _items = null,
        _sections = sections;

  static const _defaultRowHeight = 56.0;
  static const _defaultScrollbarGutter = 12.0;
  static const _defaultEmptyMessage = 'Nothing to show.';

  // Matches a section header's own established height (see
  // explorer.screen.dart's original tuning) so an empty gap between
  // sections reads as the same kind of "breathing room" as a header does —
  // the sensible default when a section header happens to be that tall;
  // override sectionGap if a table's own section headers aren't.
  static const defaultSectionGap = 36.0;

  final List<AppTableColumn> columns;

  /// Returns one [AppTableHeaderCell] per non-[DividerColumn] column, in
  /// scheme order.
  final List<AppTableHeaderCell> Function(BuildContext context) headerBuilder;

  /// Returns one widget per non-[DividerColumn] column, in scheme order.
  /// [isHovered] reflects whether the pointer is currently over this row —
  /// e.g. for a cell that only shows extra content on hover.
  final List<Widget> Function(BuildContext context, T item, bool isHovered)
      rowBuilder;

  final double rowHeight;
  final double scrollbarGutter;
  final void Function(T item)? onRowTap;

  /// Given the row's own context (so a handler can look up its Overlay/
  /// Navigator, e.g. to show a context menu), the item, and where the
  /// secondary click landed.
  final void Function(BuildContext context, T item, Offset globalPosition)?
      onRowSecondaryTapUp;

  /// A stable key per row, so a row's own state (hover, in-flight
  /// animations, ...) survives a resort/regroup instead of being torn down
  /// and rebuilt from scratch when its position in the list changes.
  final Key Function(T item)? rowKey;

  final String emptyMessage;

  final List<T>? _items;
  final List<AppTableSection<S, T>>? _sections;
  final Widget Function(BuildContext context, S section)? sectionBuilder;
  final double sectionGap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final columnCount = columns.whereType<DividerColumn>().length;
    final cellCount = columns.length - columnCount;

    final headerCells = headerBuilder(context);
    assert(
      headerCells.length == cellCount,
      'headerBuilder must return $cellCount widget(s) (one per non-divider '
      'column), got ${headerCells.length}.',
    );

    return TableCard(
      header: TableHeaderRow(
        children: _layoutChildren(
          cells: headerCells,
          isHeader: true,
          dividerColor: colorScheme.outlineVariant,
        ),
      ),
      bodyBuilder: (context, scrollController) {
        final entries = _buildEntries();
        if (entries.isEmpty) {
          return _EmptyAppTableBody(
            scrollController: scrollController,
            message: emptyMessage,
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 4)
              .copyWith(right: scrollbarGutter),
          itemCount: entries.length,
          itemBuilder: (context, index) => entries[index](context),
        );
      },
    );
  }

  // A flat list of deferred builders (not built Widgets) so the actual,
  // possibly expensive per-row content is only constructed lazily by
  // ListView.builder for whatever's on/near screen — the same recycling a
  // flat, non-sectioned list gets, just with section headers/gaps spliced
  // in as their own entries rather than each section owning a separate
  // Scrollable.
  List<Widget Function(BuildContext)> _buildEntries() {
    final entries = <Widget Function(BuildContext)>[];

    void addDivider() {
      entries.add(
        (context) => Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      );
    }

    final sections = _sections;
    if (sections != null) {
      final sectionBuilder = this.sectionBuilder!;
      var rowIndex = 0;
      for (var s = 0; s < sections.length; s++) {
        final section = sections[s];
        if (s > 0) {
          final gap = sectionGap;
          entries.add((_) => SizedBox(height: gap));
        }
        entries.add((context) => sectionBuilder(context, section.section));
        for (var i = 0; i < section.items.length; i++) {
          if (i > 0) addDivider();
          entries.add(_rowEntry(section.items[i], rowIndex++));
        }
      }
    } else {
      final items = _items!;
      for (var i = 0; i < items.length; i++) {
        if (i > 0) addDivider();
        entries.add(_rowEntry(items[i], i));
      }
    }

    return entries;
  }

  Widget Function(BuildContext) _rowEntry(T item, int rowIndex) {
    return (context) => _AppTableRow<T>(
          key: rowKey?.call(item),
          item: item,
          zebra: rowIndex.isOdd,
          columns: columns,
          rowHeight: rowHeight,
          scrollbarGutter: scrollbarGutter,
          rowBuilder: rowBuilder,
          onTap: onRowTap,
          onSecondaryTapUp: onRowSecondaryTapUp,
        );
  }

  List<Widget> _layoutChildren({
    required List<Widget> cells,
    required bool isHeader,
    required Color dividerColor,
  }) {
    final children = <Widget>[];
    var cellIndex = 0;

    Widget divider() => isHeader
        ? VerticalDivider(width: 1, thickness: 1, color: dividerColor)
        : const SizedBox(width: 1);

    for (final column in columns) {
      switch (column) {
        case FlexColumn(:final flex):
          children.add(Expanded(flex: flex, child: cells[cellIndex++]));
        case FixedColumn(:final width):
          children.add(SizedBox(width: width, child: cells[cellIndex++]));
        case DividerColumn():
          children.add(divider());
      }
    }

    if (scrollbarGutter > 0) {
      children.add(divider());
      children.add(SizedBox(width: scrollbarGutter));
    }

    return children;
  }
}

// Owns hover state (for rowBuilder's isHovered) and wires up zebra
// striping, tap, and secondary-tap — the same row chrome every AppTable
// row gets, regardless of caller.
class _AppTableRow<T> extends StatefulWidget {
  const _AppTableRow({
    super.key,
    required this.item,
    required this.zebra,
    required this.columns,
    required this.rowHeight,
    required this.scrollbarGutter,
    required this.rowBuilder,
    required this.onTap,
    required this.onSecondaryTapUp,
  });

  final T item;
  final bool zebra;
  final List<AppTableColumn> columns;
  final double rowHeight;
  final double scrollbarGutter;
  final List<Widget> Function(BuildContext context, T item, bool isHovered)
      rowBuilder;
  final void Function(T item)? onTap;
  final void Function(BuildContext context, T item, Offset globalPosition)?
      onSecondaryTapUp;

  @override
  State<_AppTableRow<T>> createState() => _AppTableRowState<T>();
}

class _AppTableRowState<T> extends State<_AppTableRow<T>> {
  bool _hovering = false;

  // Unlike AppTable's own header layout, a DividerColumn here renders as an
  // invisible 1px gap rather than a real VerticalDivider — visible dividers
  // are reserved for the header, so body rows don't get cluttered with a
  // vertical line per column.
  List<Widget> _layoutChildren(List<Widget> cells) {
    final children = <Widget>[];
    var cellIndex = 0;

    for (final column in widget.columns) {
      switch (column) {
        case FlexColumn(:final flex):
          children.add(Expanded(flex: flex, child: cells[cellIndex++]));
        case FixedColumn(:final width):
          children.add(SizedBox(width: width, child: cells[cellIndex++]));
        case DividerColumn():
          children.add(const SizedBox(width: 1));
      }
    }
    if (widget.scrollbarGutter > 0) children.add(const SizedBox(width: 1));

    return children;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cells = widget.rowBuilder(context, widget.item, _hovering);
    final children = _layoutChildren(cells);

    return ColoredBox(
      color: widget.zebra
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
          : Colors.transparent,
      child: GestureDetector(
        onSecondaryTapUp: widget.onSecondaryTapUp == null
            ? null
            : (details) => widget.onSecondaryTapUp!(
                  context,
                  widget.item,
                  details.globalPosition,
                ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:
                widget.onTap == null ? null : () => widget.onTap!(widget.item),
            onHover: (hovering) => setState(() => _hovering = hovering),
            child: SizedBox(
              height: widget.rowHeight,
              child: Row(children: children),
            ),
          ),
        ),
      ),
    );
  }
}

// A Scrollbar with `thumbVisibility: true` asserts that its controller has
// an attached ScrollPosition, so the empty state needs to be a real
// Scrollable (not a bare Center) — sized to the viewport so the message
// still reads as vertically centered.
class _EmptyAppTableBody extends StatelessWidget {
  const _EmptyAppTableBody(
      {required this.scrollController, required this.message});

  final ScrollController scrollController;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        controller: scrollController,
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
