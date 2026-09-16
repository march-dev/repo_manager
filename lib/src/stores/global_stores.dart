import '../../repo_manager.dart';

/// The handful of global (Provider-free) stores UI code outside the app's
/// Provider subtree relies on — see each store's own doc for why
/// (project_context_menu.dart's overlay, project_details.screen.dart's
/// dialog route). [initGlobalStores] builds each one explicitly from
/// [DependencyResolver], called once from main.dart right after
/// DependencyResolver.create() resolves — nothing here is a self-constructing
/// singleton/factory.
late final CollectionsStore collectionsStore;
late final IdeLauncherStore ideLauncherStore;
late final ProjectScannerStore projectScannerStore;

void initGlobalStores(DependencyResolver dependencies) {
  collectionsStore = CollectionsStore(dependencies.collectionsRepo);
  ideLauncherStore = IdeLauncherStore(dependencies.ideLauncherRepo);
  projectScannerStore = ProjectScannerStore(dependencies.projectScanner);
}
