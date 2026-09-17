import 'package:mobx/mobx.dart';

import '../models/generate_icons_type.enum.dart';
import '../utils/icon_generator.util.dart';

part 'app_icon_gen_state.g.dart';

class AppIconGenState = _AppIconGenStateBase with _$AppIconGenState;

/// Reactive UI state for the App Icon Generator screen — which platforms
/// to generate for, the source image(s) picked so far, and whether a
/// generate run is currently in flight. Purely ephemeral: nothing here is
/// persisted, and nothing outside this one screen reads it, so — like
/// ColourSchemeGenState — it isn't registered in _RootScaffold's
/// MultiProvider (app.dart); the screen provides it locally instead.
abstract class _AppIconGenStateBase with Store {
  @observable
  GenerateIconsType type = GenerateIconsType.both;

  @observable
  String srcPath = '';

  @observable
  String srcABgPath = '';

  @observable
  String srcAFgPath = '';

  @observable
  bool isGenerating = false;

  @action
  void setType(GenerateIconsType value) => type = value;

  @action
  void setSrcPath(String path) => srcPath = path;

  @action
  void setSrcABgPath(String path) => srcABgPath = path;

  @action
  void setSrcAFgPath(String path) => srcAFgPath = path;

  // The Android adaptive-icon background/foreground pair is optional, but
  // only as a pair — generateIcons only wires up the adaptive-icon XML
  // when both are given, and has nowhere sensible to fall back to if just
  // one half of the pair is set.
  @computed
  bool get canGenerate =>
      srcPath.isNotEmpty && srcABgPath.isEmpty == srcAFgPath.isEmpty;

  @action
  Future<void> generate(String dirToSave) async {
    isGenerating = true;
    try {
      await generateIcons(
        srcPath: srcPath,
        srcABgPath: srcABgPath,
        srcAFgPath: srcAFgPath,
        dirToSave: dirToSave,
        type: type,
      );
    } finally {
      isGenerating = false;
    }
  }
}
