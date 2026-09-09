import 'package:flutter/material.dart';

enum ProjectSizeType {
  core(Colors.indigo),
  cache(Colors.orange)
  ;

  const ProjectSizeType(this.color);

  final Color color;
}

class ProjectSizeModel {
  const ProjectSizeModel({required this.totalBytes, required this.cacheBytes});

  final int totalBytes;
  final int cacheBytes;

  int get baseBytes => totalBytes - cacheBytes;
}
