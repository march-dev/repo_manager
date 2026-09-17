import 'package:hive_flutter/hive_flutter.dart';

import '../repo_manager.dart';

const _boxName = 'settings';

/// Opens the shared settings box, recovering once from a corrupted box
/// file (rather than crashing at launch with no way back in) by deleting
/// and recreating it — losing every saved preference/cache, but that's
/// still strictly better than the app being unable to start at all.
///
/// Only [HiveError] (a genuinely corrupted file — bad checksum, truncated
/// frame, ...) triggers that destructive recovery. Deliberately NOT a
/// blanket `on Object`/`on Exception`: opening the box also throws a plain
/// [FileSystemException] when another instance of this app already has it
/// locked, and that case used to be caught here too — indistinguishable
/// from real corruption — silently deleting a perfectly good settings box
/// (every configured search directory, collection, favourite, preference)
/// out from under whichever instance actually owned it. That failure mode
/// is left to propagate instead.
Future<Box> _openBox() async {
  try {
    return await Hive.openBox(_boxName);
  } on HiveError catch (error, stackTrace) {
    logError(
      'Open settings box (corrupted, deleting and recreating it)',
      error,
      stackTrace,
    );
    await Hive.deleteBoxFromDisk(_boxName);
    return Hive.openBox(_boxName);
  }
}

/// The app's single composition root: opens the Hive box, then constructs
/// every repo in dependency order, wiring each one's own dependencies in
/// explicitly through its constructor. Nothing downstream of this reaches
/// for a repo via an ambient singleton/factory (the "service locator"
/// pattern this replaced) — main.dart builds one [DependencyResolver], then
/// every store gets the specific repos it needs passed into its own
/// constructor (see app.dart), each registered via a plain `Provider<T>` in
/// _RootScaffold's MultiProvider. The couple of UI spots that sit outside
/// that Provider subtree (a project-details dialog route, a right-click
/// context menu overlay — see each store's own doc) get the specific store
/// instances they need passed in explicitly by whichever Provider-reachable
/// call site opened them, rather than through any global/ambient reference.
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
    final box = await _openBox();

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
