import 'package:flutter/material.dart';

/// Overlapping "avatar stack" of icon assets — the familiar way UIs show a
/// small cluster of related things as one badge, rather than a row of
/// separately-gapped icons that reads as an arbitrary list.
class IconStack extends StatelessWidget {
  const IconStack({
    super.key,
    required this.iconAssets,
    this.size = 20,
    this.overlap = 12,
  });

  final List<String> iconAssets;
  final double size;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size + (iconAssets.length - 1) * overlap,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < iconAssets.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                width: size,
                height: size,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: colorScheme.surfaceContainerHighest,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Image(
                    image: AssetImage(iconAssets[i]),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
