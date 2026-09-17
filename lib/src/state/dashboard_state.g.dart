// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_state.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$DashboardState on _DashboardStateBase, Store {
  Computed<List<ProjectModel>>? _$projectsComputed;

  @override
  List<ProjectModel> get projects =>
      (_$projectsComputed ??= Computed<List<ProjectModel>>(() => super.projects,
              name: '_DashboardStateBase.projects'))
          .value;
  Computed<int>? _$favouriteCountComputed;

  @override
  int get favouriteCount =>
      (_$favouriteCountComputed ??= Computed<int>(() => super.favouriteCount,
              name: '_DashboardStateBase.favouriteCount'))
          .value;
  Computed<int>? _$monorepoCountComputed;

  @override
  int get monorepoCount =>
      (_$monorepoCountComputed ??= Computed<int>(() => super.monorepoCount,
              name: '_DashboardStateBase.monorepoCount'))
          .value;
  Computed<int>? _$totalBytesComputed;

  @override
  int get totalBytes =>
      (_$totalBytesComputed ??= Computed<int>(() => super.totalBytes,
              name: '_DashboardStateBase.totalBytes'))
          .value;
  Computed<int>? _$coreBytesComputed;

  @override
  int get coreBytes =>
      (_$coreBytesComputed ??= Computed<int>(() => super.coreBytes,
              name: '_DashboardStateBase.coreBytes'))
          .value;
  Computed<int>? _$cacheBytesComputed;

  @override
  int get cacheBytes =>
      (_$cacheBytesComputed ??= Computed<int>(() => super.cacheBytes,
              name: '_DashboardStateBase.cacheBytes'))
          .value;
  Computed<List<ProjectModel>>? _$pinnedProjectsComputed;

  @override
  List<ProjectModel> get pinnedProjects => (_$pinnedProjectsComputed ??=
          Computed<List<ProjectModel>>(() => super.pinnedProjects,
              name: '_DashboardStateBase.pinnedProjects'))
      .value;
  Computed<Map<ProjectLanguage, int>>? _$languageCountsComputed;

  @override
  Map<ProjectLanguage, int> get languageCounts => (_$languageCountsComputed ??=
          Computed<Map<ProjectLanguage, int>>(() => super.languageCounts,
              name: '_DashboardStateBase.languageCounts'))
      .value;
  Computed<Map<ProjectFramework, int>>? _$frameworkCountsComputed;

  @override
  Map<ProjectFramework, int> get frameworkCounts =>
      (_$frameworkCountsComputed ??= Computed<Map<ProjectFramework, int>>(
              () => super.frameworkCounts,
              name: '_DashboardStateBase.frameworkCounts'))
          .value;

  @override
  String toString() {
    return '''
projects: ${projects},
favouriteCount: ${favouriteCount},
monorepoCount: ${monorepoCount},
totalBytes: ${totalBytes},
coreBytes: ${coreBytes},
cacheBytes: ${cacheBytes},
pinnedProjects: ${pinnedProjects},
languageCounts: ${languageCounts},
frameworkCounts: ${frameworkCounts}
    ''';
  }
}
