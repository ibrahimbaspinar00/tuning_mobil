import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// Comprehensive performance optimization utilities
class PerformanceOptimizer {
  static bool _isOptimized = false;

  /// Initialize all performance optimizations
  static void initialize() {
    if (_isOptimized) return;
    
    _optimizeImageCache();
    _optimizeTextRendering();
    _optimizeSystemUI();
    _optimizeMemory();
    
    _isOptimized = true;
    
    if (kDebugMode) {
      debugPrint('PerformanceOptimizer: All optimizations applied');
    }
  }

  /// Optimize image cache settings
  static void _optimizeImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = 100; // Limit to 100 images
    imageCache.maximumSizeBytes = 50 << 20; // 50MB limit
  }

  /// Optimize text rendering
  static void _optimizeTextRendering() {
    // Disable text scaling for better performance
    // This is handled in MaterialApp builder
  }

  /// Optimize system UI
  static void _optimizeSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Optimize memory usage
  static void _optimizeMemory() {
    // Clear image cache periodically
    Timer.periodic(const Duration(minutes: 5), (_) {
      _clearImageCache();
    });
  }

  /// Clear image cache
  static void _clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    if (kDebugMode) {
      debugPrint('PerformanceOptimizer: Image cache cleared');
    }
  }

  /// Optimize widget building
  static Widget optimizedBuilder({
    required Widget Function(BuildContext) builder,
    bool enableCaching = true,
  }) {
    if (!enableCaching) {
      return Builder(builder: builder);
    }

    return Builder(
      builder: (context) {
        // Use RepaintBoundary for expensive widgets
        return RepaintBoundary(
          child: builder(context),
        );
      },
    );
  }

  /// Optimize list performance
  static Widget optimizedListView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const BouncingScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }

  /// Optimize grid performance
  static Widget optimizedGridView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const BouncingScrollPhysics(),
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }

  /// Optimize image loading
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Icon(Icons.error),
          );
        },
        // Performance optimizations
        cacheWidth: width != null && width.isFinite ? width.toInt() : null,
        cacheHeight: height != null && height.isFinite ? height.toInt() : null,
      ),
    );
  }

  /// Measure performance
  static Future<T> measurePerformance<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      if (kDebugMode) {
        debugPrint('PerformanceOptimizer: $operationName completed in ${stopwatch.elapsedMilliseconds}ms');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      if (kDebugMode) {
        debugPrint('PerformanceOptimizer: $operationName failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      }
      
      rethrow;
    }
  }

  /// Optimize scaffold
  static Widget optimizedScaffold({
    required Widget body,
    AppBar? appBar,
    Widget? bottomNavigationBar,
    Widget? floatingActionButton,
    bool resizeToAvoidBottomInset = false,
  }) {
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

/// Performance monitoring utilities
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};

  /// Start timing an operation
  static void startTimer(String operationName) {
    _timers[operationName] = Stopwatch()..start();
  }

  /// End timing an operation
  static void endTimer(String operationName) {
    final timer = _timers.remove(operationName);
    if (timer != null) {
      timer.stop();
      if (kDebugMode) {
        debugPrint('PerformanceMonitor: $operationName took ${timer.elapsedMilliseconds}ms');
      }
    }
  }

  /// Measure sync operation
  static T measureSync<T>(String operationName, T Function() operation) {
    startTimer(operationName);
    try {
      return operation();
    } finally {
      endTimer(operationName);
    }
  }

  /// Measure async operation
  static Future<T> measureAsync<T>(String operationName, Future<T> Function() operation) async {
    startTimer(operationName);
    try {
      return await operation();
    } finally {
      endTimer(operationName);
    }
  }
}
