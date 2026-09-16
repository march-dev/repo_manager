import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'settings.store.g.dart';

class SettingsStore = _SettingsStoreBase with _$SettingsStore;

abstract class _SettingsStoreBase with Store {
  _SettingsStoreBase({
    required AppSettingsRepo appSettingsRepo,
    required ProjectDirectoryRepo projectDirectoryRepo,
  })  : _appSettingsRepo = appSettingsRepo,
        _projectDirectoryRepo = projectDirectoryRepo {
    loadDirs();
    for (final group in LanguageGroup.values) {
      preferredIdes[group] = _appSettingsRepo.getPreferredIde(group);
    }
  }

  final AppSettingsRepo _appSettingsRepo;
  final ProjectDirectoryRepo _projectDirectoryRepo;

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
    if (recursive) {
      await _projectDirectoryRepo.addProjectDirsRecursively(path);
    } else {
      await _projectDirectoryRepo.addProjectDir(path);
    }
    loadDirs();
    isAdding = false;
  }

  @action
  Future<void> removeDir(String path) async {
    await _projectDirectoryRepo.removeProjectDir(path);
    loadDirs();
  }

  @observable
  ObservableMap<LanguageGroup, Ide> preferredIdes =
      ObservableMap<LanguageGroup, Ide>();

  @action
  Future<void> setPreferredIde(LanguageGroup group, Ide ide) async {
    preferredIdes[group] = ide;
    await _appSettingsRepo.setPreferredIde(group, ide);
  }
}
