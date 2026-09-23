import 'monorepo_tool.enum.dart';
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

  /// The one workspace tool every project under this entry is a member
  /// of, if they all agree — a leaf's own [ProjectModel.workspaceTool], or
  /// (recursively) whatever its children share. Null when this entry
  /// isn't a workspace member at all, or its descendants span more than
  /// one workspace (a nested monorepo's own members belong to a different
  /// workspace than this folder's other children) — either way, nothing
  /// single to badge this entry with as a whole.
  MonorepoTool? get sharedWorkspaceTool => switch (this) {
        WorkspaceProjectEntry(:final project) => project.workspaceTool,
        WorkspaceFolderEntry(:final children) => children.isEmpty
            ? null
            : children
                .map((child) => child.sharedWorkspaceTool)
                .reduce((a, b) => a == b ? a : null),
      };
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
  /// Used for a folder row's own generic "N projects" label
  /// (project_details.screen.dart) — not what a monorepo root's own
  /// [MonorepoBadge] shows, see [declaredPackageCount] for that.
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

  /// Same traversal as [projectCount], but only counting a project whose
  /// own [ProjectModel.workspaceTool] is [tool] — a member [tool] itself
  /// actually declares/recognizes (found via its own workspace config or a
  /// pub path dependency), not one this app's own supplementary heuristics
  /// turned up nearby (a sibling scan, a conventional native-platform
  /// folder — see ProjectScanner._findSubPackages' own two such call
  /// sites, which leave workspaceTool null for exactly this reason). A
  /// monorepo root's own [MonorepoBadge] shows this count — "Melos · N
  /// packages" should match what running `melos list` would actually
  /// report, not this app's own broader "everything found nearby" tree.
  int declaredPackageCount(MonorepoTool tool) {
    var count = 0;
    for (final entry in this) {
      switch (entry) {
        case WorkspaceProjectEntry(:final project):
          if (project.workspaceTool == tool) count++;
        case WorkspaceFolderEntry(:final children):
          count += children.declaredPackageCount(tool);
      }
    }
    return count;
  }
}
