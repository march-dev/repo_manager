// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SettingsStore on _SettingsStoreBase, Store {
  late final _$dirsAtom =
      Atom(name: '_SettingsStoreBase.dirs', context: context);

  @override
  ObservableList<String> get dirs {
    _$dirsAtom.reportRead();
    return super.dirs;
  }

  @override
  set dirs(ObservableList<String> value) {
    _$dirsAtom.reportWrite(value, super.dirs, () {
      super.dirs = value;
    });
  }

  late final _$isAddingAtom =
      Atom(name: '_SettingsStoreBase.isAdding', context: context);

  @override
  bool get isAdding {
    _$isAddingAtom.reportRead();
    return super.isAdding;
  }

  @override
  set isAdding(bool value) {
    _$isAddingAtom.reportWrite(value, super.isAdding, () {
      super.isAdding = value;
    });
  }

  late final _$preferredIdeAtom =
      Atom(name: '_SettingsStoreBase.preferredIde', context: context);

  @override
  PreferredIde get preferredIde {
    _$preferredIdeAtom.reportRead();
    return super.preferredIde;
  }

  bool _preferredIdeIsInitialized = false;

  @override
  set preferredIde(PreferredIde value) {
    _$preferredIdeAtom.reportWrite(
        value, _preferredIdeIsInitialized ? super.preferredIde : null, () {
      super.preferredIde = value;
      _preferredIdeIsInitialized = true;
    });
  }

  late final _$addDirAsyncAction =
      AsyncAction('_SettingsStoreBase.addDir', context: context);

  @override
  Future<void> addDir(String path, {bool recursive = false}) {
    return _$addDirAsyncAction
        .run(() => super.addDir(path, recursive: recursive));
  }

  late final _$removeDirAsyncAction =
      AsyncAction('_SettingsStoreBase.removeDir', context: context);

  @override
  Future<void> removeDir(String path) {
    return _$removeDirAsyncAction.run(() => super.removeDir(path));
  }

  late final _$setPreferredIdeAsyncAction =
      AsyncAction('_SettingsStoreBase.setPreferredIde', context: context);

  @override
  Future<void> setPreferredIde(PreferredIde ide) {
    return _$setPreferredIdeAsyncAction.run(() => super.setPreferredIde(ide));
  }

  late final _$_SettingsStoreBaseActionController =
      ActionController(name: '_SettingsStoreBase', context: context);

  @override
  void loadDirs() {
    final _$actionInfo = _$_SettingsStoreBaseActionController.startAction(
        name: '_SettingsStoreBase.loadDirs');
    try {
      return super.loadDirs();
    } finally {
      _$_SettingsStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
dirs: ${dirs},
isAdding: ${isAdding},
preferredIde: ${preferredIde}
    ''';
  }
}
