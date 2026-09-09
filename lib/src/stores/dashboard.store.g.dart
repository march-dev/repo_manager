// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard.store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$DashboardStore on _DashboardStoreBase, Store {
  Computed<List<ProjectItemStore>>? _$sortedItemsComputed;

  @override
  List<ProjectItemStore> get sortedItems => (_$sortedItemsComputed ??=
          Computed<List<ProjectItemStore>>(() => super.sortedItems,
              name: '_DashboardStoreBase.sortedItems'))
      .value;
  Computed<int>? _$totalBytesComputed;

  @override
  int get totalBytes =>
      (_$totalBytesComputed ??= Computed<int>(() => super.totalBytes,
              name: '_DashboardStoreBase.totalBytes'))
          .value;
  Computed<int>? _$coreBytesComputed;

  @override
  int get coreBytes =>
      (_$coreBytesComputed ??= Computed<int>(() => super.coreBytes,
              name: '_DashboardStoreBase.coreBytes'))
          .value;
  Computed<int>? _$cacheBytesComputed;

  @override
  int get cacheBytes =>
      (_$cacheBytesComputed ??= Computed<int>(() => super.cacheBytes,
              name: '_DashboardStoreBase.cacheBytes'))
          .value;

  late final _$itemsAtom =
      Atom(name: '_DashboardStoreBase.items', context: context);

  @override
  ObservableList<ProjectItemStore> get items {
    _$itemsAtom.reportRead();
    return super.items;
  }

  @override
  set items(ObservableList<ProjectItemStore> value) {
    _$itemsAtom.reportWrite(value, super.items, () {
      super.items = value;
    });
  }

  late final _$isRefreshingAtom =
      Atom(name: '_DashboardStoreBase.isRefreshing', context: context);

  @override
  bool get isRefreshing {
    _$isRefreshingAtom.reportRead();
    return super.isRefreshing;
  }

  @override
  set isRefreshing(bool value) {
    _$isRefreshingAtom.reportWrite(value, super.isRefreshing, () {
      super.isRefreshing = value;
    });
  }

  late final _$sortByAtom =
      Atom(name: '_DashboardStoreBase.sortBy', context: context);

  @override
  ProjectSortBy get sortBy {
    _$sortByAtom.reportRead();
    return super.sortBy;
  }

  @override
  set sortBy(ProjectSortBy value) {
    _$sortByAtom.reportWrite(value, super.sortBy, () {
      super.sortBy = value;
    });
  }

  late final _$sortAscendingAtom =
      Atom(name: '_DashboardStoreBase.sortAscending', context: context);

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
      AsyncAction('_DashboardStoreBase.loadProjects', context: context);

  @override
  Future<void> loadProjects({bool forceRefresh = false}) {
    return _$loadProjectsAsyncAction
        .run(() => super.loadProjects(forceRefresh: forceRefresh));
  }

  late final _$refreshAllAsyncAction =
      AsyncAction('_DashboardStoreBase.refreshAll', context: context);

  @override
  Future<void> refreshAll() {
    return _$refreshAllAsyncAction.run(() => super.refreshAll());
  }

  late final _$_DashboardStoreBaseActionController =
      ActionController(name: '_DashboardStoreBase', context: context);

  @override
  void setSortBy(ProjectSortBy value) {
    final _$actionInfo = _$_DashboardStoreBaseActionController.startAction(
        name: '_DashboardStoreBase.setSortBy');
    try {
      return super.setSortBy(value);
    } finally {
      _$_DashboardStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
items: ${items},
isRefreshing: ${isRefreshing},
sortBy: ${sortBy},
sortAscending: ${sortAscending},
sortedItems: ${sortedItems},
totalBytes: ${totalBytes},
coreBytes: ${coreBytes},
cacheBytes: ${cacheBytes}
    ''';
  }
}
