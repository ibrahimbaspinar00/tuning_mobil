import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kullanıcı davranışını takip et
  Future<void> trackUserBehavior({
    required String userId,
    required String action,
    required String category,
    Map<String, dynamic>? properties,
  }) async {
    try {
      await _firestore.collection('analytics_events').add({
        'userId': userId,
        'action': action,
        'category': category,
        'properties': properties ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'sessionId': _generateSessionId(),
      });
    } catch (e) {
      debugPrint('Track user behavior error: $e');
    }
  }

  /// Sayfa görüntüleme takibi
  Future<void> trackPageView({
    required String userId,
    required String pageName,
    Map<String, dynamic>? properties,
  }) async {
    await trackUserBehavior(
      userId: userId,
      action: 'page_view',
      category: 'navigation',
      properties: {
        'pageName': pageName,
        ...?properties,
      },
    );
  }

  /// Ürün görüntüleme takibi
  Future<void> trackProductView({
    required String userId,
    required String productId,
    required String productName,
    required String category,
    required double price,
  }) async {
    await trackUserBehavior(
      userId: userId,
      action: 'product_view',
      category: 'ecommerce',
      properties: {
        'productId': productId,
        'productName': productName,
        'productCategory': category,
        'productPrice': price,
      },
    );
  }

  /// Sepete ekleme takibi
  Future<void> trackAddToCart({
    required String userId,
    required String productId,
    required String productName,
    required double price,
    required int quantity,
  }) async {
    await trackUserBehavior(
      userId: userId,
      action: 'add_to_cart',
      category: 'ecommerce',
      properties: {
        'productId': productId,
        'productName': productName,
        'price': price,
        'quantity': quantity,
        'totalValue': price * quantity,
      },
    );
  }

  /// Satın alma takibi
  Future<void> trackPurchase({
    required String userId,
    required String orderId,
    required List<Map<String, dynamic>> products,
    required double totalValue,
    required String paymentMethod,
  }) async {
    await trackUserBehavior(
      userId: userId,
      action: 'purchase',
      category: 'ecommerce',
      properties: {
        'orderId': orderId,
        'products': products,
        'totalValue': totalValue,
        'paymentMethod': paymentMethod,
        'productCount': products.length,
      },
    );
  }

  /// Arama takibi
  Future<void> trackSearch({
    required String userId,
    required String query,
    required int resultCount,
    String? category,
  }) async {
    await trackUserBehavior(
      userId: userId,
      action: 'search',
      category: 'engagement',
      properties: {
        'query': query,
        'resultCount': resultCount,
        'category': category,
      },
    );
  }

  /// Filtreleme takibi
  Future<void> trackFilter({
    required String userId,
    required Map<String, dynamic> filters,
    required int resultCount,
  }) async {
    await trackUserBehavior(
      userId: userId,
      action: 'filter',
      category: 'engagement',
      properties: {
        'filters': filters,
        'resultCount': resultCount,
      },
    );
  }

  /// Kullanıcı segmentasyonu
  Future<Map<String, dynamic>> getUserSegment(String userId) async {
    try {
      final userEvents = await _firestore
          .collection('analytics_events')
          .where('userId', isEqualTo: userId)
          .get();

      final events = userEvents.docs.map((doc) => doc.data()).toList();
      
      // Kullanıcı segmentini hesapla
      final segment = _calculateUserSegment(events);
      
      return segment;
    } catch (e) {
      debugPrint('Get user segment error: $e');
      return {'segment': 'unknown', 'confidence': 0.0};
    }
  }

  /// Kullanıcı segmentini hesapla
  Map<String, dynamic> _calculateUserSegment(List<Map<String, dynamic>> events) {
    // Basit segmentasyon algoritması
    final purchaseEvents = events.where((e) => e['action'] == 'purchase').length;
    final viewEvents = events.where((e) => e['action'] == 'product_view').length;
    final searchEvents = events.where((e) => e['action'] == 'search').length;
    
    if (purchaseEvents > 5) {
      return {'segment': 'high_value', 'confidence': 0.9};
    } else if (purchaseEvents > 2) {
      return {'segment': 'medium_value', 'confidence': 0.7};
    } else if (viewEvents > 10) {
      return {'segment': 'browser', 'confidence': 0.6};
    } else if (searchEvents > 5) {
      return {'segment': 'explorer', 'confidence': 0.5};
    } else {
      return {'segment': 'new_user', 'confidence': 0.8};
    }
  }

  /// Ürün performans analizi
  Future<Map<String, dynamic>> getProductAnalytics(String productId) async {
    try {
      final viewEvents = await _firestore
          .collection('analytics_events')
          .where('action', isEqualTo: 'product_view')
          .where('properties.productId', isEqualTo: productId)
          .get();

      final cartEvents = await _firestore
          .collection('analytics_events')
          .where('action', isEqualTo: 'add_to_cart')
          .where('properties.productId', isEqualTo: productId)
          .get();

      final purchaseEvents = await _firestore
          .collection('analytics_events')
          .where('action', isEqualTo: 'purchase')
          .where('properties.products', arrayContains: {'productId': productId})
          .get();

      final views = viewEvents.docs.length;
      final cartAdds = cartEvents.docs.length;
      final purchases = purchaseEvents.docs.length;

      return {
        'views': views,
        'cartAdds': cartAdds,
        'purchases': purchases,
        'conversionRate': views > 0 ? (purchases / views) : 0.0,
        'cartConversionRate': views > 0 ? (cartAdds / views) : 0.0,
        'purchaseConversionRate': cartAdds > 0 ? (purchases / cartAdds) : 0.0,
      };
    } catch (e) {
      debugPrint('Get product analytics error: $e');
      return {};
    }
  }

  /// Genel analitik veriler
  Future<Map<String, dynamic>> getGeneralAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final query = _firestore
          .collection('analytics_events')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(start))
          .where('timestamp', isLessThan: Timestamp.fromDate(end));

      final events = await query.get();
      final eventData = events.docs.map((doc) => doc.data()).toList();

      return {
        'totalEvents': eventData.length,
        'uniqueUsers': eventData.map((e) => e['userId']).toSet().length,
        'pageViews': eventData.where((e) => e['action'] == 'page_view').length,
        'productViews': eventData.where((e) => e['action'] == 'product_view').length,
        'cartAdds': eventData.where((e) => e['action'] == 'add_to_cart').length,
        'purchases': eventData.where((e) => e['action'] == 'purchase').length,
        'searches': eventData.where((e) => e['action'] == 'search').length,
        'filters': eventData.where((e) => e['action'] == 'filter').length,
      };
    } catch (e) {
      debugPrint('Get general analytics error: $e');
      return {};
    }
  }

  /// Trend analizi
  Future<List<Map<String, dynamic>>> getTrendAnalysis({
    required String metric,
    required int days,
  }) async {
    try {
      final trends = <Map<String, dynamic>>[];
      final now = DateTime.now();

      for (int i = days - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final query = _firestore
            .collection('analytics_events')
            .where('action', isEqualTo: metric)
            .where('timestamp', isGreaterThan: Timestamp.fromDate(startOfDay))
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay));

        final events = await query.get();
        
        trends.add({
          'date': startOfDay.toIso8601String().split('T')[0],
          'count': events.docs.length,
        });
      }

      return trends;
    } catch (e) {
      debugPrint('Get trend analysis error: $e');
      return [];
    }
  }

  /// Kullanıcı davranış analizi
  Future<Map<String, dynamic>> getUserBehaviorAnalysis(String userId) async {
    try {
      final userEvents = await _firestore
          .collection('analytics_events')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final events = userEvents.docs.map((doc) => doc.data()).toList();
      
      // Aktivite analizi
      final activityHours = <int, int>{};
      final activityDays = <String, int>{};
      final actionCounts = <String, int>{};
      
      for (final event in events) {
        final timestamp = (event['timestamp'] as Timestamp).toDate();
        final hour = timestamp.hour;
        final day = timestamp.toIso8601String().split('T')[0];
        final action = event['action'] as String;
        
        activityHours[hour] = (activityHours[hour] ?? 0) + 1;
        activityDays[day] = (activityDays[day] ?? 0) + 1;
        actionCounts[action] = (actionCounts[action] ?? 0) + 1;
      }

      return {
        'totalEvents': events.length,
        'activityHours': activityHours,
        'activityDays': activityDays,
        'actionCounts': actionCounts,
        'mostActiveHour': activityHours.entries.isNotEmpty 
            ? activityHours.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
        'mostActiveDay': activityDays.entries.isNotEmpty
            ? activityDays.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
        'mostCommonAction': actionCounts.entries.isNotEmpty
            ? actionCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
      };
    } catch (e) {
      debugPrint('Get user behavior analysis error: $e');
      return {};
    }
  }

  /// A/B test sonuçları
  Future<Map<String, dynamic>> getABTestResults(String testId) async {
    try {
      final testEvents = await _firestore
          .collection('analytics_events')
          .where('properties.testId', isEqualTo: testId)
          .get();

      final events = testEvents.docs.map((doc) => doc.data()).toList();
      
      final variants = <String, List<Map<String, dynamic>>>{};
      
      for (final event in events) {
        final variant = event['properties']['variant'] as String?;
        if (variant != null) {
          variants[variant] = variants[variant] ?? [];
          variants[variant]!.add(event);
        }
      }

      final results = <String, Map<String, dynamic>>{};
      
      for (final entry in variants.entries) {
        final variant = entry.key;
        final variantEvents = entry.value;
        
        results[variant] = {
          'totalEvents': variantEvents.length,
          'uniqueUsers': variantEvents.map((e) => e['userId']).toSet().length,
          'conversionRate': _calculateConversionRate(variantEvents),
        };
      }

      return results;
    } catch (e) {
      debugPrint('Get A/B test results error: $e');
      return {};
    }
  }

  /// Dönüşüm oranını hesapla
  double _calculateConversionRate(List<Map<String, dynamic>> events) {
    final purchaseEvents = events.where((e) => e['action'] == 'purchase').length;
    final totalEvents = events.length;
    
    return totalEvents > 0 ? purchaseEvents / totalEvents : 0.0;
  }

  /// Session ID oluştur
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Verileri temizle
  Future<void> clearAnalyticsData() async {
    try {
      // Bu gerçek uygulamada dikkatli kullanılmalı
      await _firestore.collection('analytics_events').get().then((snapshot) {
        for (final doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
    } catch (e) {
      debugPrint('Clear analytics data error: $e');
    }
  }
}
