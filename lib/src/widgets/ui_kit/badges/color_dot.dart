import 'package:flutter/material.dart';

/// A small colored circle, typically paired with a label to indicate what a
/// [SizeBar] segment (or any other color-coded legend entry) represents.
class ColorDot extends StatelessWidget {
  const ColorDot({super.key, required this.color, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
