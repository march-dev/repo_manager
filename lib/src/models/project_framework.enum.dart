import 'package:flutter/material.dart';

/// A framework layered on top of a project's underlying language — shown
/// alongside it (e.g. "Dart · Flutter", "JavaScript · React"), not instead
/// of it. A [ProjectModel] with no recognized framework leaves this null,
/// so the UI just shows the plain language on its own.
enum ProjectFramework {
  flutter('Flutter', 'assets/images/framework/flutter.webp', Color(0xFF02569B)),
  reactJs('React', 'assets/images/framework/react.webp', Color(0xFF61DAFB)),
  reactNative(
      'React Native', 'assets/images/framework/react.webp', Color(0xFF00D8FF)),
  vueJs('Vue.js', 'assets/images/framework/vue-js.webp', Color(0xFF4FC08D)),
  nuxt('Nuxt', 'assets/images/framework/nuxt-js.png', Color(0xFF00DC82)),
  angular('Angular', 'assets/images/framework/angular.webp', Color(0xFFDD0031)),
  nextJs('Next.js', 'assets/images/framework/nextjs.webp', Color(0xFF9CA3AF)),
  svelte('Svelte', 'assets/images/framework/svelte.png', Color(0xFFFF3E00)),
  astro('Astro', 'assets/images/framework/astro-dark.webp', Color(0xFFBC52EE)),
  nodeJs('Node.js', 'assets/images/framework/node-js.png', Color(0xFF339933)),
  express(
      'Express', 'assets/images/framework/express-dark.png', Color(0xFF909090)),
  fastify(
      'Fastify', 'assets/images/framework/fastify-dark.png', Color(0xFF37BEB0)),
  nestJs('NestJS', 'assets/images/framework/nest-js.png', Color(0xFFE0234E)),
  xamarin('Xamarin', 'assets/images/framework/xamarin.png', Color(0xFF3498DB)),
  unity('Unity', 'assets/images/framework/unity.webp', Color(0xFFBFBFBF)),
  unrealEngine('Unreal Engine',
      'assets/images/framework/unreal-engine-dark.webp', Color(0xFF4A4A6A)),
  capacitor(
      'Capacitor', 'assets/images/framework/capacitor.png', Color(0xFF119EFF)),
  cordova('Cordova', 'assets/images/framework/apache-cordova-dark.png',
      Color(0xFF35434D)),
  ionic('Ionic', 'assets/images/framework/ionic.png', Color(0xFF3880FF)),
  nativeScript('NativeScript', 'assets/images/framework/nativescript.png',
      Color(0xFF7B61FF)),
  ;

  const ProjectFramework(this.label, this.iconAsset, this.color);

  final String label;
  final String? iconAsset;

  /// A brand-ish colour for this framework — reused for [CompositionBar]'s
  /// GitHub-style stacked bar/legend the same way [ProjectLanguage.color]
  /// is. GitHub itself has no per-framework colour scheme (frameworks
  /// aren't languages), so these are chosen to be distinct and, where a
  /// framework has a well-known brand colour (React's cyan, Vue's green,
  /// Angular's red, ...), close to it.
  final Color color;
}
