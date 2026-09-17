import 'package:flutter/material.dart';

/// Hex string for [color] — "#RRGGBB". Alpha is dropped rather than
/// included (unlike a plain `#AARRGGBB` dump of [Color.toARGB32]) since
/// every color this is used on is fully opaque, and a redundant "FF" only
/// makes the value harder to paste elsewhere as-is.
String toHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// The classic recipe for deriving a full 50-900 [MaterialColor] swatch
/// from a single color — Material 2's own `ColorScheme.fromSwatch` needs
/// one of these, not a bare [Color] the way Material 3's `fromSeed` does.
MaterialColor materialColorFromSeed(Color seed) {
  const strengths = [.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
  final r = (seed.r * 255).round();
  final g = (seed.g * 255).round();
  final b = (seed.b * 255).round();

  final swatch = <int, Color>{};
  for (final strength in strengths) {
    final ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromARGB(
      255,
      (r + ((ds < 0 ? r : (255 - r)) * ds)).round(),
      (g + ((ds < 0 ? g : (255 - g)) * ds)).round(),
      (b + ((ds < 0 ? b : (255 - b)) * ds)).round(),
    );
  }
  return MaterialColor(seed.toARGB32(), swatch);
}
