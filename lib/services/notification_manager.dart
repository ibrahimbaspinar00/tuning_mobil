import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/notification.dart';
import 'enhanced_notification_service.dart';

/// Bildirim yöneticisi - Farklı kategorilerdeki bildirimleri yönetir
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final EnhancedNotificationService _notificationService = EnhancedNotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Bildirim yöneticisini başlat
  Future<void> initialize() async {
    await _notificationService.initialize();
  }

  // ==================== KAMPANYA VE İNDİRİM BİLDİRİMLERİ ====================

  /// Kampanya bildirimi gönder
  Future<void> sendCampaignNotification({
    required String title,
    required String description,
    required double discountPercentage,
    String? productId,
    String? categoryId,
    DateTime? validUntil,
    String? imageUrl,
    List<String>? targetUserIds,
  }) async {
    await _notificationService.sendCampaignNotification(
      title: title,
      description: description,
      discountPercentage: discountPercentage,
      productId: productId,
      categoryId: categoryId,
      validUntil: validUntil,
      imageUrl: imageUrl,
    );

    // Kampanya verilerini Firestore'a kaydet
    await _saveCampaignData({
      'title': title,
      'description': description,
      'discount_percentage': discountPercentage,
      'product_id': productId,
      'category_id': categoryId,
      'valid_until': validUntil,
      'image_url': imageUrl,
      'target_user_ids': targetUserIds,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Flash sale bildirimi gönder
  Future<void> sendFlashSaleNotification({
    required String productName,
    required double originalPrice,
    required double salePrice,
    required int timeLeftMinutes,
    String? productId,
  }) async {
    await _notificationService.sendFlashSaleNotification(
      productName: productName,
      originalPrice: originalPrice,
      salePrice: salePrice,
      timeLeftMinutes: timeLeftMinutes,
    );

    // Flash sale verilerini kaydet
    await _saveFlashSaleData({
      'product_name': productName,
      'product_id': productId,
      'original_price': originalPrice,
      'sale_price': salePrice,
      'time_left_minutes': timeLeftMinutes,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Yeni ürün bildirimi gönder
  Future<void> sendNewProductNotification({
    required String productName,
    required String category,
    String? imageUrl,
    String? productId,
  }) async {
    await _notificationService.sendNewProductNotification(
      productName: productName,
      category: category,
      imageUrl: imageUrl,
    );

    // Yeni ürün verilerini kaydet
    await _saveNewProductData({
      'product_name': productName,
      'product_id': productId,
      'category': category,
      'image_url': imageUrl,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Stok uyarı bildirimi gönder
  Future<void> sendStockAlertNotification({
    required String productName,
    required int remainingStock,
    String? productId,
  }) async {
    final title = '⚠️ Stok Uyarısı!';
    final body = '$productName ürününden sadece $remainingStock adet kaldı! Hemen sipariş verin.';
    
    await _notificationService.sendNotification(
      title: title,
      body: body,
      type: 'promotion',
      channelId: 'promotion_notifications',
      data: {
        'action': 'view_product',
        'product_name': productName,
        'product_id': productId,
        'remaining_stock': remainingStock,
      },
    );
  }

  // ==================== SİPARİŞ BİLDİRİMLERİ ====================

  /// Sipariş onay bildirimi gönder
  Future<void> sendOrderConfirmationNotification({
    required String orderId,
    required double totalAmount,
    required int itemCount,
    required String estimatedDelivery,
    required String userId,
  }) async {
    await _notificationService.sendOrderConfirmationNotification(
      orderId: orderId,
      totalAmount: totalAmount,
      itemCount: itemCount,
      estimatedDelivery: estimatedDelivery,
    );

    // Sipariş onay verilerini kaydet
    await _saveOrderConfirmationData({
      'order_id': orderId,
      'user_id': userId,
      'total_amount': totalAmount,
      'item_count': itemCount,
      'estimated_delivery': estimatedDelivery,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Sipariş hazırlık bildirimi gönder
  Future<void> sendOrderPreparationNotification({
    required String orderId,
    required String status,
    required String userId,
  }) async {
    await _notificationService.sendOrderPreparationNotification(
      orderId: orderId,
      status: status,
    );

    // Sipariş hazırlık verilerini kaydet
    await _saveOrderPreparationData({
      'order_id': orderId,
      'user_id': userId,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Sipariş iptal bildirimi gönder
  Future<void> sendOrderCancellationNotification({
    required String orderId,
    required String reason,
    required String userId,
  }) async {
    final title = '❌ Siparişiniz İptal Edildi';
    final body = 'Sipariş #$orderId iptal edildi. Sebep: $reason';
    
    await _notificationService.sendNotification(
      title: title,
      body: body,
      type: 'order',
      channelId: 'order_notifications',
      userId: userId,
      data: {
        'action': 'view_order',
        'order_id': orderId,
        'reason': reason,
      },
    );
  }

  // ==================== KARGO BİLDİRİMLERİ ====================

  /// Kargo gönderim bildirimi gönder
  Future<void> sendShippingNotification({
    required String orderId,
    required String trackingNumber,
    required String courierCompany,
    required String userId,
  }) async {
    await _notificationService.sendShippingNotification(
      orderId: orderId,
      trackingNumber: trackingNumber,
      courierCompany: courierCompany,
    );

    // Kargo gönderim verilerini kaydet
    await _saveShippingData({
      'order_id': orderId,
      'user_id': userId,
      'tracking_number': trackingNumber,
      'courier_company': courierCompany,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Teslimat bildirimi gönder
  Future<void> sendDeliveryNotification({
    required String orderId,
    required String deliveryDate,
    required String userId,
  }) async {
    await _notificationService.sendDeliveryNotification(
      orderId: orderId,
      deliveryDate: deliveryDate,
    );

    // Teslimat verilerini kaydet
    await _saveDeliveryData({
      'order_id': orderId,
      'user_id': userId,
      'delivery_date': deliveryDate,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Kargo durumu güncelleme bildirimi gönder
  Future<void> sendShippingStatusUpdateNotification({
    required String orderId,
    required String status,
    required String location,
    required String userId,
  }) async {
    final title = '📦 Kargo Durumu Güncellendi';
    final body = 'Sipariş #$orderId: $status - $location';
    
    await _notificationService.sendNotification(
      title: title,
      body: body,
      type: 'shipping',
      channelId: 'shipping_notifications',
      userId: userId,
      data: {
        'action': 'track_shipment',
        'order_id': orderId,
        'status': status,
        'location': location,
      },
    );
  }

  // ==================== ÖDEME BİLDİRİMLERİ ====================

  /// Ödeme onay bildirimi gönder
  Future<void> sendPaymentConfirmationNotification({
    required String orderId,
    required double amount,
    required String paymentMethod,
    required String userId,
  }) async {
    await _notificationService.sendPaymentConfirmationNotification(
      orderId: orderId,
      amount: amount,
      paymentMethod: paymentMethod,
    );

    // Ödeme onay verilerini kaydet
    await _savePaymentConfirmationData({
      'order_id': orderId,
      'user_id': userId,
      'amount': amount,
      'payment_method': paymentMethod,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// İade bildirimi gönder
  Future<void> sendRefundNotification({
    required String orderId,
    required double refundAmount,
    required String reason,
    required String userId,
  }) async {
    await _notificationService.sendRefundNotification(
      orderId: orderId,
      refundAmount: refundAmount,
      reason: reason,
    );

    // İade verilerini kaydet
    await _saveRefundData({
      'order_id': orderId,
      'user_id': userId,
      'refund_amount': refundAmount,
      'reason': reason,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ==================== SİSTEM BİLDİRİMLERİ ====================

  /// Sistem bakım bildirimi gönder
  Future<void> sendMaintenanceNotification({
    required String title,
    required String description,
    required DateTime maintenanceStart,
    required DateTime maintenanceEnd,
  }) async {
    final body = 'Sistem bakımı: $maintenanceStart - $maintenanceEnd. $description';
    
    await _notificationService.sendNotification(
      title: title,
      body: body,
      type: 'system',
      channelId: 'system_notifications',
      data: {
        'action': 'view_maintenance',
        'maintenance_start': maintenanceStart.toIso8601String(),
        'maintenance_end': maintenanceEnd.toIso8601String(),
      },
    );
  }

  /// Uygulama güncelleme bildirimi gönder
  Future<void> sendAppUpdateNotification({
    required String version,
    required String description,
    required String downloadUrl,
  }) async {
    final title = '🔄 Uygulama Güncellendi!';
    final body = 'Yeni sürüm v$version kullanıma hazır! $description';
    
    await _notificationService.sendNotification(
      title: title,
      body: body,
      type: 'system',
      channelId: 'system_notifications',
      data: {
        'action': 'download_update',
        'version': version,
        'download_url': downloadUrl,
      },
    );
  }

  // ==================== VERİ KAYDETME METODLARI ====================

  Future<void> _saveCampaignData(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('campaigns').add(data);
    } catch (e) {
      print('❌ Kampanya verisi kaydedilemedi: $e');
    }
  }

  Future<void> _saveFlashSaleData(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('flash_sales').add(data);
    } catch (e) {
      print('❌ Flash sale verisi kaydedilemedi: $e');
    }
  }

  Future<void> _saveNewProductData(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('new_products').add(data);
    } catch (e) {
      print('❌ Yeni ürün verisi kaydedilemedi: $e');
    }
  }

  Future<void> _saveOrderConfirmationData(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('order_confirmations').add(data);
    } catch (e) {
      print('❌ Sipariş onay verisi kaydedilemedi: $e');
    }
  }

  Future<void> _saveOrderPreparationData(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('order_preparations').add(data);
    } catch (e) {
      print('❌ Sipariş hazırlık verisi kaydedilemedi: $e');
    }
  }

  Future<void> _saveShippingData(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('shipping_updates').add(data);
    } catch (e) {
      print('❌ Kargo verisi kaydedilemedi: $e');
    }
  }

  Future<void> _saveDeliveryData(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('delivery_updates').add(data);
    } catch (e) {
      print('❌ Teslimat verisi kaydedilemedi: $e');
    }
  }

  Future<void> _savePaymentConfirmationData(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('payment_confirmations').add(data);
    } catch (e) {
      print('❌ Ödeme onay verisi kaydedilemedi: $e');
    }
  }

  Future<void> _saveRefundData(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('refunds').add(data);
    } catch (e) {
      print('❌ İade verisi kaydedilemedi: $e');
    }
  }

  // ==================== BİLDİRİM YÖNETİMİ ====================

  /// Kullanıcının bildirimlerini getir
  Stream<List<AppNotification>> getUserNotifications() {
    return _notificationService.getUserNotifications();
  }

  /// Bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    await _notificationService.markAsRead(notificationId);
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead() async {
    await _notificationService.markAllAsRead();
  }

  /// Bildirim ayarlarını getir
  Future<Map<String, bool>> getNotificationSettings() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        return Map<String, bool>.from(doc.data() ?? {});
      }
    } catch (e) {
      print('❌ Bildirim ayarları alınamadı: $e');
    }

    // Varsayılan ayarlar
    return {
      'promotions': true,
      'orders': true,
      'shipping': true,
      'payments': true,
      'system': true,
    };
  }

  /// Bildirim ayarlarını güncelle
  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .set(settings);
    } catch (e) {
      print('❌ Bildirim ayarları güncellenemedi: $e');
    }
  }
}
