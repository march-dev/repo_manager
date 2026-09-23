/// A framework layered on top of a project's underlying language — shown
/// alongside it (e.g. "Dart · Flutter", "JavaScript · React"), not instead
/// of it. A [ProjectModel] with no recognized framework leaves this null,
/// so the UI just shows the plain language on its own.
enum ProjectFramework {
  flutter('Flutter', 'assets/images/framework/flutter.webp'),
  reactJs('React', 'assets/images/framework/react.webp'),
  reactNative('React Native', 'assets/images/framework/react.webp'),
  vueJs('Vue.js', 'assets/images/framework/vue-js.webp'),
  nuxt('Nuxt', 'assets/images/framework/nuxt-js.png'),
  angular('Angular', 'assets/images/framework/angular.webp'),
  nextJs('Next.js', 'assets/images/framework/nextjs.webp'),
  svelte('Svelte', 'assets/images/framework/svelte.png'),
  astro('Astro', 'assets/images/framework/astro-dark.webp'),
  nodeJs('Node.js', 'assets/images/framework/node-js.png'),
  express('Express', 'assets/images/framework/express-dark.png'),
  fastify('Fastify', 'assets/images/framework/fastify-dark.png'),
  nestJs('NestJS', 'assets/images/framework/nest-js.png'),
  xamarin('Xamarin', 'assets/images/framework/xamarin.png'),
  unity('Unity', 'assets/images/framework/unity.webp'),
  unrealEngine(
      'Unreal Engine', 'assets/images/framework/unreal-engine-dark.webp'),
  capacitor('Capacitor', 'assets/images/framework/capacitor.png'),
  cordova('Cordova', 'assets/images/framework/apache-cordova-dark.png'),
  ionic('Ionic', 'assets/images/framework/ionic.png'),
  nativeScript('NativeScript', 'assets/images/framework/nativescript.png'),
  ;

  const ProjectFramework(this.label, this.iconAsset);

  final String label;
  final String? iconAsset;
}
