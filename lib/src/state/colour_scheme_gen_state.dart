import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../models/scheme_kind.enum.dart';

part 'colour_scheme_gen_state.g.dart';

class ColourSchemeGenState = _ColourSchemeGenStateBase
    with _$ColourSchemeGenState;

/// Reactive UI state for the Colour Scheme Tool screen — which design
/// system is currently previewed, and the seed color driving Material
/// 2/3's generators. Purely ephemeral: nothing here is persisted, and
/// nothing outside this one screen reads it, so unlike most of this app's
/// other screen states it isn't registered in _RootScaffold's
/// MultiProvider (app.dart) — the screen provides it locally instead, the
/// same way SettingsScreen does for SettingsState.
abstract class _ColourSchemeGenStateBase with Store {
  @observable
  Color seedColor = const Color(0xFF204080);

  @observable
  SchemeKind kind = SchemeKind.material3;

  @action
  void setSeedColor(Color color) => seedColor = color;

  @action
  void setKind(SchemeKind value) => kind = value;

  // Cupertino's palette is fixed by Apple, and "This App"'s is fixed by
  // AppTheme — neither is derived from any seed, so picking one would
  // visibly do nothing; the seed-color button disables itself for both
  // rather than staying active for no effect.
  @computed
  bool get seedPickerDisabled =>
      kind == SchemeKind.cupertino || kind == SchemeKind.thisApp;
}
