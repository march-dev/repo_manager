// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_details_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ProjectDetailsState on _ProjectDetailsStateBase, Store {
  Computed<bool>? _$isMonorepoComputed;

  @override
  bool get isMonorepo =>
      (_$isMonorepoComputed ??= Computed<bool>(() => super.isMonorepo,
              name: '_ProjectDetailsStateBase.isMonorepo'))
          .value;

  late final _$notInstalledIdesAtom =
      Atom(name: '_ProjectDetailsStateBase.notInstalledIdes', context: context);

  @override
  ObservableSet<Ide> get notInstalledIdes {
    _$notInstalledIdesAtom.reportRead();
    return super.notInstalledIdes;
  }

  @override
  set notInstalledIdes(ObservableSet<Ide> value) {
    _$notInstalledIdesAtom.reportWrite(value, super.notInstalledIdes, () {
      super.notInstalledIdes = value;
    });
  }

  late final _$projectAtom =
      Atom(name: '_ProjectDetailsStateBase.project', context: context);

  @override
  ProjectModel get project {
    _$projectAtom.reportRead();
    return super.project;
  }

  @override
  set project(ProjectModel value) {
    _$projectAtom.reportWrite(value, super.project, () {
      super.project = value;
    });
  }

  late final _$tabAtom =
      Atom(name: '_ProjectDetailsStateBase.tab', context: context);

  @override
  ProjectDetailsTab get tab {
    _$tabAtom.reportRead();
    return super.tab;
  }

  @override
  set tab(ProjectDetailsTab value) {
    _$tabAtom.reportWrite(value, super.tab, () {
      super.tab = value;
    });
  }

  late final _$sortAscendingAtom =
      Atom(name: '_ProjectDetailsStateBase.sortAscending', context: context);

  @override
  bool get sortAscending {
    _$sortAscendingAtom.reportRead();
    return super.sortAscending;
  }

  @override
  set sortAscending(bool value) {
    _$sortAscendingAtom.reportWrite(value, super.sortAscending, () {
      super.sortAscending = value;
    });
  }

  late final _$expandedAtom =
      Atom(name: '_ProjectDetailsStateBase.expanded', context: context);

  @override
  Set<String> get expanded {
    _$expandedAtom.reportRead();
    return super.expanded;
  }

  @override
  set expanded(Set<String> value) {
    _$expandedAtom.reportWrite(value, super.expanded, () {
      super.expanded = value;
    });
  }

  late final _$sizeAtom =
      Atom(name: '_ProjectDetailsStateBase.size', context: context);

  @override
  ProjectSizeModel? get size {
    _$sizeAtom.reportRead();
    return super.size;
  }

  @override
  set size(ProjectSizeModel? value) {
    _$sizeAtom.reportWrite(value, super.size, () {
      super.size = value;
    });
  }

  late final _$sizeLoadingAtom =
      Atom(name: '_ProjectDetailsStateBase.sizeLoading', context: context);

  @override
  bool get sizeLoading {
    _$sizeLoadingAtom.reportRead();
    return super.sizeLoading;
  }

  @override
  set sizeLoading(bool value) {
    _$sizeLoadingAtom.reportWrite(value, super.sizeLoading, () {
      super.sizeLoading = value;
    });
  }

  late final _$refreshingAtom =
      Atom(name: '_ProjectDetailsStateBase.refreshing', context: context);

  @override
  bool get refreshing {
    _$refreshingAtom.reportRead();
    return super.refreshing;
  }

  @override
  set refreshing(bool value) {
    _$refreshingAtom.reportWrite(value, super.refreshing, () {
      super.refreshing = value;
    });
  }

  late final _$cleaningAtom =
      Atom(name: '_ProjectDetailsStateBase.cleaning', context: context);

  @override
  bool get cleaning {
    _$cleaningAtom.reportRead();
    return super.cleaning;
  }

  @override
  set cleaning(bool value) {
    _$cleaningAtom.reportWrite(value, super.cleaning, () {
      super.cleaning = value;
    });
  }

  late final _$languageCompositionAtom = Atom(
      name: '_ProjectDetailsStateBase.languageComposition', context: context);

  @override
  Map<ProjectLanguage, int> get languageComposition {
    _$languageCompositionAtom.reportRead();
    return super.languageComposition;
  }

  @override
  set languageComposition(Map<ProjectLanguage, int> value) {
    _$languageCompositionAtom.reportWrite(value, super.languageComposition, () {
      super.languageComposition = value;
    });
  }

  late final _$languageCompositionLoadingAtom = Atom(
      name: '_ProjectDetailsStateBase.languageCompositionLoading',
      context: context);

  @override
  bool get languageCompositionLoading {
    _$languageCompositionLoadingAtom.reportRead();
    return super.languageCompositionLoading;
  }

  @override
  set languageCompositionLoading(bool value) {
    _$languageCompositionLoadingAtom
        .reportWrite(value, super.languageCompositionLoading, () {
      super.languageCompositionLoading = value;
    });
  }

  late final _$frameworkCompositionAtom = Atom(
      name: '_ProjectDetailsStateBase.frameworkComposition', context: context);

  @override
  Map<ProjectFramework, int> get frameworkComposition {
    _$frameworkCompositionAtom.reportRead();
    return super.frameworkComposition;
  }

  @override
  set frameworkComposition(Map<ProjectFramework, int> value) {
    _$frameworkCompositionAtom.reportWrite(value, super.frameworkComposition,
        () {
      super.frameworkComposition = value;
    });
  }

  late final _$frameworkCompositionLoadingAtom = Atom(
      name: '_ProjectDetailsStateBase.frameworkCompositionLoading',
      context: context);

  @override
  bool get frameworkCompositionLoading {
    _$frameworkCompositionLoadingAtom.reportRead();
    return super.frameworkCompositionLoading;
  }

  @override
  set frameworkCompositionLoading(bool value) {
    _$frameworkCompositionLoadingAtom
        .reportWrite(value, super.frameworkCompositionLoading, () {
      super.frameworkCompositionLoading = value;
    });
  }

  late final _$_loadNotInstalledIdesAsyncAction = AsyncAction(
      '_ProjectDetailsStateBase._loadNotInstalledIdes',
      context: context);

  @override
  Future<void> _loadNotInstalledIdes({bool forceRefresh = false}) {
    return _$_loadNotInstalledIdesAsyncAction
        .run(() => super._loadNotInstalledIdes(forceRefresh: forceRefresh));
  }

  late final _$loadLanguageCompositionAsyncAction = AsyncAction(
      '_ProjectDetailsStateBase.loadLanguageComposition',
      context: context);

  @override
  Future<void> loadLanguageComposition({bool forceRefresh = false}) {
    return _$loadLanguageCompositionAsyncAction
        .run(() => super.loadLanguageComposition(forceRefresh: forceRefresh));
  }

  late final _$loadFrameworkCompositionAsyncAction = AsyncAction(
      '_ProjectDetailsStateBase.loadFrameworkComposition',
      context: context);

  @override
  Future<void> loadFrameworkComposition({bool forceRefresh = false}) {
    return _$loadFrameworkCompositionAsyncAction
        .run(() => super.loadFrameworkComposition(forceRefresh: forceRefresh));
  }

  late final _$loadSizeAsyncAction =
      AsyncAction('_ProjectDetailsStateBase.loadSize', context: context);

  @override
  Future<void> loadSize({bool forceRefresh = false}) {
    return _$loadSizeAsyncAction
        .run(() => super.loadSize(forceRefresh: forceRefresh));
  }

  late final _$cleanupAsyncAction =
      AsyncAction('_ProjectDetailsStateBase.cleanup', context: context);

  @override
  Future<void> cleanup() {
    return _$cleanupAsyncAction.run(() => super.cleanup());
  }

  late final _$_ProjectDetailsStateBaseActionController =
      ActionController(name: '_ProjectDetailsStateBase', context: context);

  @override
  void setTab(ProjectDetailsTab value) {
    final _$actionInfo = _$_ProjectDetailsStateBaseActionController.startAction(
        name: '_ProjectDetailsStateBase.setTab');
    try {
      return super.setTab(value);
    } finally {
      _$_ProjectDetailsStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleSort() {
    final _$actionInfo = _$_ProjectDetailsStateBaseActionController.startAction(
        name: '_ProjectDetailsStateBase.toggleSort');
    try {
      return super.toggleSort();
    } finally {
      _$_ProjectDetailsStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleExpanded(String path) {
    final _$actionInfo = _$_ProjectDetailsStateBaseActionController.startAction(
        name: '_ProjectDetailsStateBase.toggleExpanded');
    try {
      return super.toggleExpanded(path);
    } finally {
      _$_ProjectDetailsStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _loadSubPackages() {
    final _$actionInfo = _$_ProjectDetailsStateBaseActionController.startAction(
        name: '_ProjectDetailsStateBase._loadSubPackages');
    try {
      return super._loadSubPackages();
    } finally {
      _$_ProjectDetailsStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _setProject(ProjectModel updated) {
    final _$actionInfo = _$_ProjectDetailsStateBaseActionController.startAction(
        name: '_ProjectDetailsStateBase._setProject');
    try {
      return super._setProject(updated);
    } finally {
      _$_ProjectDetailsStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
notInstalledIdes: ${notInstalledIdes},
project: ${project},
tab: ${tab},
sortAscending: ${sortAscending},
expanded: ${expanded},
size: ${size},
sizeLoading: ${sizeLoading},
refreshing: ${refreshing},
cleaning: ${cleaning},
languageComposition: ${languageComposition},
languageCompositionLoading: ${languageCompositionLoading},
frameworkComposition: ${frameworkComposition},
frameworkCompositionLoading: ${frameworkCompositionLoading},
isMonorepo: ${isMonorepo}
    ''';
  }
}
