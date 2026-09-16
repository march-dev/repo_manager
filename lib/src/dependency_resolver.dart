import 'package:hive_flutter/hive_flutter.dart';

import '../repo_manager.dart';

const _boxName = 'settings';

/// The app's single composition root: opens the Hive box, then constructs
/// every repo in dependency order, wiring each one's own dependencies in
/// explicitly through its constructor. Nothing downstream of this reaches
/// for a repo via an ambient singleton/factory (the "service locator"
/// pattern this replaced) — main.dart builds one [DependencyResolver], then
/// every store gets the specific repos it needs passed into its own
/// constructor (see app.dart), and the couple of places UI can't reach a
/// Provider-scoped store from (a project-details dialog route, a
/// right-click context menu) instead go through one of the small
/// explicitly-constructed global stores in lib/src/stores/global_stores.dart
/// — never a repo directly.
class DependencyResolver {
  const DependencyResolver._({
    required this.languageDetector,
    required this.projectDirectoryRepo,
    required this.projectIconFinder,
    required this.projectModelCodec,
    required this.favouritesRepo,
    required this.collectionsRepo,
    required this.appSettingsRepo,
    required this.projectSizeRepo,
    required this.projectScanner,
    required this.ideLauncherRepo,
  });

  static Future<DependencyResolver> create() async {
    // The single Hive box every repo persists into — opened once here,
    // the resulting Box then passed explicitly into each repo's
    // constructor rather than repos reaching for a shared ambient static.
    await Hive.initFlutter();
    final box = await Hive.openBox(_boxName);

    // Leaves first — no dependencies of their own besides the box.
    const languageDetector = ProjectLanguageDetector();
    const projectIconFinder = ProjectIconFinder();
    const projectModelCodec = ProjectModelCodec();
    final favouritesRepo = FavouritesRepo(box: box);
    final collectionsRepo = CollectionsRepo(box: box);
    final appSettingsRepo = AppSettingsRepo(box: box);
    final projectSizeRepo = ProjectSizeRepo(box: box);

    // Depends on languageDetector only.
    final projectDirectoryRepo = ProjectDirectoryRepo(
      box: box,
      languageDetector: languageDetector,
    );

    // Depends on several of the above.
    final projectScanner = ProjectScanner(
      box: box,
      languageDetector: languageDetector,
      directoryRepo: projectDirectoryRepo,
      iconFinder: projectIconFinder,
      codec: projectModelCodec,
      favouritesRepo: favouritesRepo,
    );
    final ideLauncherRepo = IdeLauncherRepo(
      box: box,
      appSettingsRepo: appSettingsRepo,
    );

    return DependencyResolver._(
      languageDetector: languageDetector,
      projectDirectoryRepo: projectDirectoryRepo,
      projectIconFinder: projectIconFinder,
      projectModelCodec: projectModelCodec,
      favouritesRepo: favouritesRepo,
      collectionsRepo: collectionsRepo,
      appSettingsRepo: appSettingsRepo,
      projectSizeRepo: projectSizeRepo,
      projectScanner: projectScanner,
      ideLauncherRepo: ideLauncherRepo,
    );
  }

  final ProjectLanguageDetector languageDetector;
  final ProjectDirectoryRepo projectDirectoryRepo;
  final ProjectIconFinder projectIconFinder;
  final ProjectModelCodec projectModelCodec;
  final FavouritesRepo favouritesRepo;
  final CollectionsRepo collectionsRepo;
  final AppSettingsRepo appSettingsRepo;
  final ProjectSizeRepo projectSizeRepo;
  final ProjectScanner projectScanner;
  final IdeLauncherRepo ideLauncherRepo;
}
