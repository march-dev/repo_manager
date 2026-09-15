import 'package:flutter/material.dart';

/// A small icon shown as an image asset when one is given, falling back to
/// a plain [IconData] glyph otherwise — the "logo, or a generic fallback
/// glyph" pattern used for a language/framework's own small icon wherever
/// that icon might not have a dedicated asset.
class AssetOrFallbackIcon extends StatelessWidget {
  const AssetOrFallbackIcon({
    super.key,
    required this.iconAsset,
    required this.fallbackIcon,
    this.size = 14,
    this.color,
  });

  final String? iconAsset;
  final IconData fallbackIcon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconAsset = this.iconAsset;

    return SizedBox(
      width: size,
      height: size,
      child: iconAsset != null
          ? Image.asset(iconAsset)
          : Icon(fallbackIcon, size: size, color: color),
    );
  }
}
