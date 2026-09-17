// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_icon_gen_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AppIconGenState on _AppIconGenStateBase, Store {
  Computed<bool>? _$canGenerateComputed;

  @override
  bool get canGenerate =>
      (_$canGenerateComputed ??= Computed<bool>(() => super.canGenerate,
              name: '_AppIconGenStateBase.canGenerate'))
          .value;

  late final _$typeAtom =
      Atom(name: '_AppIconGenStateBase.type', context: context);

  @override
  GenerateIconsType get type {
    _$typeAtom.reportRead();
    return super.type;
  }

  @override
  set type(GenerateIconsType value) {
    _$typeAtom.reportWrite(value, super.type, () {
      super.type = value;
    });
  }

  late final _$srcPathAtom =
      Atom(name: '_AppIconGenStateBase.srcPath', context: context);

  @override
  String get srcPath {
    _$srcPathAtom.reportRead();
    return super.srcPath;
  }

  @override
  set srcPath(String value) {
    _$srcPathAtom.reportWrite(value, super.srcPath, () {
      super.srcPath = value;
    });
  }

  late final _$srcABgPathAtom =
      Atom(name: '_AppIconGenStateBase.srcABgPath', context: context);

  @override
  String get srcABgPath {
    _$srcABgPathAtom.reportRead();
    return super.srcABgPath;
  }

  @override
  set srcABgPath(String value) {
    _$srcABgPathAtom.reportWrite(value, super.srcABgPath, () {
      super.srcABgPath = value;
    });
  }

  late final _$srcAFgPathAtom =
      Atom(name: '_AppIconGenStateBase.srcAFgPath', context: context);

  @override
  String get srcAFgPath {
    _$srcAFgPathAtom.reportRead();
    return super.srcAFgPath;
  }

  @override
  set srcAFgPath(String value) {
    _$srcAFgPathAtom.reportWrite(value, super.srcAFgPath, () {
      super.srcAFgPath = value;
    });
  }

  late final _$isGeneratingAtom =
      Atom(name: '_AppIconGenStateBase.isGenerating', context: context);

  @override
  bool get isGenerating {
    _$isGeneratingAtom.reportRead();
    return super.isGenerating;
  }

  @override
  set isGenerating(bool value) {
    _$isGeneratingAtom.reportWrite(value, super.isGenerating, () {
      super.isGenerating = value;
    });
  }

  late final _$generateAsyncAction =
      AsyncAction('_AppIconGenStateBase.generate', context: context);

  @override
  Future<void> generate(String dirToSave) {
    return _$generateAsyncAction.run(() => super.generate(dirToSave));
  }

  late final _$_AppIconGenStateBaseActionController =
      ActionController(name: '_AppIconGenStateBase', context: context);

  @override
  void setType(GenerateIconsType value) {
    final _$actionInfo = _$_AppIconGenStateBaseActionController.startAction(
        name: '_AppIconGenStateBase.setType');
    try {
      return super.setType(value);
    } finally {
      _$_AppIconGenStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSrcPath(String path) {
    final _$actionInfo = _$_AppIconGenStateBaseActionController.startAction(
        name: '_AppIconGenStateBase.setSrcPath');
    try {
      return super.setSrcPath(path);
    } finally {
      _$_AppIconGenStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSrcABgPath(String path) {
    final _$actionInfo = _$_AppIconGenStateBaseActionController.startAction(
        name: '_AppIconGenStateBase.setSrcABgPath');
    try {
      return super.setSrcABgPath(path);
    } finally {
      _$_AppIconGenStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSrcAFgPath(String path) {
    final _$actionInfo = _$_AppIconGenStateBaseActionController.startAction(
        name: '_AppIconGenStateBase.setSrcAFgPath');
    try {
      return super.setSrcAFgPath(path);
    } finally {
      _$_AppIconGenStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
type: ${type},
srcPath: ${srcPath},
srcABgPath: ${srcABgPath},
srcAFgPath: ${srcAFgPath},
isGenerating: ${isGenerating},
canGenerate: ${canGenerate}
    ''';
  }
}
