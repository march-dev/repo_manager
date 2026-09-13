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
  ;

  const ProjectFramework(this.label, this.iconAsset);

  final String label;
  final String? iconAsset;
}
