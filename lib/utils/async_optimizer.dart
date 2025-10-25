import 'dart:async';
import 'package:flutter/foundation.dart';

/// Advanced async operations optimizer
class AsyncOptimizer {
  static final Map<String, Completer> _pendingOperations = {};
  static final Map<String, Timer> _debounceTimers = {};
  static final Map<String, Timer> _throttleTimers = {};

  /// Debounce function calls to prevent excessive execution
  static void debounce(String key, VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, () {
      if (kDebugMode) {
        debugPrint('AsyncOptimizer: Executing debounced callback for key: $key');
      }
      callback();
      _debounceTimers.remove(key);
    });
  }

  /// Throttle function calls to limit execution frequency
  static void throttle(String key, VoidCallback callback, {Duration interval = const Duration(milliseconds: 500)}) {
    if (_throttleTimers.containsKey(key)) {
      return; // Already throttled
    }
    
    callback();
    _throttleTimers[key] = Timer(interval, () {
      _throttleTimers.remove(key);
    });
  }

  /// Prevent duplicate async operations
  static Future<T> preventDuplicate<T>(String key, Future<T> Function() operation) async {
    // If operation is already running, return the existing future
    if (_pendingOperations.containsKey(key)) {
      if (kDebugMode) {
        debugPrint('AsyncOptimizer: Operation already running for key: $key');
      }
      return await _pendingOperations[key]!.future as T;
    }

    // Create new completer for this operation
    final completer = Completer<T>();
    _pendingOperations[key] = completer;

    try {
      if (kDebugMode) {
        debugPrint('AsyncOptimizer: Starting operation for key: $key');
      }
      
      final result = await operation();
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingOperations.remove(key);
    }
  }

  /// Batch multiple operations together
  static Future<List<T>> batchOperations<T>(List<Future<T> Function()> operations) async {
    if (kDebugMode) {
      debugPrint('AsyncOptimizer: Batching ${operations.length} operations');
    }
    
    final futures = operations.map((op) => op()).toList();
    return await Future.wait(futures);
  }

  /// Execute operations with timeout
  static Future<T> withTimeout<T>(Future<T> Function() operation, {Duration timeout = const Duration(seconds: 10)}) async {
    return await operation().timeout(timeout);
  }

  /// Execute operations with retry logic
  static Future<T> withRetry<T>(Future<T> Function() operation, {int maxRetries = 3, Duration delay = const Duration(seconds: 1)}) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        if (kDebugMode) {
          debugPrint('AsyncOptimizer: Retry attempt $attempts for operation');
        }
        
        await Future.delayed(delay * attempts); // Exponential backoff
      }
    }
    
    throw Exception('Max retries exceeded');
  }

  /// Execute operations with circuit breaker pattern
  static Future<T> withCircuitBreaker<T>(String key, Future<T> Function() operation, {int failureThreshold = 5, Duration timeout = const Duration(minutes: 1)}) async {
    // This is a simplified circuit breaker implementation
    // In a real app, you'd want to persist the state
    
    try {
      return await operation().timeout(timeout);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AsyncOptimizer: Circuit breaker triggered for key: $key');
      }
      rethrow;
    }
  }

  /// Cancel all pending operations
  static void cancelAll() {
    if (kDebugMode) {
      debugPrint('AsyncOptimizer: Cancelling all pending operations');
    }
    
    for (final completer in _pendingOperations.values) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Operation cancelled'));
      }
    }
    _pendingOperations.clear();
    
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    
    for (final timer in _throttleTimers.values) {
      timer.cancel();
    }
    _throttleTimers.clear();
  }

  /// Get operation statistics
  static Map<String, dynamic> getStats() {
    return {
      'pendingOperations': _pendingOperations.length,
      'debounceTimers': _debounceTimers.length,
      'throttleTimers': _throttleTimers.length,
    };
  }
}
