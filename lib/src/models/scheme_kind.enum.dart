/// Which design system's palette is currently previewed by the Colour
/// Scheme Tool screen. Material 2/3 are both generated from a picked seed
/// color; Cupertino has no such generator of its own and always shows
/// Apple's fixed system palette regardless of the seed; [thisApp] shows
/// this app's own real (fixed, hand-picked) `ColorScheme`, likewise
/// regardless of the seed.
enum SchemeKind { material3, material2, cupertino, thisApp }
