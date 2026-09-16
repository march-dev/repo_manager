import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'settings.store.g.dart';

class SettingsStore = _SettingsStoreBase with _$SettingsStore;

abstract class _SettingsStoreBase with Store {
  _SettingsStoreBase({
    required AppSettingsRepo appSettingsRepo,
    required ProjectDirectoryRepo projectDirectoryRepo,
    required AppLocalizations l10n,
  })  : _appSettingsRepo = appSettingsRepo,
        _projectDirectoryRepo = projectDirectoryRepo,
        _l10n = l10n {
    loadDirs();
    for (final group in LanguageGroup.values) {
      preferredIdes[group] = _appSettingsRepo.getPreferredIde(group);
    }
  }

  final AppSettingsRepo _appSettingsRepo;
  final ProjectDirectoryRepo _projectDirectoryRepo;
  final AppLocalizations _l10n;

  @observable
  ObservableList<String> dirs = ObservableList<String>();

  @action
  void loadDirs() {
    dirs
      ..clear()
      ..addAll(_projectDirectoryRepo.getProjectDirs());
  }

  @observable
  bool isAdding = false;

  @action
  Future<void> addDir(String path, {bool recursive = false}) async {
    isAdding = true;
    try {
      if (recursive) {
        await _projectDirectoryRepo.addProjectDirsRecursively(path);
      } else {
        await _projectDirectoryRepo.addProjectDir(path);
      }
      loadDirs();
    } on Object catch (error, stackTrace) {
      logError('Add directory $path', error, stackTrace);
      SnackbarManager.show(_l10n.errorAddDirectory);
    } finally {
      // Regardless of success/failure — otherwise a failed add leaves the
      // button spinning/disabled forever.
      isAdding = false;
    }
  }

  @action
  Future<void> removeDir(String path) async {
    try {
      await _projectDirectoryRepo.removeProjectDir(path);
      loadDirs();
    } on Object catch (error, stackTrace) {
      logError('Remove directory $path', error, stackTrace);
      SnackbarManager.show(_l10n.errorRemoveDirectory);
    }
  }

  @observable
  ObservableMap<LanguageGroup, Ide> preferredIdes =
      ObservableMap<LanguageGroup, Ide>();

  @action
  Future<void> setPreferredIde(LanguageGroup group, Ide ide) async {
    preferredIdes[group] = ide;
    try {
      await _appSettingsRepo.setPreferredIde(group, ide);
    } on Object catch (error, stackTrace) {
      // Just a preference save — the choice already applied above
      // regardless, so this is only worth logging, not interrupting the
      // user over.
      logError('Save preferred IDE for ${group.name}', error, stackTrace);
    }
  }
}
