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
