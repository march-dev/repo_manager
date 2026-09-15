import 'package:flutter/material.dart';

/// A small colored circle, typically paired with a label to indicate what a
/// [SizeBar] segment (or any other color-coded legend entry) represents.
class ColorDot extends StatelessWidget {
  const ColorDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
