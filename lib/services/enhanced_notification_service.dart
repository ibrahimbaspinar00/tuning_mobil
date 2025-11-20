import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../model/notification.dart';
import '../config/app_routes.dart';
import '../main.dart';
import '../services/order_service.dart';

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
  
  // Stream subscriptions for memory leak prevention
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  /// Servisi başlat
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _requestPermissions();
      await _getFCMToken();
      await _setupLocalNotifications();
      await _createNotificationChannels();
      
      // Message handlers
      // Background handler main.dart'ta kaydedilmiş olmalı (main() içinde)
      // onBackgroundMessage sadece main() içinde çağrılmalı
      // Memory leak önleme: Subscription'ları kaydet
      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Uygulama kapalıyken açılan bildirimleri kontrol et
      // Geç çağrılır (plugin'in tamamen hazır olması için)
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkInitialMessage().catchError((e) {
          debugPrint('⚠️ Initial message check hatası (normal olabilir): $e');
        });
      });
      
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

  /// Background message handler (main.dart'tan çağrılır)
  /// Bu metod background isolate'de çalışır, singleton instance kullanılamaz
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('📱 Background mesaj işleniyor: ${message.messageId}');
    
    // Background isolate'de local notifications plugin'i yeniden initialize et
    final FlutterLocalNotificationsPlugin localNotifications = 
        FlutterLocalNotificationsPlugin();
    
    // Android için ayarlar
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

    // Background isolate'de initialize et
    await localNotifications.initialize(settings);
    
    // Notification channels oluştur (Android için)
    if (Platform.isAndroid) {
      final androidPlugin = localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      const AndroidNotificationChannel promotionChannel = AndroidNotificationChannel(
        'promotion_notifications',
        '🎯 Kampanya & İndirim',
        description: 'Özel kampanyalar, indirimler ve promosyonlar',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      
      const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
        'order_notifications',
        '📦 Sipariş Takibi',
        description: 'Sipariş onayı, hazırlık ve durum güncellemeleri',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      
      const AndroidNotificationChannel shippingChannel = AndroidNotificationChannel(
        'shipping_notifications',
        '🚚 Kargo Takibi',
        description: 'Kargo durumu ve teslimat bildirimleri',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      
      const AndroidNotificationChannel paymentChannel = AndroidNotificationChannel(
        'payment_notifications',
        '💳 Ödeme Bildirimleri',
        description: 'Ödeme onayı ve iade bildirimleri',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      
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
    
    // Local notification göster (uygulama kapalıyken)
    if (message.notification != null) {
      final channelId = _getChannelIdHelper(message.data);
      final channelName = _getChannelNameHelper(channelId);
      final channelDescription = _getChannelDescriptionHelper(channelId);
      
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
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

      await localNotifications.show(
        message.hashCode,
        message.notification!.title ?? 'Bildirim',
        message.notification!.body ?? '',
        details,
        payload: json.encode(message.data),
      );
      
      debugPrint('✅ Background bildirim gösterildi: ${message.notification!.title}');
      
      // Firestore kaydı uygulama açıldığında yapılacak
      debugPrint('✅ Background bildirim gösterildi');
    }
  }
  
  /// Helper methods for background handler (static-like, but instance methods)
  String _getChannelIdHelper(Map<String, dynamic> data) {
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
  
  String _getChannelNameHelper(String channelId) {
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

  String _getChannelDescriptionHelper(String channelId) {
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
  
  /// Foreground message handler
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📨 Foreground message alındı: ${message.messageId}');
    
    final notification = message.notification;
    if (notification != null) {
      await _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'Bildirim',
        body: notification.body ?? '',
        payload: json.encode(message.data),
        channelId: _getChannelId(message.data),
        type: message.data['type'] ?? 'system',
      );
      
      // Firestore'a kaydet
      await _saveNotificationToFirestore(message);
    }
  }
  
  /// Uygulama kapalıyken açılan bildirimleri kontrol et
  Future<void> _checkInitialMessage() async {
    try {
      // Platform kontrolü - Web ve bazı platformlarda desteklenmeyebilir
      if (kIsWeb) {
        debugPrint('⚠️ getInitialMessage web platformunda desteklenmiyor');
        return;
      }

      // Method channel kontrolü - Bazı durumlarda plugin henüz hazır olmayabilir
      // Bu durumda hatayı yakalayıp sessizce devam et
      try {
        final initialMessage = await _messaging.getInitialMessage()
            .timeout(const Duration(seconds: 2), onTimeout: () {
          debugPrint('⚠️ getInitialMessage timeout');
          return null;
        });
        
        if (initialMessage != null) {
          debugPrint('📱 Uygulama kapalıyken gelen bildirim var');
          await _handleNotificationTap(initialMessage);
        }
      } on MissingPluginException catch (e) {
        // Plugin henüz hazır değil veya platform desteklemiyor
        debugPrint('⚠️ Firebase Messaging plugin henüz hazır değil (normal olabilir): $e');
        // Uygulama çalışmaya devam eder, bu kritik bir hata değil
      } on PlatformException catch (e) {
        // Platform-specific hata
        debugPrint('⚠️ Platform exception (normal olabilir): $e');
      }
    } catch (e) {
      // Genel hata yakalama
      debugPrint('⚠️ getInitialMessage genel hatası (normal olabilir): $e');
      // Hata durumunda sessizce devam et, uygulama çalışmaya devam eder
    }
  }
  
  /// Bildirimi Firestore'a kaydet
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final notification = AppNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'Bildirim',
        body: message.notification?.body ?? '',
        type: message.data['type'] ?? 'system',
        createdAt: DateTime.now(),
        isRead: false,
        actionUrl: message.data['action']?.toString(),
        data: message.data,
      );
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toFirestore());
    } catch (e) {
      debugPrint('❌ Bildirim Firestore\'a kaydedilemedi: $e');
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
    
    if (response.payload == null || response.payload!.isEmpty) {
      // Payload yoksa bildirimler sayfasına git
      _navigateToNotifications();
      return;
    }
    
    try {
      // Payload'dan data parse et
      final payload = response.payload!;
      Map<String, dynamic>? data;
      
      // JSON decode dene
      try {
        data = json.decode(payload) as Map<String, dynamic>?;
      } catch (e) {
        // JSON decode başarısız oldu, eski format olabilir (toString() formatı)
        debugPrint('JSON decode başarısız, eski format parse ediliyor: $e');
        // Eski format için basit parse (fallback)
        data = _parseLegacyPayload(payload);
      }
      
      if (data != null && data.isNotEmpty) {
        _handleNotificationAction(data);
      } else {
        // Payload parse edilemediyse bildirimler sayfasına git
        _navigateToNotifications();
      }
    } catch (e) {
      debugPrint('Notification tap hatası: $e');
      _navigateToNotifications();
    }
  }
  
  /// Eski format payload'ı parse et (toString() formatı için fallback)
  Map<String, dynamic>? _parseLegacyPayload(String payload) {
    try {
      // Eğer payload Map.toString() formatındaysa (örnek: {action: view_order, order_id: 123})
      // Bu format güvenilir değil, ama fallback olarak deneyebiliriz
      if (payload.startsWith('{') && payload.endsWith('}')) {
        // Basit key-value parse
        final cleaned = payload.replaceAll('{', '').replaceAll('}', '');
        final pairs = cleaned.split(',');
        final Map<String, dynamic> result = {};
        
        for (final pair in pairs) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            final key = parts[0].trim();
            var value = parts[1].trim();
            // String tırnaklarını temizle
            if (value.startsWith("'") && value.endsWith("'")) {
              value = value.substring(1, value.length - 1);
            } else if (value.startsWith('"') && value.endsWith('"')) {
              value = value.substring(1, value.length - 1);
            }
            result[key] = value;
          }
        }
        
        return result.isNotEmpty ? result : null;
      }
    } catch (e) {
      debugPrint('Legacy payload parse hatası: $e');
    }
    
    return null;
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
    final action = data['action']?.toString();
    final type = data['type']?.toString();
    
    print('🎯 Notification action: $action, type: $type');
    
    if (navigatorKey.currentContext == null) {
      debugPrint('⚠️ Navigator context yok, navigasyon yapılamıyor');
      return;
    }
    
    final context = navigatorKey.currentContext!;
    
    try {
      switch (action) {
        case 'view_campaign':
          // Kampanya sayfasına git (şimdilik ana sayfaya)
          await Navigator.pushNamed(context, AppRoutes.main);
          break;
          
        case 'view_flash_sale':
          // Flash sale sayfasına git (şimdilik ana sayfaya)
          await Navigator.pushNamed(context, AppRoutes.main);
          break;
          
        case 'view_product':
          // Ürün detay sayfasına git
          final productId = data['product_id']?.toString() ?? 
                           data['productId']?.toString();
          if (productId != null && productId.isNotEmpty) {
            await AppRoutes.navigateToProductDetailById(context, productId);
          } else {
            // Product ID yoksa ana sayfaya git
            await Navigator.pushNamed(context, AppRoutes.main);
          }
          break;
          
        case 'view_order':
          // Sipariş detay sayfasına git
          final orderId = data['order_id']?.toString() ?? 
                         data['orderId']?.toString();
          if (orderId != null && orderId.isNotEmpty) {
            await _navigateToOrderDetail(context, orderId);
          } else {
            // Order ID yoksa siparişler sayfasına git
            await Navigator.pushNamed(context, AppRoutes.orders);
          }
          break;
          
        case 'track_shipment':
          // Kargo takip - sipariş detay sayfasına git
          final orderId = data['order_id']?.toString() ?? 
                         data['orderId']?.toString();
          if (orderId != null && orderId.isNotEmpty) {
            await _navigateToOrderDetail(context, orderId);
          } else {
            await Navigator.pushNamed(context, AppRoutes.orders);
          }
          break;
          
        case 'rate_order':
          // Sipariş değerlendirme - sipariş detay sayfasına git
          final orderId = data['order_id']?.toString() ?? 
                         data['orderId']?.toString();
          if (orderId != null && orderId.isNotEmpty) {
            await _navigateToOrderDetail(context, orderId);
          } else {
            await Navigator.pushNamed(context, AppRoutes.orders);
          }
          break;
          
        case 'view_refund':
          // İade detay - sipariş detay sayfasına git
          final orderId = data['order_id']?.toString() ?? 
                         data['orderId']?.toString();
          if (orderId != null && orderId.isNotEmpty) {
            await _navigateToOrderDetail(context, orderId);
          } else {
            await Navigator.pushNamed(context, AppRoutes.orders);
          }
          break;
          
        default:
          // Bilinmeyen action - bildirimler sayfasına git
          _navigateToNotifications();
          break;
      }
    } catch (e) {
      debugPrint('❌ Navigation hatası: $e');
      // Hata durumunda bildirimler sayfasına git
      _navigateToNotifications();
    }
  }
  
  /// Sipariş detay sayfasına git
  Future<void> _navigateToOrderDetail(BuildContext context, String orderId) async {
    try {
      final orderService = OrderService();
      final orderModel = await orderService.getOrderById(orderId);
      
      if (orderModel != null) {
        // OrderModel.Order'ı Order'a çevir
        final order = _convertOrderModelToOrder(orderModel);
        await AppRoutes.navigateToOrderDetail(context, order);
      } else {
        debugPrint('⚠️ Sipariş bulunamadı: $orderId');
        // Sipariş bulunamadıysa siparişler sayfasına git
        await Navigator.pushNamed(context, AppRoutes.orders);
      }
    } catch (e) {
      debugPrint('❌ Sipariş detay yükleme hatası: $e');
      await Navigator.pushNamed(context, AppRoutes.orders);
    }
  }
  
  /// OrderModel.Order'ı Order'a çevir
  dynamic _convertOrderModelToOrder(dynamic orderModel) {
    // OrderModel.Order aslında Order sınıfı (aynı model)
    // Direkt kullanabiliriz
    return orderModel;
  }
  
  /// Bildirimler sayfasına git
  void _navigateToNotifications() {
    if (navigatorKey.currentContext == null) {
      debugPrint('⚠️ Navigator context yok');
      return;
    }
    
    Navigator.pushNamed(navigatorKey.currentContext!, AppRoutes.notifications);
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
    String? fcmToken;
    
    // Eğer userId belirtilmişse, kullanıcının FCM token'ını al
    if (userId != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          fcmToken = userDoc.data()?['fcmToken'];
          print('📱 Kullanıcının FCM Token\'ı alındı: ${fcmToken != null ? fcmToken.substring(0, 20) + '...' : 'yok'}');
        }
      } catch (e) {
        print('⚠️ Kullanıcı FCM Token alınamadı: $e');
      }
    } else {
      // userId yoksa, mevcut kullanıcının token'ını kullan
      fcmToken = _fcmToken;
    }

    // notification_queue koleksiyonuna kaydet - Firebase Functions bunu dinleyip FCM bildirimi gönderecek
    try {
      final notificationQueueRef = _firestore.collection('notification_queue').doc();
      await notificationQueueRef.set({
        if (fcmToken != null) 'fcmToken': fcmToken,
        if (userId != null) 'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // Firebase Functions bunu 'sent' veya 'failed' olarak güncelleyecek
      });
      print('✅ Bildirim kuyruğa eklendi, Firebase Functions gönderecek: $title');
    } catch (e) {
      print('❌ Bildirim kuyruğa eklenemedi: $e');
    }

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

    // Local notification göster - Her durumda gösterilmeli (uygulama açıkken)
    try {
      await _showLocalNotification(
        id: notification.hashCode,
        title: title,
        body: body,
        payload: data != null ? json.encode(data) : null,
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
  
  /// Servisi temizle (memory leak önleme)
  /// NOT: Singleton olduğu için genellikle çağrılmaz, ama test veya reset için kullanılabilir
  void dispose() {
    _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = null;
    _messageOpenedSubscription?.cancel();
    _messageOpenedSubscription = null;
    _isInitialized = false;
    debugPrint('✅ EnhancedNotificationService temizlendi');
  }
}

// Background handler artık main.dart'ta tanımlı
