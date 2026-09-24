import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../repo_manager.dart';

// Durable, user-authored data: configured search directories, favourites,
// collections, preferences, the recently-opened list. Small, fixed key
// sets (see each repo's own doc) — nothing here is safe to casually lose.
const _settingsBoxName = 'settings';

// Purely regenerable scan results: ProjectSizeRepo's per-project total/
// cleanable byte counts, ProjectScanner's per-project monorepo member-
// package trees. Unbounded — one (or two) keys per project ever scanned —
// and every one of them is just a cache of filesystem work that reruns
// on a miss, never data the user actually authored. Kept in its own box
// so a corrupted cache can be wiped and rebuilt from a fresh scan without
// also losing every configured directory/favourite/collection along with
// it, the way sharing one box with _settingsBoxName used to.
const _cacheBoxName = 'cache';

/// Opens [name], recovering once from a corrupted box file (rather than
/// crashing at launch with no way back in) by deleting and recreating it
/// — losing everything that box held, but that's still strictly better
/// than the app being unable to start at all.
///
/// Only [HiveError] (a genuinely corrupted file — bad checksum, truncated
/// frame, ...) triggers that destructive recovery. Deliberately NOT a
/// blanket `on Object`/`on Exception`: opening a box also throws a plain
/// [FileSystemException] when another instance of this app already has it
/// locked, and that case used to be caught here too — indistinguishable
/// from real corruption — silently deleting a perfectly good box out from
/// under whichever instance actually owned it. That failure mode is left
/// to propagate instead.
Future<Box> _openBox(String name) async {
  try {
    return await Hive.openBox(name);
  } on HiveError catch (error, stackTrace) {
    logError(
      'Open $name box (corrupted, deleting and recreating it)',
      error,
      stackTrace,
    );
    await Hive.deleteBoxFromDisk(name);
    return Hive.openBox(name);
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
    required this.projectCompositionRepo,
    required this.projectScanner,
    required this.ideLauncherRepo,
  });

  static Future<DependencyResolver> create() async {
    // Two Hive boxes — durable settings and regenerable cache (see
    // _settingsBoxName/_cacheBoxName's own docs for why they're split) —
    // opened once here, each resulting Box then passed explicitly into
    // whichever repo's constructor needs it, rather than repos reaching
    // for a shared ambient static.
    //
    // Hive.initFlutter() would default to getApplicationDocumentsDirectory()
    // (~/Documents on macOS) — one of the folders macOS's TCC privacy
    // protections gate behind explicit per-app user consent, independent
    // of this app's own (disabled) sandbox entitlements. That consent can
    // silently lapse (e.g. a rebuilt debug binary getting a new ad-hoc
    // signature), and Hive's own "delete stale .hivec compaction file"
    // step then throws PathAccessException before the box even opens,
    // crashing the app at launch with nothing left here to catch it (see
    // _openBox's own doc comment for why that catch stays narrow).
    // Application Support isn't one of the TCC-gated folders and isn't
    // meant to be user-visible anyway, so both boxes live there instead.
    final supportDir = await getApplicationSupportDirectory();
    Hive.init(supportDir.path);
    final settingsBox = await _openBox(_settingsBoxName);
    final cacheBox = await _openBox(_cacheBoxName);

    // Leaves first — no dependencies of their own besides a box.
    const languageDetector = ProjectLanguageDetector();
    const projectIconFinder = ProjectIconFinder();
    const projectModelCodec = ProjectModelCodec();
    final favouritesRepo = FavouritesRepo(box: settingsBox);
    final collectionsRepo = CollectionsRepo(box: settingsBox);
    final appSettingsRepo = AppSettingsRepo(box: settingsBox);
    final projectSizeRepo = ProjectSizeRepo(box: cacheBox);
    final projectCompositionRepo = ProjectCompositionRepo(box: cacheBox);

    // Depends on languageDetector only.
    final projectDirectoryRepo = ProjectDirectoryRepo(
      box: settingsBox,
      languageDetector: languageDetector,
    );

    // Depends on several of the above.
    final projectScanner = ProjectScanner(
      box: cacheBox,
      languageDetector: languageDetector,
      directoryRepo: projectDirectoryRepo,
      iconFinder: projectIconFinder,
      codec: projectModelCodec,
      favouritesRepo: favouritesRepo,
    );
    final ideLauncherRepo = IdeLauncherRepo(
      box: settingsBox,
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
      projectCompositionRepo: projectCompositionRepo,
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
  final ProjectCompositionRepo projectCompositionRepo;
  final ProjectScanner projectScanner;
  final IdeLauncherRepo ideLauncherRepo;
}
