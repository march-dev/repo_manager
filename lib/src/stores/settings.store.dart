import '../../repo_manager.dart';
import 'package:mobx/mobx.dart';

part 'settings.store.g.dart';

class SettingsStore = _SettingsStoreBase with _$SettingsStore;

abstract class _SettingsStoreBase with Store {
  _SettingsStoreBase() {
    loadDirs();
    preferredIde = ProjectRepo().getPreferredIde();
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

  @observable
  bool recursiveAdd = false;

  @action
  void setRecursiveAdd(bool value) => recursiveAdd = value;

  @action
  Future<void> addDir(String path) async {
    isAdding = true;
    if (recursiveAdd) {
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
  late PreferredIde preferredIde;

  @action
  Future<void> setPreferredIde(PreferredIde ide) async {
    preferredIde = ide;
    await ProjectRepo().setPreferredIde(ide);
  }
}
