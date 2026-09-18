/// A framework layered on top of a project's underlying language — shown
/// alongside it (e.g. "Dart · Flutter", "JavaScript · React"), not instead
/// of it. A [ProjectModel] with no recognized framework leaves this null,
/// so the UI just shows the plain language on its own.
enum ProjectFramework {
  flutter('Flutter', 'assets/images/framework/flutter.webp'),
  reactJs('React', 'assets/images/framework/react.webp'),
  // React Native has no icon asset of its own — it reuses React's, since
  // that's the mark people actually recognize. Only the label
  // distinguishes the two.
  reactNative('React Native', 'assets/images/framework/react.webp'),
  vueJs('Vue.js', 'assets/images/framework/vue-js.webp'),
  nuxt('Nuxt', 'assets/images/framework/nuxt-js.png'),
  angular('Angular', 'assets/images/framework/angular.webp'),
  nextJs('Next.js', 'assets/images/framework/nextjs.webp'),
  svelte('Svelte', 'assets/images/framework/svelte.png'),
  astro('Astro', 'assets/images/framework/astro.png'),
  nodeJs('Node.js', 'assets/images/framework/node-js.png'),
  express('Express', 'assets/images/framework/express.png'),
  fastify('Fastify', 'assets/images/framework/fastify.png'),
  nestJs('NestJS', 'assets/images/framework/nest-js.png'),
  xamarin('Xamarin', 'assets/images/framework/xamarin.png'),
  unity('Unity', 'assets/images/framework/unity.webp'),
  unrealEngine('Unreal Engine', 'assets/images/framework/unreal-engine.webp'),
  // Wraps an existing web framework choice (Angular/React/Vue/vanilla)
  // rather than replacing it — see project_language_detector.dart's own
  // detection-order comment. No icon asset of its own yet.
  capacitor('Capacitor', null),
  cordova('Cordova', null),
  ionic('Ionic', null),
  // A full framework replacement, not a wrapper — its own package (e.g.
  // "@nativescript/core") is the marker, no underlying web framework
  // dependency to prioritize over.
  nativeScript('NativeScript', null),
  ;

  const ProjectFramework(this.label, this.iconAsset);

  final String label;
  final String? iconAsset;
}
