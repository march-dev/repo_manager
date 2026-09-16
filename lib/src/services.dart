// Pure domain logic with no persistence of its own — detection, icon
// discovery, (de)serialization. Kept separate from repos/ (which all read
// from or write to the shared Hive box) since these aren't repositories.
export 'services/project_icon_finder.dart';
export 'services/project_language_detector.dart';
export 'services/project_model_codec.dart';
