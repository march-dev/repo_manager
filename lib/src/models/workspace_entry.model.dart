import 'project.model.dart';

/// One node in a monorepo's member-package tree: either a real, openable
/// project, or a plain container folder found along the way that isn't a
/// project itself — e.g. a workspace glob that resolves one level above
/// the actual packages, a folder just used to group several of them, or a
/// nested repo with no workspace config of its own. Kept as its own
/// visible tree node instead of being silently flattened through, so the
/// tree actually reflects where packages live on disk rather than
/// collapsing every non-project directory away.
sealed class WorkspaceEntry {
  WorkspaceEntry(this.name, this.path);

  final String name;
  final String path;
}

/// A real project found somewhere inside a monorepo's tree — openable,
/// with its own language/framework, just nested here instead of appearing
/// as an unrelated top-level sibling. Can itself carry further
/// [ProjectModel.subPackages] if it's a monorepo root in its own right.
class WorkspaceProjectEntry extends WorkspaceEntry {
  WorkspaceProjectEntry(this.project) : super(project.name, project.path);

  final ProjectModel project;
}

/// A plain directory that isn't a project itself, shown so the tree stays
/// honest about where its member projects actually live rather than
/// hiding a level of nesting. Not openable in an IDE — it has no
/// language/framework of its own — only collapsible.
class WorkspaceFolderEntry extends WorkspaceEntry {
  WorkspaceFolderEntry(super.name, super.path, this.children);

  final List<WorkspaceEntry> children;
}

extension WorkspaceEntryListX on List<WorkspaceEntry> {
  /// Total number of real projects anywhere in this subtree — a plain
  /// container folder doesn't count itself, only what it actually holds.
  int get projectCount {
    var count = 0;
    for (final entry in this) {
      switch (entry) {
        case WorkspaceProjectEntry():
          count++;
        case WorkspaceFolderEntry(:final children):
          count += children.projectCount;
      }
    }
    return count;
  }
}
