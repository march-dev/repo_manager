# repo_manager

![Build](https://github.com/march-dev/repo_manager/workflows/build/badge.svg)
![GitHub](https://img.shields.io/github/license/march-dev/repo_manager)
![GitHub stars](https://img.shields.io/github/stars/march-dev/repo_manager?style=social)

Project description

## Getting Started

Add intro here

## Feature requests and Bug reports

Feel free to post a feature requests or report a bug [here](https://github.com/march-dev/repo_manager/issues).

## TODO

Fix local storage (not related but just needed)

Create custom painted size bar (cover all cases)
Create custom theme and typography
Create custom UIKit
Create grouping by collection (collection creation, add to collection action)

New AppTable widget:
there must be a table scheme, where user configs his columns
config should have these types: FlexColumn, FixedColumn, Divider

table widget must contain table itself, providing:
- rowBuilder, returns list of widgets, must be equal to scheme columns length (omitting divider)
- headerBuilder, returns list of header widgets, must be equal to scheme columns length (omitting divider)
- sectionBuilder, returns section widget, if present, data must be set to not items, but to sections, where each section will have its own list of items
- sectionGap, returns double, must default to default size of a section

under the hood sections must still be a list entry, for recycling (performance efficient)

header widgets must be: HeaderEmpty (space filler), HeaderText (plain text, no buttons), HeaderButton (text, and onPressed), HeaderSortableButton (text, arrow reacting on ascending bool param, and onChanged to toggle the ascending state, should be default state where no arrow is shown if another such sortable button is active)

reuse this AppTable on both explorer and storage screens
