import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart';

Future<String?> pickImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
  );

  if (result?.paths.singleOrNull != null) {
    return result!.paths.single!;
  }

  return null;
}

Future<void> resizeImage(
  String sourcePath,
  String targetPath,
  int size, {
  bool removeAlpha = false,
}) async {
  final cmd = Command()
    ..decodeImageFile(sourcePath)
    ..copyResize(
      width: size,
      height: size,
      maintainAspect: true,
      interpolation: Interpolation.cubic,
    );

  if (removeAlpha) {
    cmd.encodeJpg();
  }

  cmd.writeToFile(targetPath);

  await cmd.executeThread();
}
