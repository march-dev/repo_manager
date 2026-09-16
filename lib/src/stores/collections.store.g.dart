// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collections.store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CollectionsStore on _CollectionsStoreBase, Store {
  late final _$namesAtom =
      Atom(name: '_CollectionsStoreBase.names', context: context);

  @override
  ObservableList<String> get names {
    _$namesAtom.reportRead();
    return super.names;
  }

  @override
  set names(ObservableList<String> value) {
    _$namesAtom.reportWrite(value, super.names, () {
      super.names = value;
    });
  }

  late final _$membershipVersionAtom =
      Atom(name: '_CollectionsStoreBase.membershipVersion', context: context);

  @override
  int get membershipVersion {
    _$membershipVersionAtom.reportRead();
    return super.membershipVersion;
  }

  @override
  set membershipVersion(int value) {
    _$membershipVersionAtom.reportWrite(value, super.membershipVersion, () {
      super.membershipVersion = value;
    });
  }

  late final _$createCollectionAsyncAction =
      AsyncAction('_CollectionsStoreBase.createCollection', context: context);

  @override
  Future<void> createCollection(String name) {
    return _$createCollectionAsyncAction
        .run(() => super.createCollection(name));
  }

  late final _$toggleProjectCollectionAsyncAction = AsyncAction(
      '_CollectionsStoreBase.toggleProjectCollection',
      context: context);

  @override
  Future<void> toggleProjectCollection(
      String projectPath, String collectionName) {
    return _$toggleProjectCollectionAsyncAction
        .run(() => super.toggleProjectCollection(projectPath, collectionName));
  }

  late final _$renameCollectionAsyncAction =
      AsyncAction('_CollectionsStoreBase.renameCollection', context: context);

  @override
  Future<void> renameCollection(String oldName, String newName) {
    return _$renameCollectionAsyncAction
        .run(() => super.renameCollection(oldName, newName));
  }

  late final _$deleteCollectionAsyncAction =
      AsyncAction('_CollectionsStoreBase.deleteCollection', context: context);

  @override
  Future<void> deleteCollection(String name) {
    return _$deleteCollectionAsyncAction
        .run(() => super.deleteCollection(name));
  }

  @override
  String toString() {
    return '''
names: ${names},
membershipVersion: ${membershipVersion}
    ''';
  }
}
