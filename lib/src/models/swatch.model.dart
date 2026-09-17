import 'package:flutter/material.dart';

/// One named color role (e.g. "Primary" -> `colorScheme.primary`) and the
/// value it currently resolves to.
typedef Swatch = ({String label, Color color});

/// A related group of [Swatch]es, sectioned the way a design system's own
/// docs group them.
typedef SwatchGroup = ({String title, List<Swatch> swatches});
