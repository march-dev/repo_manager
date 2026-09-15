/// The app's size scale — spacing/gaps, corner radii, and icon sizes that
/// kept turning up as separately-named (but identical-valued) local
/// constants across screens (e.g. explorer.screen.dart's `_rowPadding`,
/// storage.screen.dart's `_iconGap`, and project_details.screen.dart's
/// `_rowPadding` were all `16.0` under different names). Referencing these
/// by name here means a size change happens in one place instead of
/// hunting down every "matches X's own Y" comment that was the only thing
/// previously keeping them in sync.
///
/// Not every numeric literal in the app belongs here — a one-off widget's
/// own tuned dimension (a tile's fixed width, a segment's fixed column
/// width) isn't a shared design token just because it happens to be a
/// round number, and forcing it through this scale would risk an
/// unrelated widget resizing the next time this scale changes. This only
/// covers values that are genuinely reused as the same semantic role in
/// more than one place.
abstract final class AppSizes {
  // Spacing/gap scale — padding and gaps between elements, roughly a 4pt
  // grid. Named by pixel value (not t-shirt size) since callers already
  // think in terms of "the usual 16px gap", not an abstract step.
  static const spacing2 = 2.0;
  static const spacing4 = 4.0;
  static const spacing6 = 6.0;
  static const spacing8 = 8.0;
  static const spacing10 = 10.0;
  static const spacing12 = 12.0;
  static const spacing16 = 16.0;
  static const spacing20 = 20.0;
  static const spacing24 = 24.0;

  // Corner radii.
  static const radiusSmall = 4.0;
  static const radiusMedium = 8.0;
  static const radiusLarge = 12.0;
  static const radiusXLarge = 16.0;

  // Icon/glyph sizes.
  static const iconTiny = 12.0;
  static const iconXSmall = 14.0;
  static const iconSmall = 16.0;
  static const iconMedium = 18.0;
  static const iconLarge = 20.0;
  static const iconXLarge = 24.0;
  static const iconHuge = 32.0;

  // A project/folder row's own icon badge — Explorer, Storage,
  // project_details' member-package tree, and every AWKit icon widget
  // (ProjectIcon/FolderIcon/EntryIcon's default, ProjectRow's default) all
  // converge on this one size.
  static const rowIconSize = 40.0;

  // AppTable's default row height, and project_details' member-package
  // tree rows matching it so both read as the same kind of table.
  static const rowHeight = 56.0;

  // A fixed trailing action column (a favourite toggle, a cleanup button)
  // sized to match rowIconSize so the column reads as square.
  static const actionColumnSize = 40.0;

  // Every hairline border/divider in the app is this thick.
  static const borderWidth = 1.0;
}
