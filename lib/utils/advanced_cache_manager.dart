import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Gelişmiş cache yönetimi sistemi
class AdvancedCacheManager {
  static AdvancedCacheManager? _instance;
  static AdvancedCacheManager get instance => _instance ??= AdvancedCacheManager._();
  
  AdvancedCacheManager._();
  
  SharedPreferences? _prefs;
  Directory? _cacheDirectory;
  
  /// Cache'i başlat
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _cacheDirectory = await getApplicationDocumentsDirectory();
      
      // Cache dizini oluştur
      final cacheDir = Directory('${_cacheDirectory!.path}/cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      debugPrint('AdvancedCacheManager initialized');
    } catch (e) {
      debugPrint('Cache initialization error: $e');
    }
  }
  
  /// String cache
  Future<void> setString(String key, String value, {Duration? expiry}) async {
    try {
      final cacheData = CacheData(
        value: value,
        timestamp: DateTime.now(),
        expiry: expiry,
      );
      
      await _prefs?.setString('cache_$key', jsonEncode(cacheData.toMap()));
    } catch (e) {
      debugPrint('String cache error: $e');
    }
  }
  
  Future<String?> getString(String key) async {
    try {
      final cached = _prefs?.getString('cache_$key');
      if (cached == null) return null;
      
      final cacheData = CacheData.fromMap(jsonDecode(cached));
      
      // Expiry kontrolü
      if (cacheData.isExpired) {
        await removeString(key);
        return null;
      }
      
      return cacheData.value;
    } catch (e) {
      debugPrint('String cache get error: $e');
      return null;
    }
  }
  
  Future<void> removeString(String key) async {
    await _prefs?.remove('cache_$key');
  }
  
  /// JSON cache
  Future<void> setJson(String key, Map<String, dynamic> value, {Duration? expiry}) async {
    await setString(key, jsonEncode(value), expiry: expiry);
  }
  
  Future<Map<String, dynamic>?> getJson(String key) async {
    final cached = await getString(key);
    if (cached == null) return null;
    
    try {
      return jsonDecode(cached) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JSON cache parse error: $e');
      return null;
    }
  }
  
  /// List cache
  Future<void> setList(String key, List<dynamic> value, {Duration? expiry}) async {
    await setString(key, jsonEncode(value), expiry: expiry);
  }
  
  Future<List<dynamic>?> getList(String key) async {
    final cached = await getString(key);
    if (cached == null) return null;
    
    try {
      return jsonDecode(cached) as List<dynamic>;
    } catch (e) {
      debugPrint('List cache parse error: $e');
      return null;
    }
  }
  
  /// File cache
  Future<void> setFile(String key, List<int> data, {Duration? expiry}) async {
    try {
      final file = File('${_cacheDirectory!.path}/cache/$key');
      await file.writeAsBytes(data);
      
      // Metadata kaydet
      final metadata = CacheData(
        value: file.path,
        timestamp: DateTime.now(),
        expiry: expiry,
      );
      
      await _prefs?.setString('file_cache_$key', jsonEncode(metadata.toMap()));
    } catch (e) {
      debugPrint('File cache error: $e');
    }
  }
  
  Future<List<int>?> getFile(String key) async {
    try {
      final cached = _prefs?.getString('file_cache_$key');
      if (cached == null) return null;
      
      final cacheData = CacheData.fromMap(jsonDecode(cached));
      
      // Expiry kontrolü
      if (cacheData.isExpired) {
        await removeFile(key);
        return null;
      }
      
      final file = File(cacheData.value);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      
      return null;
    } catch (e) {
      debugPrint('File cache get error: $e');
      return null;
    }
  }
  
  Future<void> removeFile(String key) async {
    try {
      final cached = _prefs?.getString('file_cache_$key');
      if (cached != null) {
        final cacheData = CacheData.fromMap(jsonDecode(cached));
        final file = File(cacheData.value);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      await _prefs?.remove('file_cache_$key');
    } catch (e) {
      debugPrint('File cache remove error: $e');
    }
  }
  
  /// Cache temizleme
  Future<void> clearExpired() async {
    try {
      final keys = _prefs?.getKeys() ?? <String>{};
      final expiredKeys = <String>[];
      
      for (final key in keys) {
        if (key.startsWith('cache_') || key.startsWith('file_cache_')) {
          final cached = _prefs?.getString(key);
          if (cached != null) {
            final cacheData = CacheData.fromMap(jsonDecode(cached));
            if (cacheData.isExpired) {
              expiredKeys.add(key);
            }
          }
        }
      }
      
      for (final key in expiredKeys) {
        if (key.startsWith('file_cache_')) {
          await removeFile(key.substring(11)); // 'file_cache_' kısmını çıkar
        } else {
          await _prefs?.remove(key);
        }
      }
      
      debugPrint('Cleared ${expiredKeys.length} expired cache entries');
    } catch (e) {
      debugPrint('Cache clear error: $e');
    }
  }
  
  Future<void> clearAll() async {
    try {
      final keys = _prefs?.getKeys() ?? <String>{};
      final cacheKeys = keys.where((key) => 
        key.startsWith('cache_') || key.startsWith('file_cache_')).toList();
      
      for (final key in cacheKeys) {
        if (key.startsWith('file_cache_')) {
          await removeFile(key.substring(11));
        } else {
          await _prefs?.remove(key);
        }
      }
      
      // Cache dizinini temizle
      final cacheDir = Directory('${_cacheDirectory!.path}/cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
      }
      
      debugPrint('Cleared all cache');
    } catch (e) {
      debugPrint('Cache clear all error: $e');
    }
  }
  
  /// Cache istatistikleri
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final keys = _prefs?.getKeys() ?? <String>{};
      final cacheKeys = keys.where((key) => 
        key.startsWith('cache_') || key.startsWith('file_cache_')).toList();
      
      int expiredCount = 0;
      int totalSize = 0;
      
      for (final key in cacheKeys) {
        final cached = _prefs?.getString(key);
        if (cached != null) {
          final cacheData = CacheData.fromMap(jsonDecode(cached));
          if (cacheData.isExpired) {
            expiredCount++;
          }
          totalSize += cached.length;
        }
      }
      
      return {
        'totalEntries': cacheKeys.length,
        'expiredEntries': expiredCount,
        'totalSize': totalSize,
        'cacheDirectory': _cacheDirectory?.path,
      };
    } catch (e) {
      debugPrint('Cache statistics error: $e');
      return {};
    }
  }
}

/// Cache data modeli
class CacheData {
  final String value;
  final DateTime timestamp;
  final Duration? expiry;
  
  CacheData({
    required this.value,
    required this.timestamp,
    this.expiry,
  });
  
  bool get isExpired {
    if (expiry == null) return false;
    return DateTime.now().difference(timestamp) > expiry!;
  }
  
  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'expiry': expiry?.inMilliseconds,
    };
  }
  
  factory CacheData.fromMap(Map<String, dynamic> map) {
    return CacheData(
      value: map['value'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      expiry: map['expiry'] != null ? Duration(milliseconds: map['expiry']) : null,
    );
  }
}
