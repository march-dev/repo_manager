// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_item_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ProjectItemState on _ProjectItemStateBase, Store {
  late final _$projectAtom =
      Atom(name: '_ProjectItemStateBase.project', context: context);

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

  late final _$sizeAtom =
      Atom(name: '_ProjectItemStateBase.size', context: context);

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

  late final _$cleaningAtom =
      Atom(name: '_ProjectItemStateBase.cleaning', context: context);

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

  late final _$loadSizeAsyncAction =
      AsyncAction('_ProjectItemStateBase.loadSize', context: context);

  @override
  Future<void> loadSize({bool forceRefresh = false}) {
    return _$loadSizeAsyncAction
        .run(() => super.loadSize(forceRefresh: forceRefresh));
  }

  late final _$_refreshSizeAsyncAction =
      AsyncAction('_ProjectItemStateBase._refreshSize', context: context);

  @override
  Future<void> _refreshSize({bool forceRefresh = false}) {
    return _$_refreshSizeAsyncAction
        .run(() => super._refreshSize(forceRefresh: forceRefresh));
  }

  late final _$cleanupAsyncAction =
      AsyncAction('_ProjectItemStateBase.cleanup', context: context);

  @override
  Future<void> cleanup() {
    return _$cleanupAsyncAction.run(() => super.cleanup());
  }

  late final _$_ProjectItemStateBaseActionController =
      ActionController(name: '_ProjectItemStateBase', context: context);

  @override
  void updateProject(ProjectModel updated) {
    final _$actionInfo = _$_ProjectItemStateBaseActionController.startAction(
        name: '_ProjectItemStateBase.updateProject');
    try {
      return super.updateProject(updated);
    } finally {
      _$_ProjectItemStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
project: ${project},
size: ${size},
cleaning: ${cleaning}
    ''';
  }
}
