import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/notification.dart';

/// Push notification servisi
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
      // İzinleri kontrol et ve iste
      await _requestPermissions();
      
      // FCM token al
      await _getFCMToken();
      
      // Local notifications ayarla
      await _setupLocalNotifications();
      
      // Background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Notification tap handler
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // App açıkken gelen bildirimler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      _isInitialized = true;
      print('✅ NotificationService başlatıldı');
    } catch (e) {
      print('❌ NotificationService başlatılamadı: $e');
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
      
      // Token'ı Firestore'a kaydet
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

    // Android için notification channel oluştur
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Android notification channels oluştur
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
      'order_notifications',
      'Sipariş Bildirimleri',
      description: 'Sipariş durumu değişiklikleri',
      importance: Importance.high,
    );

    const AndroidNotificationChannel promotionChannel = AndroidNotificationChannel(
      'promotion_notifications',
      'Promosyon Bildirimleri',
      description: 'İndirim ve promosyon duyuruları',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
      'system_notifications',
      'Sistem Bildirimleri',
      description: 'Sistem güncellemeleri ve duyurular',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(orderChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(promotionChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(systemChannel);
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
        channelId: _getChannelId(message.data['type']),
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

  /// Local notification göster
  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Genel Bildirimler',
      channelDescription: 'Genel uygulama bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
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

  /// Channel ID belirle
  String _getChannelId(Map<String, dynamic> data) {
    final type = data['type'] ?? 'system';
    switch (type) {
      case 'order':
        return 'order_notifications';
      case 'promotion':
        return 'promotion_notifications';
      default:
        return 'system_notifications';
    }
  }

  /// Notification action handler
  Future<void> _handleNotificationAction(Map<String, dynamic> data) async {
    final action = data['action'];
    
    // TODO: Navigation logic based on action
    print('🎯 Notification action: $action');
  }

  /// Bildirim gönder (Admin panelinden)
  Future<void> sendNotification({
    required String title,
    required String body,
    String? imageUrl,
    String? type,
    String? userId,
    Map<String, dynamic>? data,
    DateTime? scheduledAt,
  }) async {
    try {
      final notification = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        imageUrl: imageUrl,
        type: type ?? 'system',
        data: data,
        userId: userId,
        createdAt: DateTime.now(),
        scheduledAt: scheduledAt,
      );

      // Firestore'a kaydet
      final notificationData = notification.toFirestore();
      notificationData['status'] = 'sent';
      notificationData['sentAt'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notificationData);

      print('✅ Bildirim gönderildi: $title');
    } catch (e) {
      print('❌ Bildirim gönderilemedi: $e');
    }
  }

  /// Kullanıcının bildirimlerini getir
  Stream<List<AppNotification>> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    // Sadece kullanıcıya özel bildirimleri al
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
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
