// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explorer.store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ExplorerStore on _ExplorerStoreBase, Store {
  Computed<List<ProjectModel>>? _$visibleProjectsComputed;

  @override
  List<ProjectModel> get visibleProjects => (_$visibleProjectsComputed ??=
          Computed<List<ProjectModel>>(() => super.visibleProjects,
              name: '_ExplorerStoreBase.visibleProjects'))
      .value;
  Computed<Map<String, List<ProjectModel>>>? _$groupedProjectsComputed;

  @override
  Map<String, List<ProjectModel>> get groupedProjects =>
      (_$groupedProjectsComputed ??= Computed<Map<String, List<ProjectModel>>>(
              () => super.groupedProjects,
              name: '_ExplorerStoreBase.groupedProjects'))
          .value;

  late final _$projectsAtom =
      Atom(name: '_ExplorerStoreBase.projects', context: context);

  @override
  ObservableList<ProjectModel> get projects {
    _$projectsAtom.reportRead();
    return super.projects;
  }

  @override
  set projects(ObservableList<ProjectModel> value) {
    _$projectsAtom.reportWrite(value, super.projects, () {
      super.projects = value;
    });
  }

  late final _$groupingAtom =
      Atom(name: '_ExplorerStoreBase.grouping', context: context);

  @override
  ExplorerGrouping get grouping {
    _$groupingAtom.reportRead();
    return super.grouping;
  }

  @override
  set grouping(ExplorerGrouping value) {
    _$groupingAtom.reportWrite(value, super.grouping, () {
      super.grouping = value;
    });
  }

  late final _$pinFavouritesAtom =
      Atom(name: '_ExplorerStoreBase.pinFavourites', context: context);

  @override
  bool get pinFavourites {
    _$pinFavouritesAtom.reportRead();
    return super.pinFavourites;
  }

  @override
  set pinFavourites(bool value) {
    _$pinFavouritesAtom.reportWrite(value, super.pinFavourites, () {
      super.pinFavourites = value;
    });
  }

  late final _$sortAscendingAtom =
      Atom(name: '_ExplorerStoreBase.sortAscending', context: context);

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

  late final _$loadProjectsAsyncAction =
      AsyncAction('_ExplorerStoreBase.loadProjects', context: context);

  @override
  Future<void> loadProjects() {
    return _$loadProjectsAsyncAction.run(() => super.loadProjects());
  }

  late final _$setGroupingAsyncAction =
      AsyncAction('_ExplorerStoreBase.setGrouping', context: context);

  @override
  Future<void> setGrouping(ExplorerGrouping value) {
    return _$setGroupingAsyncAction.run(() => super.setGrouping(value));
  }

  late final _$togglePinFavouritesAsyncAction =
      AsyncAction('_ExplorerStoreBase.togglePinFavourites', context: context);

  @override
  Future<void> togglePinFavourites() {
    return _$togglePinFavouritesAsyncAction
        .run(() => super.togglePinFavourites());
  }

  late final _$toggleFavouriteAsyncAction =
      AsyncAction('_ExplorerStoreBase.toggleFavourite', context: context);

  @override
  Future<void> toggleFavourite(ProjectModel project) {
    return _$toggleFavouriteAsyncAction
        .run(() => super.toggleFavourite(project));
  }

  late final _$_ExplorerStoreBaseActionController =
      ActionController(name: '_ExplorerStoreBase', context: context);

  @override
  void toggleNameSort() {
    final _$actionInfo = _$_ExplorerStoreBaseActionController.startAction(
        name: '_ExplorerStoreBase.toggleNameSort');
    try {
      return super.toggleNameSort();
    } finally {
      _$_ExplorerStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
projects: ${projects},
grouping: ${grouping},
pinFavourites: ${pinFavourites},
sortAscending: ${sortAscending},
visibleProjects: ${visibleProjects},
groupedProjects: ${groupedProjects}
    ''';
  }
}
