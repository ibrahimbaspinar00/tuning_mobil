import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performans izleme ve optimizasyon utility'si
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, int> _operationCounts = {};
  
  /// İşlem başlatma
  static void startOperation(String operationName) {
    _startTimes[operationName] = DateTime.now();
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
    
    if (kDebugMode) {
      debugPrint('🚀 Started: $operationName');
    }
  }
  
  /// İşlem bitirme
  static void endOperation(String operationName) {
    final startTime = _startTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      final count = _operationCounts[operationName] ?? 0;
      
      if (kDebugMode) {
        debugPrint('✅ Completed: $operationName in ${duration.inMilliseconds}ms (Count: $count)');
      }
      
      // Yavaş işlemleri uyar
      if (duration.inMilliseconds > 100) {
        debugPrint('⚠️ Slow operation: $operationName took ${duration.inMilliseconds}ms');
      }
    }
  }
  
  /// Widget build performansı
  static Widget measureBuild(String widgetName, Widget Function() builder) {
    if (kDebugMode) {
      startOperation('Build_$widgetName');
    }
    
    final widget = builder();
    
    if (kDebugMode) {
      endOperation('Build_$widgetName');
    }
    
    return widget;
  }
  
  /// Async işlem performansı
  static Future<T> measureAsync<T>(String operationName, Future<T> Function() operation) async {
    startOperation(operationName);
    try {
      final result = await operation();
      endOperation(operationName);
      return result;
    } catch (e) {
      endOperation(operationName);
      rethrow;
    }
  }
  
  /// Memory kullanımı
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      debugPrint('📊 Memory usage at $context');
    }
  }
  
  /// Cache temizleme
  static void clearCaches() {
    // Non-blocking cache clearing
    Future.microtask(() {
      imageCache.clear();
      imageCache.clearLiveImages();
      if (kDebugMode) {
        debugPrint('🧹 Caches cleared');
      }
    });
  }
  
  /// Performans raporu
  static void printPerformanceReport() {
    if (kDebugMode) {
      debugPrint('📈 Performance Report:');
      _operationCounts.forEach((operation, count) {
        debugPrint('  $operation: $count times');
      });
    }
  }
}

/// Performans optimizasyonlu widget wrapper
class PerformanceWidget extends StatelessWidget {
  final String name;
  final Widget child;
  final bool enableMeasurement;
  
  const PerformanceWidget({
    super.key,
    required this.name,
    required this.child,
    this.enableMeasurement = kDebugMode,
  });
  
  @override
  Widget build(BuildContext context) {
    if (enableMeasurement) {
      return PerformanceMonitor.measureBuild(name, () => child);
    }
    return child;
  }
}

/// Lazy loading için optimized list widget
class OptimizedListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final Axis scrollDirection;
  
  const OptimizedListView({
    super.key,
    required this.children,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      scrollDirection: scrollDirection,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return PerformanceWidget(
          name: 'ListItem_$index',
          child: children[index],
        );
      },
    );
  }
}

/// Optimized grid view
class OptimizedGridView extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  
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
  });
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        return PerformanceWidget(
          name: 'GridItem_$index',
          child: children[index],
        );
      },
    );
  }
}
