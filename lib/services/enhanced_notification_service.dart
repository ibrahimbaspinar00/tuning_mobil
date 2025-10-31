import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/notification.dart';

/// Gelişmiş bildirim servisi - Kampanya, indirim, sipariş, kargo bildirimleri
class EnhancedNotificationService {
  static final EnhancedNotificationService _instance = EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;
  bool _isInitialized = false;

  /// Servisi başlat
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _requestPermissions();
      await _getFCMToken();
      await _setupLocalNotifications();
      await _createNotificationChannels();
      
      // Message handlers
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      _isInitialized = true;
      print('✅ EnhancedNotificationService başlatıldı');
    } catch (e) {
      print('❌ EnhancedNotificationService başlatılamadı: $e');
    }
  }

  /// İzinleri iste
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status != PermissionStatus.granted) {
        print('❌ Bildirim izni verilmedi');
      }
    } else if (Platform.isIOS) {
      final status = await Permission.notification.request();
      if (status != PermissionStatus.granted) {
        print('❌ Bildirim izni verilmedi');
      }
    }
  }

  /// FCM token al
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      print('📱 FCM Token: $_fcmToken');
      
      if (_auth.currentUser != null && _fcmToken != null) {
        await _saveTokenToFirestore(_fcmToken!);
      }
    } catch (e) {
      print('❌ FCM Token alınamadı: $e');
    }
  }

  /// Token'ı Firestore'a kaydet
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('✅ FCM Token Firestore\'a kaydedildi');
      }
    } catch (e) {
      print('❌ FCM Token kaydedilemedi: $e');
    }
  }

  /// Local notifications ayarla
  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Notification channels oluştur
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Kampanya ve İndirim Bildirimleri
    const AndroidNotificationChannel promotionChannel = AndroidNotificationChannel(
      'promotion_notifications',
      '🎯 Kampanya & İndirim',
      description: 'Özel kampanyalar, indirimler ve promosyonlar',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Sipariş Bildirimleri
    const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
      'order_notifications',
      '📦 Sipariş Takibi',
      description: 'Sipariş onayı, hazırlık ve durum güncellemeleri',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Kargo Bildirimleri
    const AndroidNotificationChannel shippingChannel = AndroidNotificationChannel(
      'shipping_notifications',
      '🚚 Kargo Takibi',
      description: 'Kargo durumu ve teslimat bildirimleri',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Ödeme Bildirimleri
    const AndroidNotificationChannel paymentChannel = AndroidNotificationChannel(
      'payment_notifications',
      '💳 Ödeme Bildirimleri',
      description: 'Ödeme onayı ve iade bildirimleri',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Sistem Bildirimleri
    const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
      'system_notifications',
      '⚙️ Sistem Bildirimleri',
      description: 'Sistem güncellemeleri ve önemli duyurular',
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
    );

    await androidPlugin?.createNotificationChannel(promotionChannel);
    await androidPlugin?.createNotificationChannel(orderChannel);
    await androidPlugin?.createNotificationChannel(shippingChannel);
    await androidPlugin?.createNotificationChannel(paymentChannel);
    await androidPlugin?.createNotificationChannel(systemChannel);
  }

  /// Foreground message handler
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Foreground message alındı: ${message.messageId}');
    
    final notification = message.notification;
    if (notification != null) {
      await _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'Bildirim',
        body: notification.body ?? '',
        payload: message.data.toString(),
        channelId: _getChannelId(message.data),
        type: message.data['type'] ?? 'system',
      );
    }
  }

  /// Notification tap handler
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('👆 Notification tıklandı: ${message.messageId}');
    await _handleNotificationAction(message.data);
  }

  /// Local notification tap handler
  void _onNotificationTap(NotificationResponse response) {
    print('👆 Local notification tıklandı: ${response.payload}');
    // TODO: Navigation logic
  }

  /// Channel ID belirle
  String _getChannelId(Map<String, dynamic> data) {
    final type = data['type'] ?? 'system';
    switch (type) {
      case 'promotion':
        return 'promotion_notifications';
      case 'order':
        return 'order_notifications';
      case 'shipping':
        return 'shipping_notifications';
      case 'payment':
        return 'payment_notifications';
      default:
        return 'system_notifications';
    }
  }

  /// Local notification göster
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? type,
  }) async {
    final channel = channelId ?? 'system_notifications';
    
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channel,
      _getChannelName(channel),
      channelDescription: _getChannelDescription(channel),
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Channel adı al
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'promotion_notifications':
        return '🎯 Kampanya & İndirim';
      case 'order_notifications':
        return '📦 Sipariş Takibi';
      case 'shipping_notifications':
        return '🚚 Kargo Takibi';
      case 'payment_notifications':
        return '💳 Ödeme Bildirimleri';
      default:
        return '⚙️ Sistem Bildirimleri';
    }
  }

  /// Channel açıklaması al
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'promotion_notifications':
        return 'Özel kampanyalar, indirimler ve promosyonlar';
      case 'order_notifications':
        return 'Sipariş onayı, hazırlık ve durum güncellemeleri';
      case 'shipping_notifications':
        return 'Kargo durumu ve teslimat bildirimleri';
      case 'payment_notifications':
        return 'Ödeme onayı ve iade bildirimleri';
      default:
        return 'Sistem güncellemeleri ve önemli duyurular';
    }
  }

  /// Notification action handler
  Future<void> _handleNotificationAction(Map<String, dynamic> data) async {
    final action = data['action'];
    final type = data['type'];
    
    print('🎯 Notification action: $action, type: $type');
    // TODO: Navigation logic based on action and type
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
  }) async {
    final body = '🎉 %${discountPercentage.toInt()} indirim! $description';
    
    await sendNotification(
      title: title,
      body: body,
      type: 'promotion',
      channelId: 'promotion_notifications',
      data: {
        'action': 'view_campaign',
        'discount_percentage': discountPercentage,
        'product_id': productId,
        'category_id': categoryId,
        'valid_until': validUntil?.toIso8601String(),
        'image_url': imageUrl,
      },
    );
  }

  /// Flash sale bildirimi gönder
  Future<void> sendFlashSaleNotification({
    required String productName,
    required double originalPrice,
    required double salePrice,
    required int timeLeftMinutes,
  }) async {
    final discountPercentage = ((originalPrice - salePrice) / originalPrice * 100).round();
    final title = '⚡ Flash Sale!';
    final body = '$productName - %$discountPercentage indirim! Sadece $timeLeftMinutes dakika kaldı!';
    
    await sendNotification(
      title: title,
      body: body,
      type: 'promotion',
      channelId: 'promotion_notifications',
      data: {
        'action': 'view_flash_sale',
        'product_name': productName,
        'original_price': originalPrice,
        'sale_price': salePrice,
        'time_left_minutes': timeLeftMinutes,
      },
    );
  }

  /// Yeni ürün bildirimi gönder
  Future<void> sendNewProductNotification({
    required String productName,
    required String category,
    String? imageUrl,
  }) async {
    final title = '🆕 Yeni Ürün!';
    final body = '$productName $category kategorisinde! Hemen keşfet!';
    
    await sendNotification(
      title: title,
      body: body,
      type: 'promotion',
      channelId: 'promotion_notifications',
      data: {
        'action': 'view_product',
        'product_name': productName,
        'category': category,
        'image_url': imageUrl,
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
  }) async {
    final title = '✅ Siparişiniz Onaylandı!';
    final body = 'Sipariş #$orderId onaylandı. $itemCount ürün, ${totalAmount.toStringAsFixed(2)} ₺. Tahmini teslimat: $estimatedDelivery';
    
    await sendNotification(
      title: title,
      body: body,
      type: 'order',
      channelId: 'order_notifications',
      data: {
        'action': 'view_order',
        'order_id': orderId,
        'total_amount': totalAmount,
        'item_count': itemCount,
        'estimated_delivery': estimatedDelivery,
      },
    );
  }

  /// Sipariş hazırlık bildirimi gönder
  Future<void> sendOrderPreparationNotification({
    required String orderId,
    required String status,
  }) async {
    final title = '📦 Siparişiniz Hazırlanıyor';
    final body = 'Sipariş #$orderId $status aşamasında. Kısa sürede kargoya verilecek.';
    
    await sendNotification(
      title: title,
      body: body,
      type: 'order',
      channelId: 'order_notifications',
      data: {
        'action': 'view_order',
        'order_id': orderId,
        'status': status,
      },
    );
  }

  // ==================== KARGO BİLDİRİMLERİ ====================

  /// Kargo gönderim bildirimi gönder
  Future<void> sendShippingNotification({
    required String orderId,
    required String trackingNumber,
    required String courierCompany,
  }) async {
    final title = '🚚 Siparişiniz Kargoya Verildi!';
    final body = 'Sipariş #$orderId kargoya verildi. Takip no: $trackingNumber ($courierCompany)';
    
    await sendNotification(
      title: title,
      body: body,
      type: 'shipping',
      channelId: 'shipping_notifications',
      data: {
        'action': 'track_shipment',
        'order_id': orderId,
        'tracking_number': trackingNumber,
        'courier_company': courierCompany,
      },
    );
  }

  /// Teslimat bildirimi gönder
  Future<void> sendDeliveryNotification({
    required String orderId,
    required String deliveryDate,
  }) async {
    final title = '📦 Siparişiniz Teslim Edildi!';
    final body = 'Sipariş #$orderId $deliveryDate tarihinde teslim edildi. Memnuniyetinizi değerlendirin!';
    
    await sendNotification(
      title: title,
      body: body,
      type: 'shipping',
      channelId: 'shipping_notifications',
      data: {
        'action': 'rate_order',
        'order_id': orderId,
        'delivery_date': deliveryDate,
      },
    );
  }

  // ==================== ÖDEME BİLDİRİMLERİ ====================

  /// Ödeme onay bildirimi gönder
  Future<void> sendPaymentConfirmationNotification({
    required String orderId,
    required double amount,
    required String paymentMethod,
  }) async {
    final title = '💳 Ödemeniz Onaylandı!';
    final body = 'Sipariş #$orderId için ${amount.toStringAsFixed(2)} ₺ ödeme onaylandı ($paymentMethod)';
    
    await sendNotification(
      title: title,
      body: body,
      type: 'payment',
      channelId: 'payment_notifications',
      data: {
        'action': 'view_order',
        'order_id': orderId,
        'amount': amount,
        'payment_method': paymentMethod,
      },
    );
  }

  /// İade bildirimi gönder
  Future<void> sendRefundNotification({
    required String orderId,
    required double refundAmount,
    required String reason,
  }) async {
    final title = '💰 İadeniz Onaylandı!';
    final body = 'Sipariş #$orderId için ${refundAmount.toStringAsFixed(2)} ₺ iade onaylandı. Sebep: $reason';
    
    await sendNotification(
      title: title,
      body: body,
      type: 'payment',
      channelId: 'payment_notifications',
      data: {
        'action': 'view_refund',
        'order_id': orderId,
        'refund_amount': refundAmount,
        'reason': reason,
      },
    );
  }

  // ==================== GENEL BİLDİRİM METODU ====================

  /// Genel bildirim gönder
  Future<void> sendNotification({
    required String title,
    required String body,
    required String type,
    required String channelId,
    Map<String, dynamic>? data,
    String? userId,
    DateTime? scheduledAt,
  }) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      data: data,
      userId: userId,
      createdAt: DateTime.now(),
      scheduledAt: scheduledAt,
    );

    // Firestore'a kaydet - Hata olsa bile local notification gösterilmeli
    try {
      final notificationData = notification.toFirestore();
      notificationData['status'] = 'sent';
      notificationData['sentAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notificationData)
          .timeout(const Duration(seconds: 5));
      
      print('✅ Bildirim Firestore\'a kaydedildi: $title');
    } catch (e) {
      // Firestore hatası olsa bile local notification gösterilmeye devam edilmeli
      print('⚠️ Firestore hatası (bildirim local olarak gösterilecek): $e');
    }

    // Local notification göster - Her durumda gösterilmeli
    try {
      await _showLocalNotification(
        id: notification.hashCode,
        title: title,
        body: body,
        payload: data.toString(),
        channelId: channelId,
        type: type,
      );
      print('✅ Local bildirim gösterildi: $title');
    } catch (e) {
      print('❌ Local bildirim gösterilemedi: $e');
    }
  }

  /// Kullanıcının bildirimlerini getir
  Stream<List<AppNotification>> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', whereIn: [user.uid, null])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    });
  }

  /// Bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Bildirim okundu olarak işaretlenemedi: $e');
    }
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', whereIn: [user.uid, null])
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('✅ Tüm bildirimler okundu olarak işaretlendi');
    } catch (e) {
      print('❌ Bildirimler işaretlenemedi: $e');
    }
  }

  /// FCM Token al
  String? get fcmToken => _fcmToken;

  /// Servis başlatıldı mı?
  bool get isInitialized => _isInitialized;
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Background message alındı: ${message.messageId}');
  // Background'da gelen mesajları işle
}
