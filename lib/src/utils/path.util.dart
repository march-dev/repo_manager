import 'dart:io';

/// The longest path prefix shared by every path in [paths], split on
/// directory boundaries (so e.g. "/Users/x/Projects" and "/Users/x/Proj2"
/// share "/Users/x", not "/Users/x/Proj"). Always leaves at least the last
/// segment of the shortest path un-shared, so a single path (or a group of
/// identical ones) never collapses down to nothing.
String commonDirPrefix(List<String> paths) {
  if (paths.isEmpty) return '';

  final segmentLists =
      paths.map((path) => path.split(Platform.pathSeparator)).toList();
  final shortestLength = segmentLists
      .map((segments) => segments.length)
      .reduce((a, b) => a < b ? a : b);

  var commonLength = shortestLength;
  for (var i = 0; i < shortestLength; i++) {
    final segment = segmentLists.first[i];
    if (!segmentLists.every((segments) => segments[i] == segment)) {
      commonLength = i;
      break;
    }
  }
  if (commonLength >= shortestLength) commonLength = shortestLength - 1;
  if (commonLength <= 0) return '';

  return segmentLists.first.sublist(0, commonLength).join(
        Platform.pathSeparator,
      );
}

/// The current user's home directory, or null if it can't be determined —
/// `$HOME` on macOS/Linux, `%USERPROFILE%` on Windows (Dart's own
/// `Platform.environment` doesn't otherwise expose a portable accessor for
/// this).
String? _homeDir() => Platform.isWindows
    ? Platform.environment['USERPROFILE']
    : Platform.environment['HOME'];

/// Collapses [path]'s home-directory prefix to `~`, the common shell
/// shorthand — e.g. "/Users/alice/Projects" becomes "~/Projects" when the
/// current user's home is "/Users/alice". Left unchanged when [path] isn't
/// actually under the home directory, or the home directory itself can't be
/// determined — deliberately just this one well-known shorthand rather than
/// a general `$ENV_VAR` substitution scheme, since guessing which of
/// several arbitrary env vars a path "belongs to" gets ambiguous fast for
/// little real benefit, and most other platforms have no equivalent
/// convention for it anyway.
String collapseHomeDir(String path) {
  final home = _homeDir();
  if (home == null || home.isEmpty) return path;

  if (path == home) return '~';

  final homeWithSeparator = home.endsWith(Platform.pathSeparator)
      ? home
      : '$home${Platform.pathSeparator}';
  return path.startsWith(homeWithSeparator)
      ? '~${Platform.pathSeparator}${path.substring(homeWithSeparator.length)}'
      : path;
}

/// The part of [path] left over after removing [commonPrefix] (as computed
/// by [commonDirPrefix]) — e.g. "/Users/x/Projects" and
/// "/Users/x/Projects/other" become "Projects" and "Projects/other" once
/// their shared "/Users/x" prefix is stripped.
String stripCommonPrefix(String path, String commonPrefix) {
  if (commonPrefix.isEmpty) return path;
  if (path == commonPrefix) return path.split(Platform.pathSeparator).last;

  final prefixWithSeparator = commonPrefix.endsWith(Platform.pathSeparator)
      ? commonPrefix
      : '$commonPrefix${Platform.pathSeparator}';
  return path.startsWith(prefixWithSeparator)
      ? path.substring(prefixWithSeparator.length)
      : path;
}
