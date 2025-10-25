import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Optimized ListView widget with performance improvements
class OptimizedListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Axis scrollDirection;

  const OptimizedListView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.scrollDirection = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('OptimizedListView: Building with ${children.length} items');
    }

    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      scrollDirection: scrollDirection,
      itemCount: children.length,
      itemBuilder: (context, index) {
        // Performance optimization: Only build visible items
        return children[index];
      },
    );
  }
}

/// Optimized GridView widget with performance improvements
class OptimizedGridView extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedGridView({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('OptimizedGridView: Building with ${children.length} items');
    }

    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        // Performance optimization: Only build visible items
        return children[index];
      },
    );
  }
}

/// Performance monitoring for list operations
class ListPerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};

  static void startOperation(String name) {
    if (kDebugMode) {
      _timers[name] = Stopwatch()..start();
      debugPrint('ListPerformanceMonitor: Operation "$name" started.');
    }
  }

  static void endOperation(String name) {
    if (kDebugMode) {
      final stopwatch = _timers.remove(name);
      if (stopwatch != null) {
        stopwatch.stop();
        debugPrint('ListPerformanceMonitor: Operation "$name" completed in ${stopwatch.elapsedMicroseconds} µs.');
      }
    }
  }

  static Future<T> measureAsync<T>(String name, Future<T> Function() operation) async {
    startOperation(name);
    try {
      return await operation();
    } finally {
      endOperation(name);
    }
  }
}
