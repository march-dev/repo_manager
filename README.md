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

Search/filter in Explorer — with sorting/grouping/favourites already built, a quick fuzzy-search box for project name is a natural, cheap addition that's conspicuously missing from a list-heavy UI.
Monorepo awareness — detect Melos/Nx/Turborepo/Lerna workspaces and show sub-packages nested under one project instead of missing them or treating the whole repo as one opaque unit.

Git awareness — currently there's none at all. For an app called "repo manager," it doesn't show branch, dirty/clean status, or ahead/behind-remote. That'd probably be the single highest-value addition:
Current branch + a dot/badge for uncommitted changes
Ahead/behind counts vs. the tracked remote
Last commit date, maybe the message
Quick actions: fetch/pull, or "open on GitHub/GitLab"
