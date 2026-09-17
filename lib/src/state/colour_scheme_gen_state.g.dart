// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'colour_scheme_gen_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ColourSchemeGenState on _ColourSchemeGenStateBase, Store {
  Computed<bool>? _$seedPickerDisabledComputed;

  @override
  bool get seedPickerDisabled => (_$seedPickerDisabledComputed ??=
          Computed<bool>(() => super.seedPickerDisabled,
              name: '_ColourSchemeGenStateBase.seedPickerDisabled'))
      .value;

  late final _$seedColorAtom =
      Atom(name: '_ColourSchemeGenStateBase.seedColor', context: context);

  @override
  Color get seedColor {
    _$seedColorAtom.reportRead();
    return super.seedColor;
  }

  @override
  set seedColor(Color value) {
    _$seedColorAtom.reportWrite(value, super.seedColor, () {
      super.seedColor = value;
    });
  }

  late final _$kindAtom =
      Atom(name: '_ColourSchemeGenStateBase.kind', context: context);

  @override
  SchemeKind get kind {
    _$kindAtom.reportRead();
    return super.kind;
  }

  @override
  set kind(SchemeKind value) {
    _$kindAtom.reportWrite(value, super.kind, () {
      super.kind = value;
    });
  }

  late final _$_ColourSchemeGenStateBaseActionController =
      ActionController(name: '_ColourSchemeGenStateBase', context: context);

  @override
  void setSeedColor(Color color) {
    final _$actionInfo = _$_ColourSchemeGenStateBaseActionController
        .startAction(name: '_ColourSchemeGenStateBase.setSeedColor');
    try {
      return super.setSeedColor(color);
    } finally {
      _$_ColourSchemeGenStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setKind(SchemeKind value) {
    final _$actionInfo = _$_ColourSchemeGenStateBaseActionController
        .startAction(name: '_ColourSchemeGenStateBase.setKind');
    try {
      return super.setKind(value);
    } finally {
      _$_ColourSchemeGenStateBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
seedColor: ${seedColor},
kind: ${kind},
seedPickerDisabled: ${seedPickerDisabled}
    ''';
  }
}
