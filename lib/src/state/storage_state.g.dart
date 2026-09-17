// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$StorageState on _StorageStateBase, Store {
  Computed<int>? _$totalBytesComputed;

  @override
  int get totalBytes =>
      (_$totalBytesComputed ??= Computed<int>(() => super.totalBytes,
              name: '_StorageStateBase.totalBytes'))
          .value;
  Computed<int>? _$coreBytesComputed;

  @override
  int get coreBytes =>
      (_$coreBytesComputed ??= Computed<int>(() => super.coreBytes,
              name: '_StorageStateBase.coreBytes'))
          .value;
  Computed<int>? _$cacheBytesComputed;

  @override
  int get cacheBytes =>
      (_$cacheBytesComputed ??= Computed<int>(() => super.cacheBytes,
              name: '_StorageStateBase.cacheBytes'))
          .value;
  Computed<int>? _$maxProjectTotalBytesComputed;

  @override
  int get maxProjectTotalBytes => (_$maxProjectTotalBytesComputed ??=
          Computed<int>(() => super.maxProjectTotalBytes,
              name: '_StorageStateBase.maxProjectTotalBytes'))
      .value;
  Computed<List<ProjectItemState>>? _$sortedItemsComputed;

  @override
  List<ProjectItemState> get sortedItems => (_$sortedItemsComputed ??=
          Computed<List<ProjectItemState>>(() => super.sortedItems,
              name: '_StorageStateBase.sortedItems'))
      .value;

  late final _$itemsAtom =
      Atom(name: '_StorageStateBase.items', context: context);

  @override
  ObservableList<ProjectItemState> get items {
    _$itemsAtom.reportRead();
    return super.items;
  }

  @override
  set items(ObservableList<ProjectItemState> value) {
    _$itemsAtom.reportWrite(value, super.items, () {
      super.items = value;
    });
  }

  late final _$sortAscendingAtom =
      Atom(name: '_StorageStateBase.sortAscending', context: context);

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
      Atom(name: '_StorageStateBase.sortBy', context: context);

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
      Atom(name: '_StorageStateBase.isRefreshing', context: context);

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
      Atom(name: '_StorageStateBase.cleaningAll', context: context);

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
      AsyncAction('_StorageStateBase.loadProjects', context: context);

  @override
  Future<void> loadProjects({bool forceRefresh = false}) {
    return _$loadProjectsAsyncAction
        .run(() => super.loadProjects(forceRefresh: forceRefresh));
  }

  late final _$_loadSubPackagesInBackgroundAsyncAction = AsyncAction(
      '_StorageStateBase._loadSubPackagesInBackground',
      context: context);

  @override
  Future<void> _loadSubPackagesInBackground() {
    return _$_loadSubPackagesInBackgroundAsyncAction
        .run(() => super._loadSubPackagesInBackground());
  }

  late final _$refreshSizesInBackgroundAsyncAction = AsyncAction(
      '_StorageStateBase.refreshSizesInBackground',
      context: context);

  @override
  Future<void> refreshSizesInBackground() {
    return _$refreshSizesInBackgroundAsyncAction
        .run(() => super.refreshSizesInBackground());
  }

  late final _$refreshAllAsyncAction =
      AsyncAction('_StorageStateBase.refreshAll', context: context);

  @override
  Future<void> refreshAll() {
    return _$refreshAllAsyncAction.run(() => super.refreshAll());
  }

  late final _$cleanupAllAsyncAction =
      AsyncAction('_StorageStateBase.cleanupAll', context: context);

  @override
  Future<void> cleanupAll() {
    return _$cleanupAllAsyncAction.run(() => super.cleanupAll());
  }

  late final _$_StorageStateBaseActionController =
      ActionController(name: '_StorageStateBase', context: context);

  @override
  void setSortBy(ProjectSortBy value) {
    final _$actionInfo = _$_StorageStateBaseActionController.startAction(
        name: '_StorageStateBase.setSortBy');
    try {
      return super.setSortBy(value);
    } finally {
      _$_StorageStateBaseActionController.endAction(_$actionInfo);
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
maxProjectTotalBytes: ${maxProjectTotalBytes},
sortedItems: ${sortedItems}
    ''';
  }
}
