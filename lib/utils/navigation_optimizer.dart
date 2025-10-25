import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Navigation optimizer for better performance
class NavigationOptimizer {
  static final Map<String, Widget> _pageCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Navigate with caching
  static Future<T?> navigateWithCache<T extends Object?>(
    BuildContext context,
    Widget Function() pageBuilder, {
    String? cacheKey,
    bool clearCache = false,
  }) async {
    final key = cacheKey ?? pageBuilder.toString();
    
    // Clear cache if requested
    if (clearCache) {
      _pageCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    // Check if page is cached and not expired
    if (_pageCache.containsKey(key) && _cacheTimestamps.containsKey(key)) {
      final timestamp = _cacheTimestamps[key]!;
      if (DateTime.now().difference(timestamp) < _cacheExpiry) {
        if (kDebugMode) {
          debugPrint('NavigationOptimizer: Using cached page for key: $key');
        }
        return Navigator.push<T>(
          context,
          MaterialPageRoute(
            builder: (context) => _pageCache[key]!,
            settings: RouteSettings(name: key),
          ),
        );
      } else {
        // Cache expired, remove it
        _pageCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
    
    // Create new page and cache it
    final page = pageBuilder();
    _pageCache[key] = page;
    _cacheTimestamps[key] = DateTime.now();
    
    if (kDebugMode) {
      debugPrint('NavigationOptimizer: Created and cached new page for key: $key');
    }
    
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (context) => page,
        settings: RouteSettings(name: key),
      ),
    );
  }

  /// Navigate with preloading
  static Future<T?> navigateWithPreload<T extends Object?>(
    BuildContext context,
    Widget Function() pageBuilder, {
    Duration preloadDelay = const Duration(milliseconds: 100),
  }) async {
    // Preload the page in background
    Future.delayed(preloadDelay, () {
      pageBuilder();
    });
    
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (context) => pageBuilder(),
      ),
    );
  }

  /// Navigate with animation optimization
  static Future<T?> navigateWithOptimizedAnimation<T extends Object?>(
    BuildContext context,
    Widget Function() pageBuilder, {
    Duration transitionDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) async {
    return Navigator.push<T>(
      context,
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => pageBuilder(),
        transitionDuration: transitionDuration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: curve)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  /// Clear page cache
  static void clearCache({String? specificKey}) {
    if (specificKey != null) {
      _pageCache.remove(specificKey);
      _cacheTimestamps.remove(specificKey);
      if (kDebugMode) {
        debugPrint('NavigationOptimizer: Cleared cache for key: $specificKey');
      }
    } else {
      _pageCache.clear();
      _cacheTimestamps.clear();
      if (kDebugMode) {
        debugPrint('NavigationOptimizer: Cleared all page cache');
      }
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) > _cacheExpiry)
        .map((entry) => entry.key)
        .toList();
    
    return {
      'totalCachedPages': _pageCache.length,
      'expiredPages': expiredKeys.length,
      'cacheKeys': _pageCache.keys.toList(),
    };
  }

  /// Clean expired cache
  static void cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) > _cacheExpiry)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _pageCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (kDebugMode && expiredKeys.isNotEmpty) {
      debugPrint('NavigationOptimizer: Cleaned ${expiredKeys.length} expired pages');
    }
  }
}
