/// A monorepo/workspace tool detected at a project's own root — when
/// present, [ProjectModel.subPackages] holds the member packages it
/// manages, so they show up nested under this project instead of being
/// missed entirely or the whole repo being treated as one opaque unit.
enum MonorepoTool {
  melos('Melos'),
  nx('Nx'),
  turborepo('Turborepo'),
  lerna('Lerna'),
  ;

  const MonorepoTool(this.label);

  final String label;
}
