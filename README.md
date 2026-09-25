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

* Dev Tools cleaner (xcode cache, pub.dev cache, ...)
  * enhance header, add chart, toggle all on/off
  * leave whole page shimmer for initial loading, for refresh add shimmer only to sizes, compute sizes using multithreading and update on the calculation finished per entry
  * add 3-state indicator for every cache entry that will show how safe it is to delete (safe to delete / could be unsafe to delete / could cause malfunctions)
  * adapt paths for each desktop platform

* FVM manager (same as storage, but only for fvm)

### Shortlist

* Git awareness — currently there's none at all. For an app called "repo manager," it doesn't show branch, dirty/clean status, or ahead/ behind-remote. That'd probably be the single highest-value addition:
  Current branch + a dot/badge for uncommitted changes
  Ahead/behind counts vs. the tracked remote
  Last commit date, maybe the message
  Quick actions: fetch/pull, or "open on GitHub/GitLab"

### Longlist

* Still wrong concept of Data->Domain->State->UI, need to provide more precise instruction
* Adjust colour scheme generator
* Adjust app icon generator
