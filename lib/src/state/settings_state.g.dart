// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SettingsState on _SettingsStateBase, Store {
  Computed<bool>? _$dirsCollapsibleComputed;

  @override
  bool get dirsCollapsible =>
      (_$dirsCollapsibleComputed ??= Computed<bool>(() => super.dirsCollapsible,
              name: '_SettingsStateBase.dirsCollapsible'))
          .value;
  Computed<List<String>>? _$visibleDirsComputed;

  @override
  List<String> get visibleDirs =>
      (_$visibleDirsComputed ??= Computed<List<String>>(() => super.visibleDirs,
              name: '_SettingsStateBase.visibleDirs'))
          .value;
  Computed<int>? _$hiddenDirsCountComputed;

  @override
  int get hiddenDirsCount =>
      (_$hiddenDirsCountComputed ??= Computed<int>(() => super.hiddenDirsCount,
              name: '_SettingsStateBase.hiddenDirsCount'))
          .value;

  late final _$dirsAtom =
      Atom(name: '_SettingsStateBase.dirs', context: context);

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

  late final _$dirsExpandedAtom =
      Atom(name: '_SettingsStateBase.dirsExpanded', context: context);

  @override
  bool get dirsExpanded {
    _$dirsExpandedAtom.reportRead();
    return super.dirsExpanded;
  }

  @override
  set dirsExpanded(bool value) {
    _$dirsExpandedAtom.reportWrite(value, super.dirsExpanded, () {
      super.dirsExpanded = value;
    });
  }

  late final _$isAddingAtom =
      Atom(name: '_SettingsStateBase.isAdding', context: context);

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

  late final _$preferredIdesAtom =
      Atom(name: '_SettingsStateBase.preferredIdes', context: context);

  @override
  ObservableMap<LanguageGroup, Ide> get preferredIdes {
    _$preferredIdesAtom.reportRead();
    return super.preferredIdes;
  }

  @override
  set preferredIdes(ObservableMap<LanguageGroup, Ide> value) {
    _$preferredIdesAtom.reportWrite(value, super.preferredIdes, () {
      super.preferredIdes = value;
    });
  }

  late final _$addDirAsyncAction =
      AsyncAction('_SettingsStateBase.addDir', context: context);

  @override
  Future<void> addDir(String path, {bool recursive = false}) {
    return _$addDirAsyncAction
        .run(() => super.addDir(path, recursive: recursive));
  }

  late final _$removeDirAsyncAction =
      AsyncAction('_SettingsStateBase.removeDir', context: context);

  @override
  Future<void> removeDir(String path) {
    return _$removeDirAsyncAction.run(() => super.removeDir(path));
  }

  late final _$setPreferredIdeAsyncAction =
      AsyncAction('_SettingsStateBase.setPreferredIde', context: context);

  @override
  Future<void> setPreferredIde(LanguageGroup group, Ide ide) {
    return _$setPreferredIdeAsyncAction
        .run(() => super.setPreferredIde(group, ide));
  }

  late final _$_SettingsStateBaseActionController =
      ActionController(name: '_SettingsStateBase', context: context);

  @override
  void loadDirs() {
    final _$actionInfo = _$_SettingsStateBaseActionController.startAction(
        name: '_SettingsStateBase.loadDirs');
    try {
      return super.loadDirs();
    } finally {
      _$_SettingsStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleDirsExpanded() {
    final _$actionInfo = _$_SettingsStateBaseActionController.startAction(
        name: '_SettingsStateBase.toggleDirsExpanded');
    try {
      return super.toggleDirsExpanded();
    } finally {
      _$_SettingsStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
dirs: ${dirs},
dirsExpanded: ${dirsExpanded},
isAdding: ${isAdding},
preferredIdes: ${preferredIdes},
dirsCollapsible: ${dirsCollapsible},
visibleDirs: ${visibleDirs},
hiddenDirsCount: ${hiddenDirsCount}
    ''';
  }
}
