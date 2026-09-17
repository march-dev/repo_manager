import 'dart:io';

import '../models/generate_icons_type.enum.dart';
import 'image.util.dart';

const _androidAnyDpiXml = {
  'mipmap-anydpi-v26/ic_launcher.xml': '''
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
''',
};
const _androidImages = {
  'mipmap-mdpi/ic_launcher.png': 48,
  'mipmap-hdpi/ic_launcher.png': 72,
  'mipmap-xhdpi/ic_launcher.png': 96,
  'mipmap-xxhdpi/ic_launcher.png': 144,
  'mipmap-xxxhdpi/ic_launcher.png': 192,
};
const _androidBgImages = {
  'mipmap-mdpi/ic_launcher_background.png': 108,
  'mipmap-hdpi/ic_launcher_background.png': 162,
  'mipmap-xhdpi/ic_launcher_background.png': 216,
  'mipmap-xxhdpi/ic_launcher_background.png': 324,
  'mipmap-xxxhdpi/ic_launcher_background.png': 432,
};
const _androidFgImages = {
  'mipmap-mdpi/ic_launcher_foreground.png': 108,
  'mipmap-hdpi/ic_launcher_foreground.png': 162,
  'mipmap-xhdpi/ic_launcher_foreground.png': 216,
  'mipmap-xxhdpi/ic_launcher_foreground.png': 324,
  'mipmap-xxxhdpi/ic_launcher_foreground.png': 432,
};
const _androidMcImages = {
  'mipmap-mdpi/ic_launcher_monochrome.png': 108,
  'mipmap-hdpi/ic_launcher_monochrome.png': 162,
  'mipmap-xhdpi/ic_launcher_monochrome.png': 216,
  'mipmap-xxhdpi/ic_launcher_monochrome.png': 324,
  'mipmap-xxxhdpi/ic_launcher_monochrome.png': 432,
};

const _iosContentsJson = {
  'AppIcon.appiconset/Contents.json': '''
{
  "images" : [
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-60x60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-60x60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-20x20@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-76x76@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-76x76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-83.5x83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "ItunesArtwork@2x.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
''',
};
const _iosImages = {
  'AppIcon.appiconset/ItunesArtwork@2x.png': 1024,
  'AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
  'AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
  'AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
  'AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
  'AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
  'AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
  'AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
  'AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
  'AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
  'AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
  'AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
  'AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
  'AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
  'AppIcon.appiconset/Icon-App-83.5x83.5@2x.png': 167,
};

Future<void> generateIcons({
  required String srcPath,
  String srcABgPath = '',
  String srcAFgPath = '',
  String dirToSave = '',
  GenerateIconsType type = GenerateIconsType.both,
}) async {
  if (type == GenerateIconsType.android || type == GenerateIconsType.both) {
    _androidImages.forEach(
      (path, size) => resizeImage(srcPath, '$dirToSave/$path', size),
    );

    if (srcABgPath.isNotEmpty && srcAFgPath.isNotEmpty) {
      _androidAnyDpiXml.forEach((path, content) async {
        final file = File('$dirToSave/$path');
        await file.create(recursive: true);
        await file.writeAsString(content);
      });
      _androidBgImages.forEach(
        (path, size) => resizeImage(srcABgPath, '$dirToSave/$path', size),
      );
      _androidFgImages.forEach(
        (path, size) => resizeImage(srcAFgPath, '$dirToSave/$path', size),
      );
      _androidMcImages.forEach(
        (path, size) => resizeImage(srcAFgPath, '$dirToSave/$path', size),
      );
    }
  }

  if (type == GenerateIconsType.ios || type == GenerateIconsType.both) {
    _iosContentsJson.forEach((path, content) async {
      final file = File('$dirToSave/$path');
      await file.create(recursive: true);
      await file.writeAsString(content);
    });
    _iosImages.forEach(
      (path, size) =>
          resizeImage(srcPath, '$dirToSave/$path', size, removeAlpha: true),
    );
  }
}
