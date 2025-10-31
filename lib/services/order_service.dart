import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../model/order.dart' as OrderModel;
import '../model/product.dart';

/// Sipariş yönetimi için ana servis
class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı ID'sini al
  String? get _currentUserId => _auth.currentUser?.uid;

  // ==================== SİPARİŞ YÖNETİMİ ====================

  /// Sipariş oluştur
  Future<String> createOrder({
    required List<Product> products,
    required double totalAmount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String shippingAddress,
    String? paymentMethod,
    String? notes,
  }) async {
    if (_currentUserId == null) throw Exception('Kullanıcı giriş yapmamış');

    try {
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final orderData = {
        'id': orderId,
        'userId': _currentUserId,
        'products': products.map((p) => p.toMap()).toList(),
        'totalAmount': totalAmount,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod ?? 'Kredi Kartı',
        'notes': notes ?? '',
        'status': 'Beklemede',
        'orderDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('orders').doc(orderId).set(orderData);

      // Ürün stoklarını güncelle
      await _updateProductStocks(products);

      return orderId;
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }

  /// Ürün stoklarını güncelle
  Future<void> _updateProductStocks(List<Product> products) async {
    try {
      final batch = _firestore.batch();
      
      for (final product in products) {
        final productRef = _firestore.collection('products').doc(product.id);
        batch.update(productRef, {
          'stock': FieldValue.increment(-product.quantity),
          'salesCount': FieldValue.increment(product.quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error updating product stocks: $e');
    }
  }

  /// Kullanıcının siparişlerini getir
  Future<List<OrderModel.Order>> getUserOrders() async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('orderDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OrderModel.Order.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting user orders: $e');
      return [];
    }
  }

  /// Sipariş detayını getir
  Future<OrderModel.Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return OrderModel.Order.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting order: $e');
      return null;
    }
  }

  /// Sipariş durumunu güncelle
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }

  /// Siparişi iptal et
  Future<void> cancelOrder(String orderId) async {
    try {
      // Sipariş durumunu güncelle
      await updateOrderStatus(orderId, 'İptal Edildi');
      
      // Ürün stoklarını geri yükle
      final order = await getOrderById(orderId);
      if (order != null) {
        await _restoreProductStocks(order.products);
      }
    } catch (e) {
      debugPrint('Error canceling order: $e');
    }
  }

  /// Ürün stoklarını geri yükle
  Future<void> _restoreProductStocks(List<Product> products) async {
    try {
      final batch = _firestore.batch();
      
      for (final product in products) {
        final productRef = _firestore.collection('products').doc(product.id);
        batch.update(productRef, {
          'stock': FieldValue.increment(product.quantity),
          'salesCount': FieldValue.increment(-product.quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error restoring product stocks: $e');
    }
  }

  /// Sipariş takip numarası oluştur
  Future<String> generateTrackingNumber(String orderId) async {
    try {
      final trackingNumber = 'TRK${orderId.substring(orderId.length - 8)}';
      
      await _firestore.collection('orders').doc(orderId).update({
        'trackingNumber': trackingNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return trackingNumber;
    } catch (e) {
      debugPrint('Error generating tracking number: $e');
      return 'TRK${orderId.substring(orderId.length - 8)}';
    }
  }

  /// Sipariş istatistikleri
  Future<Map<String, dynamic>> getOrderStatistics() async {
    if (_currentUserId == null) return {};

    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      int totalOrders = snapshot.docs.length;
      double totalSpent = 0;
      int pendingOrders = 0;
      int completedOrders = 0;
      int cancelledOrders = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalSpent += (data['totalAmount'] ?? 0).toDouble();
        
        final status = data['status'] ?? '';
        switch (status) {
          case 'Beklemede':
            pendingOrders++;
            break;
          case 'Tamamlandı':
            completedOrders++;
            break;
          case 'İptal Edildi':
            cancelledOrders++;
            break;
        }
      }

      return {
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'averageOrderValue': totalOrders > 0 ? totalSpent / totalOrders : 0,
      };
    } catch (e) {
      debugPrint('Error getting order statistics: $e');
      return {};
    }
  }

  /// Sipariş geçmişi (son N sipariş)
  Future<List<OrderModel.Order>> getRecentOrders({int limit = 5}) async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('orderDate', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OrderModel.Order.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting recent orders: $e');
      return [];
    }
  }

  /// Sipariş durumları
  static const List<String> orderStatuses = [
    'Beklemede',
    'Onaylandı',
    'Hazırlanıyor',
    'Kargoya Verildi',
    'Teslim Edildi',
    'Tamamlandı',
    'İptal Edildi',
  ];

  /// Sipariş durumu renkleri
  static Color getStatusColor(String status) {
    switch (status) {
      case 'Beklemede':
        return Colors.orange;
      case 'Onaylandı':
        return Colors.blue;
      case 'Hazırlanıyor':
        return Colors.purple;
      case 'Kargoya Verildi':
        return Colors.indigo;
      case 'Teslim Edildi':
        return Colors.green;
      case 'Tamamlandı':
        return Colors.green.shade700;
      case 'İptal Edildi':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Sipariş durumu ikonları
  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'Beklemede':
        return Icons.hourglass_empty;
      case 'Onaylandı':
        return Icons.check_circle_outline;
      case 'Hazırlanıyor':
        return Icons.build;
      case 'Kargoya Verildi':
        return Icons.local_shipping;
      case 'Teslim Edildi':
        return Icons.home;
      case 'Tamamlandı':
        return Icons.check_circle;
      case 'İptal Edildi':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // ==================== ADMIN FONKSİYONLARI ====================

  /// Tüm siparişleri getir (Admin)
  Future<List<OrderModel.Order>> getAllOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OrderModel.Order.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting all orders: $e');
      return [];
    }
  }

  /// Sipariş durumuna göre filtrele (Admin)
  Future<List<OrderModel.Order>> getOrdersByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: status)
          .orderBy('orderDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OrderModel.Order.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting orders by status: $e');
      return [];
    }
  }

  /// Günlük sipariş istatistikleri (Admin)
  Future<Map<String, dynamic>> getDailyOrderStats(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      int totalOrders = snapshot.docs.length;
      double totalRevenue = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalRevenue += (data['totalAmount'] ?? 0).toDouble();
      }

      return {
        'date': date.toIso8601String().split('T')[0],
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
      };
    } catch (e) {
      debugPrint('Error getting daily order stats: $e');
      return {};
    }
  }
}
