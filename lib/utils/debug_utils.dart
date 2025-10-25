import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Debug ve geliştirme yardımcıları
class DebugUtils {
  // Debug modunda log yazdırma
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      final logTag = tag != null ? '[$tag]' : '[DEBUG]';
      debugPrint('$logTag $timestamp: $message');
    }
  }

  // Performance log
  static void logPerformance(String operation, Duration duration) {
    if (kDebugMode) {
      log('Performance: $operation took ${duration.inMilliseconds}ms', tag: 'PERF');
    }
  }

  // Memory usage log
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      log('Memory usage at: $context', tag: 'MEMORY');
    }
  }

  // Network log
  static void logNetwork(String url, String method, {int? statusCode}) {
    if (kDebugMode) {
      final status = statusCode != null ? ' ($statusCode)' : '';
      log('Network: $method $url$status', tag: 'NETWORK');
    }
  }

  // Error log
  static void logError(String error, {StackTrace? stackTrace}) {
    if (kDebugMode) {
      log('Error: $error', tag: 'ERROR');
      if (stackTrace != null) {
        log('Stack trace: $stackTrace', tag: 'ERROR');
      }
    }
  }

  // Warning log
  static void logWarning(String warning) {
    if (kDebugMode) {
      log('Warning: $warning', tag: 'WARNING');
    }
  }

  // Info log
  static void logInfo(String info) {
    if (kDebugMode) {
      log('Info: $info', tag: 'INFO');
    }
  }

  // Debug widget
  static Widget debugWidget({
    required Widget child,
    String? label,
    Color? borderColor,
  }) {
    if (!kDebugMode) return child;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor ?? Colors.red,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          child,
          if (label != null)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                color: Colors.red,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Debug overlay
  static Widget debugOverlay({
    required Widget child,
    Map<String, dynamic>? debugInfo,
  }) {
    if (!kDebugMode) return child;
    
    return Stack(
      children: [
        child,
        Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEBUG INFO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (debugInfo != null)
                  ...debugInfo.entries.map(
                    (entry) => Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
