import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'settings_state.g.dart';

class SettingsState = _SettingsStateBase with _$SettingsState;

/// Reactive UI state for Settings' screen. Business logic (persisting a
/// directory add/remove, a preferred-IDE change) lives in
/// [ProjectDirectoryUseCases]/[AppSettingsUseCases]; this only tracks what
/// the UI needs to observe and re-render on.
abstract class _SettingsStateBase with Store {
  _SettingsStateBase({
    required AppSettingsUseCases appSettingsUseCases,
    required ProjectDirectoryUseCases projectDirectoryUseCases,
    required IdeLauncherUseCases ideLauncherUseCases,
  })  : _appSettingsUseCases = appSettingsUseCases,
        _projectDirectoryUseCases = projectDirectoryUseCases,
        _ideLauncherUseCases = ideLauncherUseCases {
    loadDirs();
    for (final group in LanguageGroup.values) {
      preferredIdes[group] = _appSettingsUseCases.getPreferredIde(group);
    }
    _loadNotInstalledIdes();
  }

  final AppSettingsUseCases _appSettingsUseCases;
  final ProjectDirectoryUseCases _projectDirectoryUseCases;
  final IdeLauncherUseCases _ideLauncherUseCases;

  @observable
  ObservableList<String> dirs = ObservableList<String>();

  @action
  void loadDirs() {
    dirs
      ..clear()
      ..addAll(_projectDirectoryUseCases.getProjectDirs());
  }

  // Past this many, the list is collapsed to a preview behind a "Show N
  // more" toggle — a directory list can grow long enough (every search
  // root a user has ever added) to push the preferred-editor card below
  // the fold for no benefit, when most of it is rarely looked at again
  // after being added.
  static const collapsedDirsLimit = 5;

  @observable
  bool dirsExpanded = false;

  @action
  void toggleDirsExpanded() => dirsExpanded = !dirsExpanded;

  @computed
  bool get dirsCollapsible => dirs.length > collapsedDirsLimit;

  @computed
  List<String> get visibleDirs => dirsExpanded || !dirsCollapsible
      ? dirs
      : dirs.take(collapsedDirsLimit).toList();

  @computed
  int get hiddenDirsCount => dirs.length - collapsedDirsLimit;

  @observable
  bool isAdding = false;

  @action
  Future<void> addDir(String path, {bool recursive = false}) async {
    isAdding = true;
    // Regardless of success/failure — otherwise a failed add leaves the
    // button spinning/disabled forever.
    if (await _projectDirectoryUseCases.addDir(path, recursive: recursive)) {
      loadDirs();
    }
    isAdding = false;
  }

  @action
  Future<void> removeDir(String path) async {
    if (await _projectDirectoryUseCases.removeDir(path)) loadDirs();
  }

  @observable
  ObservableMap<LanguageGroup, Ide> preferredIdes =
      ObservableMap<LanguageGroup, Ide>();

  @action
  Future<void> setPreferredIde(LanguageGroup group, Ide ide) async {
    preferredIdes[group] = ide;
    await _appSettingsUseCases.setPreferredIde(group, ide);
  }

  // IdeLauncherRepo.notInstalledIdes()'s own cached result (every Ide value
  // not actually installed on this machine) — see its own doc for why
  // every "which IDEs can I actually use" surface in the app shares this
  // one scan rather than each re-deriving its own. _LanguageGroupIdeSelector
  // disables (rather than hides — candidatesOnHost already hides an IDE
  // this OS could never run at all) a segment found in here. Normally
  // nothing here still matches the group's own preferredIdes entry by the
  // time this settles, thanks to _reselectNotInstalledPreferences below —
  // the one exception being a group where every one of its candidates
  // turns out not installed, which this still disables rather than
  // leaving genuinely unselectable.
  @observable
  ObservableSet<Ide> notInstalledIdes = ObservableSet<Ide>();

  @action
  Future<void> _loadNotInstalledIdes({bool forceRefresh = false}) async {
    final result = forceRefresh
        ? await _ideLauncherUseCases.refreshNotInstalledIdes()
        : await _ideLauncherUseCases.notInstalledIdes();
    notInstalledIdes
      ..clear()
      ..addAll(result);

    await _reselectNotInstalledPreferences();
  }

  // Settings' own manual refresh (F5 — see settings.screen.dart) — an IDE
  // installed or uninstalled since this page's own initial load is
  // exactly the kind of staleness a rescan fixes, the same reasoning
  // every other screen's own refresh already reruns this for (see
  // IdeLauncherRepo.refreshNotInstalledIdes' own doc).
  Future<void> refreshNotInstalledIdes() =>
      _loadNotInstalledIdes(forceRefresh: true);

  // Auto-heals a preference that's drifted onto a not-installed IDE (e.g.
  // uninstalled since it was picked) by moving it to the next candidate in
  // that group's own preference order that IS installed — persisted via
  // setPreferredIde, the same as an explicit pick, rather than leaving a
  // choice sat on something that's guaranteed to silently fail the moment
  // it's actually used (see IdeLauncherRepo.openPathInIde's own
  // ProcessException handling). Left alone (and disabled — see
  // notInstalledIdes' own doc) only when every one of the group's
  // candidates turns out not installed, since there's nothing better to
  // fall back to.
  Future<void> _reselectNotInstalledPreferences() async {
    for (final group in LanguageGroup.values) {
      final current = preferredIdes[group];
      if (current == null || !notInstalledIdes.contains(current)) continue;

      for (final candidate in group.candidatesOnHost) {
        if (notInstalledIdes.contains(candidate)) continue;
        await setPreferredIde(group, candidate);
        break;
      }
    }
  }
}
