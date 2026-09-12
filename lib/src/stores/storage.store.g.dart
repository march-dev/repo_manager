// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage.store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$StorageStore on _StorageStoreBase, Store {
  Computed<int>? _$totalBytesComputed;

  @override
  int get totalBytes =>
      (_$totalBytesComputed ??= Computed<int>(() => super.totalBytes,
              name: '_StorageStoreBase.totalBytes'))
          .value;
  Computed<int>? _$coreBytesComputed;

  @override
  int get coreBytes =>
      (_$coreBytesComputed ??= Computed<int>(() => super.coreBytes,
              name: '_StorageStoreBase.coreBytes'))
          .value;
  Computed<int>? _$cacheBytesComputed;

  @override
  int get cacheBytes =>
      (_$cacheBytesComputed ??= Computed<int>(() => super.cacheBytes,
              name: '_StorageStoreBase.cacheBytes'))
          .value;
  Computed<List<ProjectItemStore>>? _$sortedItemsComputed;

  @override
  List<ProjectItemStore> get sortedItems => (_$sortedItemsComputed ??=
          Computed<List<ProjectItemStore>>(() => super.sortedItems,
              name: '_StorageStoreBase.sortedItems'))
      .value;

  late final _$itemsAtom =
      Atom(name: '_StorageStoreBase.items', context: context);

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

  late final _$sortAscendingAtom =
      Atom(name: '_StorageStoreBase.sortAscending', context: context);

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

  late final _$sortByAtom =
      Atom(name: '_StorageStoreBase.sortBy', context: context);

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

  late final _$isRefreshingAtom =
      Atom(name: '_StorageStoreBase.isRefreshing', context: context);

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

  late final _$cleaningAllAtom =
      Atom(name: '_StorageStoreBase.cleaningAll', context: context);

  @override
  bool get cleaningAll {
    _$cleaningAllAtom.reportRead();
    return super.cleaningAll;
  }

  @override
  set cleaningAll(bool value) {
    _$cleaningAllAtom.reportWrite(value, super.cleaningAll, () {
      super.cleaningAll = value;
    });
  }

  late final _$loadProjectsAsyncAction =
      AsyncAction('_StorageStoreBase.loadProjects', context: context);

  @override
  Future<void> loadProjects({bool forceRefresh = false}) {
    return _$loadProjectsAsyncAction
        .run(() => super.loadProjects(forceRefresh: forceRefresh));
  }

  late final _$refreshAllAsyncAction =
      AsyncAction('_StorageStoreBase.refreshAll', context: context);

  @override
  Future<void> refreshAll() {
    return _$refreshAllAsyncAction.run(() => super.refreshAll());
  }

  late final _$cleanupAllAsyncAction =
      AsyncAction('_StorageStoreBase.cleanupAll', context: context);

  @override
  Future<void> cleanupAll() {
    return _$cleanupAllAsyncAction.run(() => super.cleanupAll());
  }

  late final _$_StorageStoreBaseActionController =
      ActionController(name: '_StorageStoreBase', context: context);

  @override
  void setSortBy(ProjectSortBy value) {
    final _$actionInfo = _$_StorageStoreBaseActionController.startAction(
        name: '_StorageStoreBase.setSortBy');
    try {
      return super.setSortBy(value);
    } finally {
      _$_StorageStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
items: ${items},
sortAscending: ${sortAscending},
sortBy: ${sortBy},
isRefreshing: ${isRefreshing},
cleaningAll: ${cleaningAll},
totalBytes: ${totalBytes},
coreBytes: ${coreBytes},
cacheBytes: ${cacheBytes},
sortedItems: ${sortedItems}
    ''';
  }
}
