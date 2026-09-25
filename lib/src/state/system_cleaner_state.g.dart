// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_cleaner_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SystemCleanerState on _SystemCleanerStateBase, Store {
  Computed<int>? _$totalBytesComputed;

  @override
  int get totalBytes =>
      (_$totalBytesComputed ??= Computed<int>(() => super.totalBytes,
              name: '_SystemCleanerStateBase.totalBytes'))
          .value;
  Computed<int>? _$selectedBytesComputed;

  @override
  int get selectedBytes =>
      (_$selectedBytesComputed ??= Computed<int>(() => super.selectedBytes,
              name: '_SystemCleanerStateBase.selectedBytes'))
          .value;
  Computed<List<CleanerCategory>>? _$sortedCategoriesComputed;

  @override
  List<CleanerCategory> get sortedCategories => (_$sortedCategoriesComputed ??=
          Computed<List<CleanerCategory>>(() => super.sortedCategories,
              name: '_SystemCleanerStateBase.sortedCategories'))
      .value;

  late final _$scanningAtom =
      Atom(name: '_SystemCleanerStateBase.scanning', context: context);

  @override
  bool get scanning {
    _$scanningAtom.reportRead();
    return super.scanning;
  }

  @override
  set scanning(bool value) {
    _$scanningAtom.reportWrite(value, super.scanning, () {
      super.scanning = value;
    });
  }

  late final _$isRefreshingAtom =
      Atom(name: '_SystemCleanerStateBase.isRefreshing', context: context);

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

  late final _$categoriesAtom =
      Atom(name: '_SystemCleanerStateBase.categories', context: context);

  @override
  ObservableList<CleanerCategory> get categories {
    _$categoriesAtom.reportRead();
    return super.categories;
  }

  @override
  set categories(ObservableList<CleanerCategory> value) {
    _$categoriesAtom.reportWrite(value, super.categories, () {
      super.categories = value;
    });
  }

  late final _$selectedPathsAtom =
      Atom(name: '_SystemCleanerStateBase.selectedPaths', context: context);

  @override
  ObservableSet<String> get selectedPaths {
    _$selectedPathsAtom.reportRead();
    return super.selectedPaths;
  }

  @override
  set selectedPaths(ObservableSet<String> value) {
    _$selectedPathsAtom.reportWrite(value, super.selectedPaths, () {
      super.selectedPaths = value;
    });
  }

  late final _$cleaningAtom =
      Atom(name: '_SystemCleanerStateBase.cleaning', context: context);

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

  late final _$_scanAsyncAction =
      AsyncAction('_SystemCleanerStateBase._scan', context: context);

  @override
  Future<void> _scan({required bool forceRefresh}) {
    return _$_scanAsyncAction
        .run(() => super._scan(forceRefresh: forceRefresh));
  }

  late final _$cleanSelectedAsyncAction =
      AsyncAction('_SystemCleanerStateBase.cleanSelected', context: context);

  @override
  Future<void> cleanSelected() {
    return _$cleanSelectedAsyncAction.run(() => super.cleanSelected());
  }

  late final _$_SystemCleanerStateBaseActionController =
      ActionController(name: '_SystemCleanerStateBase', context: context);

  @override
  void toggleEntry(CleanerEntry entry) {
    final _$actionInfo = _$_SystemCleanerStateBaseActionController.startAction(
        name: '_SystemCleanerStateBase.toggleEntry');
    try {
      return super.toggleEntry(entry);
    } finally {
      _$_SystemCleanerStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleCategory(CleanerCategory category) {
    final _$actionInfo = _$_SystemCleanerStateBaseActionController.startAction(
        name: '_SystemCleanerStateBase.toggleCategory');
    try {
      return super.toggleCategory(category);
    } finally {
      _$_SystemCleanerStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
scanning: ${scanning},
isRefreshing: ${isRefreshing},
categories: ${categories},
selectedPaths: ${selectedPaths},
cleaning: ${cleaning},
totalBytes: ${totalBytes},
selectedBytes: ${selectedBytes},
sortedCategories: ${sortedCategories}
    ''';
  }
}
