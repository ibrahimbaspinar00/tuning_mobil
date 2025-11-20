import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Firestore quota yönetimi ve hata yönetimi servisi
class FirestoreQuotaManager {
  static final FirestoreQuotaManager _instance = FirestoreQuotaManager._internal();
  factory FirestoreQuotaManager() => _instance;
  FirestoreQuotaManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Quota durumu
  bool _isQuotaExceeded = false;
  DateTime? _quotaExceededAt;
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;
  
  // Rate limiting
  final Map<String, DateTime> _lastRequestTime = {};
  final Map<String, int> _requestCount = {};
  static const Duration _rateLimitWindow = Duration(minutes: 1);
  static const int _maxRequestsPerWindow = 30; // Dakikada maksimum 30 istek
  
  // Cache
  final Map<String, CacheEntry> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  /// Quota aşıldı mı?
  bool get isQuotaExceeded => _isQuotaExceeded;
  
  /// Quota aşıldığında ne zaman aşıldı?
  DateTime? get quotaExceededAt => _quotaExceededAt;
  
  /// Quota hatası kontrolü
  bool _isQuotaError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('resource_exhausted') ||
           errorString.contains('quota exceeded') ||
           errorString.contains('quota') ||
           errorString.contains('429'); // HTTP 429 Too Many Requests
  }
  
  /// Rate limit kontrolü
  bool _checkRateLimit(String operation) {
    final now = DateTime.now();
    final lastTime = _lastRequestTime[operation];
    final count = _requestCount[operation] ?? 0;
    
    if (lastTime == null || now.difference(lastTime) > _rateLimitWindow) {
      // Yeni pencere başladı
      _lastRequestTime[operation] = now;
      _requestCount[operation] = 1;
      return true;
    }
    
    if (count >= _maxRequestsPerWindow) {
      debugPrint('⚠️ Rate limit aşıldı: $operation (${count} istek)');
      return false;
    }
    
    _requestCount[operation] = count + 1;
    return true;
  }
  
  /// Cache kontrolü
  T? _getFromCache<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    if (DateTime.now().difference(entry.timestamp) > _cacheExpiry) {
      _cache.remove(key);
      return null;
    }
    
    return entry.data as T?;
  }
  
  /// Cache'e ekle
  void _addToCache(String key, dynamic data) {
    _cache[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
    );
    
    // Cache boyutunu sınırla (en fazla 100 entry)
    if (_cache.length > 100) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
  }
  
  /// Güvenli Firestore işlemi (quota kontrolü ile)
  Future<T?> safeFirestoreOperation<T>({
    required String operation,
    required Future<T> Function() operationFn,
    T? fallbackValue,
    bool useCache = false,
    String? cacheKey,
    int maxRetries = 2,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    // Quota aşıldıysa ve henüz çok yakın zamanda aşıldıysa, direkt fallback dön
    if (_isQuotaExceeded && _quotaExceededAt != null) {
      final timeSinceQuotaExceeded = DateTime.now().difference(_quotaExceededAt!);
      if (timeSinceQuotaExceeded < const Duration(minutes: 5)) {
        debugPrint('⚠️ Quota aşıldı, fallback değer dönülüyor: $operation');
        return fallbackValue;
      } else {
        // 5 dakika geçti, tekrar deneyebiliriz
        _isQuotaExceeded = false;
        _quotaExceededAt = null;
        _consecutiveFailures = 0;
      }
    }
    
    // Rate limit kontrolü
    if (!_checkRateLimit(operation)) {
      debugPrint('⚠️ Rate limit aşıldı, cache veya fallback kullanılıyor: $operation');
      if (useCache && cacheKey != null) {
        final cached = _getFromCache<T>(cacheKey);
        if (cached != null) return cached;
      }
      return fallbackValue;
    }
    
    // Cache kontrolü
    if (useCache && cacheKey != null) {
      final cached = _getFromCache<T>(cacheKey);
      if (cached != null) {
        debugPrint('✅ Cache\'den döndürüldü: $operation');
        return cached;
      }
    }
    
    // Retry mekanizması
    int retryCount = 0;
    while (retryCount <= maxRetries) {
      try {
        final result = await operationFn();
        
        // Başarılı oldu, quota durumunu sıfırla
        _consecutiveFailures = 0;
        if (_isQuotaExceeded) {
          _isQuotaExceeded = false;
          _quotaExceededAt = null;
          debugPrint('✅ Quota durumu normale döndü');
        }
        
        // Cache'e ekle
        if (useCache && cacheKey != null && result != null) {
          _addToCache(cacheKey, result);
        }
        
        return result;
      } catch (e) {
        retryCount++;
        
        if (_isQuotaError(e)) {
          _isQuotaExceeded = true;
          _quotaExceededAt = DateTime.now();
          _consecutiveFailures++;
          
          debugPrint('❌ Firestore quota hatası: $operation (Deneme: $retryCount/$maxRetries)');
          
          if (_consecutiveFailures >= _maxConsecutiveFailures) {
            debugPrint('⚠️ Ardışık $maxRetries başarısız deneme, fallback değer dönülüyor');
            return fallbackValue;
          }
          
          // Retry yap
          if (retryCount <= maxRetries) {
            await Future.delayed(retryDelay * retryCount); // Exponential backoff
            continue;
          }
        } else {
          // Quota hatası değil, direkt fırlat
          debugPrint('❌ Firestore hatası (quota değil): $e');
          rethrow;
        }
      }
    }
    
    // Tüm denemeler başarısız
    debugPrint('⚠️ Tüm denemeler başarısız, fallback değer dönülüyor: $operation');
    return fallbackValue;
  }
  
  /// Güvenli get işlemi
  Future<DocumentSnapshot?> safeGet({
    required String collection,
    required String documentId,
    bool useCache = true,
    DocumentSnapshot? fallbackValue,
  }) async {
    return await safeFirestoreOperation<DocumentSnapshot>(
      operation: 'get_$collection/$documentId',
      cacheKey: useCache ? 'get_$collection/$documentId' : null,
      useCache: useCache,
      fallbackValue: fallbackValue,
      operationFn: () => _firestore.collection(collection).doc(documentId).get(),
    );
  }
  
  /// Güvenli set işlemi
  Future<bool> safeSet({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    final result = await safeFirestoreOperation<bool>(
      operation: 'set_$collection/$documentId',
      fallbackValue: false,
      operationFn: () async {
        if (merge) {
          await _firestore.collection(collection).doc(documentId).set(data, SetOptions(merge: true));
        } else {
          await _firestore.collection(collection).doc(documentId).set(data);
        }
        return true;
      },
    );
    
    // Başarılıysa cache'i temizle
    if (result == true) {
      _cache.remove('get_$collection/$documentId');
    }
    
    return result ?? false;
  }
  
  /// Güvenli update işlemi
  Future<bool> safeUpdate({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    final result = await safeFirestoreOperation<bool>(
      operation: 'update_$collection/$documentId',
      fallbackValue: false,
      operationFn: () async {
        await _firestore.collection(collection).doc(documentId).update(data);
        return true;
      },
    );
    
    // Başarılıysa cache'i temizle
    if (result == true) {
      _cache.remove('get_$collection/$documentId');
    }
    
    return result ?? false;
  }
  
  /// Güvenli query işlemi
  Future<QuerySnapshot?> safeQuery({
    required String collection,
    Query Function(Query query)? queryBuilder,
    bool useCache = true,
    QuerySnapshot? fallbackValue,
    int? limit,
  }) async {
    final queryKey = 'query_$collection${limit != null ? '_limit$limit' : ''}';
    
    return await safeFirestoreOperation<QuerySnapshot>(
      operation: queryKey,
      cacheKey: useCache ? queryKey : null,
      useCache: useCache,
      fallbackValue: fallbackValue,
      operationFn: () {
        Query query = _firestore.collection(collection);
        if (queryBuilder != null) {
          query = queryBuilder(query);
        }
        if (limit != null) {
          query = query.limit(limit);
        }
        return query.get();
      },
    );
  }
  
  /// Güvenli add işlemi
  Future<String?> safeAdd({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    final result = await safeFirestoreOperation<DocumentReference>(
      operation: 'add_$collection',
      fallbackValue: null,
      operationFn: () => _firestore.collection(collection).add(data),
    );
    
    return result?.id;
  }
  
  /// Güvenli delete işlemi
  Future<bool> safeDelete({
    required String collection,
    required String documentId,
  }) async {
    final result = await safeFirestoreOperation<bool>(
      operation: 'delete_$collection/$documentId',
      fallbackValue: false,
      operationFn: () async {
        await _firestore.collection(collection).doc(documentId).delete();
        return true;
      },
    );
    
    // Başarılıysa cache'i temizle
    if (result == true) {
      _cache.remove('get_$collection/$documentId');
    }
    
    return result ?? false;
  }
  
  /// Cache'i temizle
  void clearCache() {
    _cache.clear();
    debugPrint('✅ Firestore cache temizlendi');
  }
  
  /// Quota durumunu sıfırla (manuel)
  void resetQuotaStatus() {
    _isQuotaExceeded = false;
    _quotaExceededAt = null;
    _consecutiveFailures = 0;
    debugPrint('✅ Quota durumu manuel olarak sıfırlandı');
  }
  
  /// İstatistikleri al
  Map<String, dynamic> getStats() {
    return {
      'isQuotaExceeded': _isQuotaExceeded,
      'quotaExceededAt': _quotaExceededAt?.toIso8601String(),
      'consecutiveFailures': _consecutiveFailures,
      'cacheSize': _cache.length,
      'activeRateLimits': _requestCount.length,
    };
  }
}

/// Cache entry
class CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  
  CacheEntry({
    required this.data,
    required this.timestamp,
  });
}

