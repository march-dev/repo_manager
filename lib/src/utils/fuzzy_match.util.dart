/// Whether every character of [query] appears in [text], in order, case
/// insensitively — the usual "fuzzy" search behavior (e.g. "rmgr" matches
/// "repo_manager") rather than a strict substring match. An empty query
/// matches everything.
bool fuzzyMatch(String query, String text) {
  if (query.isEmpty) return true;

  final lowerQuery = query.toLowerCase();
  final lowerText = text.toLowerCase();

  var queryIndex = 0;
  for (var i = 0; i < lowerText.length && queryIndex < lowerQuery.length; i++) {
    if (lowerText[i] == lowerQuery[queryIndex]) queryIndex++;
  }

  return queryIndex == lowerQuery.length;
}
