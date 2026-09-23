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
  })  : _appSettingsUseCases = appSettingsUseCases,
        _projectDirectoryUseCases = projectDirectoryUseCases {
    loadDirs();
    for (final group in LanguageGroup.values) {
      preferredIdes[group] = _appSettingsUseCases.getPreferredIde(group);
    }
  }

  final AppSettingsUseCases _appSettingsUseCases;
  final ProjectDirectoryUseCases _projectDirectoryUseCases;

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
}
