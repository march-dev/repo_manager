import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'settings.store.g.dart';

class SettingsStore = _SettingsStoreBase with _$SettingsStore;

abstract class _SettingsStoreBase with Store {
  _SettingsStoreBase() {
    loadDirs();
    for (final group in LanguageGroup.values) {
      preferredIdes[group] = ProjectRepo().getPreferredIde(group);
    }
  }

  @observable
  ObservableList<String> dirs = ObservableList<String>();

  @action
  void loadDirs() {
    dirs
      ..clear()
      ..addAll(ProjectRepo().getProjectDirs());
  }

  @observable
  bool isAdding = false;

  @action
  Future<void> addDir(String path, {bool recursive = false}) async {
    isAdding = true;
    if (recursive) {
      await ProjectRepo().addProjectDirsRecursively(path);
    } else {
      await ProjectRepo().addProjectDir(path);
    }
    loadDirs();
    isAdding = false;
  }

  @action
  Future<void> removeDir(String path) async {
    await ProjectRepo().removeProjectDir(path);
    loadDirs();
  }

  @observable
  ObservableMap<LanguageGroup, Ide> preferredIdes =
      ObservableMap<LanguageGroup, Ide>();

  @action
  Future<void> setPreferredIde(LanguageGroup group, Ide ide) async {
    preferredIdes[group] = ide;
    await ProjectRepo().setPreferredIde(group, ide);
  }
}
