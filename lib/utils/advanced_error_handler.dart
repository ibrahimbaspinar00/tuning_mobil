import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

/// Gelişmiş hata yönetimi ve loglama sistemi
class AdvancedErrorHandler {
  static final List<ErrorLog> _errorLogs = [];
  static const int _maxLogs = 100;
  
  /// Hata yakalama ve loglama
  static void handleError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool showToUser = false,
  }) {
    final errorLog = ErrorLog(
      error: error.toString(),
      stackTrace: stackTrace?.toString(),
      context: context ?? 'Unknown',
      timestamp: DateTime.now(),
      additionalData: additionalData,
    );
    
    _addToLogs(errorLog);
    
    // Debug modunda detaylı log
    if (kDebugMode) {
      developer.log(
        'Error: ${error.toString()}',
        name: 'AdvancedErrorHandler',
        error: error,
        stackTrace: stackTrace,
      );
    }
    
    // Kullanıcıya gösterilecekse SnackBar göster
    if (showToUser) {
      _showErrorToUser(error.toString());
    }
  }
  
  /// Async hata yakalama
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    String? context,
    T? fallbackValue,
    bool showToUser = false,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace,
        context: context,
        showToUser: showToUser,
      );
      return fallbackValue;
    }
  }
  
  /// Widget hata yakalama
  static Widget handleWidget(
    Widget Function() builder, {
    String? context,
    Widget? fallbackWidget,
  }) {
    try {
      return builder();
    } catch (error, stackTrace) {
      handleError(
        error,
        stackTrace,
        context: context ?? 'Widget Builder',
      );
      return fallbackWidget ?? const SizedBox.shrink();
    }
  }
  
  /// Log ekleme
  static void _addToLogs(ErrorLog log) {
    _errorLogs.add(log);
    
    // Maksimum log sayısını aşarsa eski logları sil
    if (_errorLogs.length > _maxLogs) {
      _errorLogs.removeRange(0, _errorLogs.length - _maxLogs);
    }
  }
  
  /// Kullanıcıya hata gösterme
  static void _showErrorToUser(String error) {
    // Global context'e erişim için bir callback sistemi gerekir
    // Bu şimdilik basit bir implementasyon
    debugPrint('User Error: $error');
  }
  
  /// Hata loglarını getir
  static List<ErrorLog> getErrorLogs() {
    return List.unmodifiable(_errorLogs);
  }
  
  /// Son N hata logunu getir
  static List<ErrorLog> getRecentErrors(int count) {
    final start = _errorLogs.length - count;
    if (start < 0) return List.unmodifiable(_errorLogs);
    return List.unmodifiable(_errorLogs.sublist(start));
  }
  
  /// Logları temizle
  static void clearLogs() {
    _errorLogs.clear();
  }
  
  /// Hata istatistikleri
  static Map<String, int> getErrorStatistics() {
    final stats = <String, int>{};
    
    for (final log in _errorLogs) {
      final context = log.context;
      stats[context] = (stats[context] ?? 0) + 1;
    }
    
    return stats;
  }
}

/// Hata log modeli
class ErrorLog {
  final String error;
  final String? stackTrace;
  final String context;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;
  
  ErrorLog({
    required this.error,
    this.stackTrace,
    required this.context,
    required this.timestamp,
    this.additionalData,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'error': error,
      'stackTrace': stackTrace,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'additionalData': additionalData,
    };
  }
  
  factory ErrorLog.fromMap(Map<String, dynamic> map) {
    return ErrorLog(
      error: map['error'] ?? '',
      stackTrace: map['stackTrace'],
      context: map['context'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      additionalData: map['additionalData'],
    );
  }
}

/// Global error handler
class GlobalErrorHandler {
  static void initialize() {
    // Flutter error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      AdvancedErrorHandler.handleError(
        details.exception,
        details.stack,
        context: 'Flutter Framework',
        additionalData: {
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
    };
    
    // Platform error handler
    PlatformDispatcher.instance.onError = (error, stack) {
      AdvancedErrorHandler.handleError(
        error,
        stack,
        context: 'Platform',
      );
      return true;
    };
  }
}
