import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class SmartNotificationService {
  static final SmartNotificationService _instance = SmartNotificationService._internal();
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  bool _isInitialized = false;
  String? _fcmToken;

  /// Bildirim servisini başlat
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Local notifications setup
      await _setupLocalNotifications();
      
      // Firebase messaging setup
      await _setupFirebaseMessaging();
      
      // FCM token al
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
      
      _isInitialized = true;
      debugPrint('SmartNotificationService initialized');
    } catch (e) {
      debugPrint('SmartNotificationService initialization error: $e');
    }
  }

  /// Local notifications kurulumu
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Firebase messaging kurulumu
  Future<void> _setupFirebaseMessaging() async {
    // İzin iste
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Notification tap handler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Foreground mesaj işleyici
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    
    // Local notification göster
    _showLocalNotification(
      title: message.notification?.title ?? 'Yeni Bildirim',
      body: message.notification?.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  /// Notification tap işleyici
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    _handleNotificationAction(message.data);
  }

  /// Local notification tap işleyici
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _handleNotificationAction(data);
    }
  }

  /// Notification action işleyici
  void _handleNotificationAction(Map<String, dynamic> data) {
    final action = data['action'];
    final productId = data['product_id'];
    final orderId = data['order_id'];
    final couponCode = data['coupon_code'];
    
    switch (action) {
      case 'view_product':
        if (productId != null) {
          // Ürün detay sayfasına git
          debugPrint('Navigate to product: $productId');
        }
        break;
      case 'view_order':
        if (orderId != null) {
          // Sipariş detay sayfasına git
          debugPrint('Navigate to order: $orderId');
        }
        break;
      case 'use_coupon':
        if (couponCode != null) {
          // Kupon kullan
          debugPrint('Use coupon: $couponCode');
        }
        break;
      default:
        debugPrint('Unknown notification action: $action');
    }
  }

  /// Local notification göster
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tuning_store_channel',
      'Tuning Store Notifications',
      channelDescription: 'Tuning Store bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Akıllı bildirim gönder
  Future<void> sendSmartNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String? userId,
  }) async {
    try {
      // Kullanıcı tercihlerini kontrol et
      if (userId != null && !_shouldSendNotification(userId, type)) {
        return;
      }
      
      // Bildirim zamanlaması
      final scheduledTime = _getOptimalNotificationTime(userId);
      if (scheduledTime != null) {
        await _scheduleNotification(
          title: title,
          body: body,
          scheduledTime: scheduledTime,
          data: data,
        );
      } else {
        await _showLocalNotification(
          title: title,
          body: body,
          payload: data != null ? jsonEncode(data) : null,
        );
      }
    } catch (e) {
      debugPrint('Send notification error: $e');
    }
  }

  /// Bildirim gönderilmeli mi kontrol et
  bool _shouldSendNotification(String userId, String type) {
    // Bu gerçek uygulamada kullanıcı tercihleri veritabanından gelecek
    return true;
  }

  /// Optimal bildirim zamanı
  DateTime? _getOptimalNotificationTime(String? userId) {
    // Bu gerçek uygulamada kullanıcı aktivite verilerine göre hesaplanacak
    return null; // Şimdi gönder
  }

  /// Zamanlanmış bildirim
  Future<void> _scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tuning_store_scheduled',
      'Scheduled Notifications',
      channelDescription: 'Zamanlanmış bildirimler',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      scheduledTime.millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Ürün bildirimi gönder
  Future<void> sendProductNotification({
    required String productName,
    required String productId,
    required String type, // 'price_drop', 'back_in_stock', 'new_arrival'
  }) async {
    String title;
    String body;
    Map<String, dynamic> data;
    
    switch (type) {
      case 'price_drop':
        title = '💰 Fiyat Düştü!';
        body = '$productName ürününde indirim! Hemen kontrol et.';
        data = {
          'action': 'view_product',
          'product_id': productId,
          'type': 'price_drop',
        };
        break;
      case 'back_in_stock':
        title = '📦 Stokta!';
        body = '$productName ürünü tekrar stokta!';
        data = {
          'action': 'view_product',
          'product_id': productId,
          'type': 'back_in_stock',
        };
        break;
      case 'new_arrival':
        title = '🆕 Yeni Ürün!';
        body = '$productName yeni ürün eklendi!';
        data = {
          'action': 'view_product',
          'product_id': productId,
          'type': 'new_arrival',
        };
        break;
      default:
        return;
    }
    
    await sendSmartNotification(
      title: title,
      body: body,
      type: 'product',
      data: data,
    );
  }

  /// Sipariş bildirimi gönder
  Future<void> sendOrderNotification({
    required String orderId,
    required String status,
    required String message,
  }) async {
    String title;
    Map<String, dynamic> data;
    
    switch (status) {
      case 'confirmed':
        title = '✅ Sipariş Onaylandı';
        data = {
          'action': 'view_order',
          'order_id': orderId,
          'type': 'order_confirmed',
        };
        break;
      case 'shipped':
        title = '🚚 Sipariş Kargoya Verildi';
        data = {
          'action': 'view_order',
          'order_id': orderId,
          'type': 'order_shipped',
        };
        break;
      case 'delivered':
        title = '📦 Sipariş Teslim Edildi';
        data = {
          'action': 'view_order',
          'order_id': orderId,
          'type': 'order_delivered',
        };
        break;
      default:
        title = '📋 Sipariş Güncellemesi';
        data = {
          'action': 'view_order',
          'order_id': orderId,
          'type': 'order_update',
        };
    }
    
    await sendSmartNotification(
      title: title,
      body: message,
      type: 'order',
      data: data,
    );
  }

  /// Kupon bildirimi gönder
  Future<void> sendCouponNotification({
    required String couponCode,
    required String discount,
    required String expiryDate,
  }) async {
    await sendSmartNotification(
      title: '🎉 Yeni Kuponunuz!',
      body: '$discount indirim kuponu: $couponCode',
      type: 'coupon',
      data: {
        'action': 'use_coupon',
        'coupon_code': couponCode,
        'discount': discount,
        'expiry_date': expiryDate,
      },
    );
  }

  /// Bildirim geçmişini getir
  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    // Bu gerçek uygulamada veritabanından gelecek
    return [];
  }

  /// Bildirim ayarlarını güncelle
  Future<void> updateNotificationSettings({
    required String userId,
    required Map<String, bool> settings,
  }) async {
    // Bu gerçek uygulamada veritabanına kaydedilecek
    debugPrint('Notification settings updated for user $userId: $settings');
  }

  /// FCM token'ı getir
  String? get fcmToken => _fcmToken;

  /// Tüm bildirimleri temizle
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Belirli bildirimleri temizle
  Future<void> clearNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}
