import 'dart:async';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _defaultExpiry = Duration(hours: 1);

  // Cache'e veri ekle
  void set(String key, dynamic value, {Duration? expiry}) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
    
    // Expiry süresi sonunda otomatik temizleme
    if (expiry != null) {
      Timer(expiry, () {
        if (_cacheTimestamps.containsKey(key)) {
          _cache.remove(key);
          _cacheTimestamps.remove(key);
        }
      });
    }
  }

  // Cache'den veri al
  T? get<T>(String key) {
    if (!_cache.containsKey(key)) return null;
    
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null && DateTime.now().difference(timestamp) > _defaultExpiry) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }
    
    return _cache[key] as T?;
  }

  // Cache'de var mı kontrol et
  bool contains(String key) {
    if (!_cache.containsKey(key)) return false;
    
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null && DateTime.now().difference(timestamp) > _defaultExpiry) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return false;
    }
    
    return true;
  }

  // Cache'i temizle
  void clear() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // Belirli bir key'i temizle
  void remove(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  // Cache boyutunu al
  int get size => _cache.length;

  // Eski cache'leri temizle
  void cleanExpired() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _defaultExpiry) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // Cache istatistikleri
  Map<String, dynamic> getStats() {
    return {
      'size': _cache.length,
      'keys': _cache.keys.toList(),
      'oldest': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'newest': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }
}
