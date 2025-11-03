import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Bildirim gönderme test yardımcısı
/// Bu dosya test amaçlıdır, production'da Firebase Functions kullanın
class NotificationTestHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Test bildirimi gönder (Sadece test için!)
  /// Production'da Firebase Console veya Cloud Functions kullanın
  static Future<void> sendTestNotification({
    required String title,
    required String body,
    String type = 'system',
    Map<String, dynamic>? data,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ Kullanıcı giriş yapmamış');
        return;
      }

      // FCM Token'ı al
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final fcmToken = userDoc.data()?['fcmToken'];
      
      if (fcmToken == null) {
        debugPrint('❌ FCM Token bulunamadı. Lütfen uygulamayı açık tutun.');
        // Token yoksa, direkt Firestore'a kaydet, Functions kullanıcıya token ile gönderecek
        debugPrint('⚠️ FCM Token bulunamadı, notification_queue\'ya kaydediliyor...');
      } else {
        debugPrint('📱 FCM Token bulundu: ${fcmToken.substring(0, 20)}...');
      }

      // Firebase Functions'a istek gönder (eğer varsa)
      // Ya da direkt Firestore'a kaydet ve Functions tetiklenir
      
      // Yöntem 1: Firestore'a kaydet, Functions tetiklesin (önerilen)
      final notificationRef = _firestore.collection('notification_queue').doc();
      await notificationRef.set({
        if (fcmToken != null) 'fcmToken': fcmToken,
        'userId': user.uid, // Token yoksa userId ile gönderilebilir
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      debugPrint('✅ Test bildirimi kuyruğa eklendi');
      debugPrint('📝 Firebase Functions bu bildirimi gönderecek');
      
      // Ayrıca kullanıcının bildirimler koleksiyonuna da ekle (görüntülenmesi için)
      final userNotificationRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc();
      
      await userNotificationRef.set({
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      debugPrint('✅ Bildirim kullanıcının bildirimler listesine eklendi');
      
    } catch (e) {
      debugPrint('❌ Test bildirimi gönderilemedi: $e');
      rethrow; // Hata durumunda tekrar fırlat
    }
  }

  /// Kampanya bildirimi test et
  static Future<void> testCampaignNotification() async {
    await sendTestNotification(
      title: '🎉 Test Kampanya Bildirimi',
      body: 'Bu bir test bildirimidir. Arkaplan bildirimleri çalışıyor!',
      type: 'promotion',
      data: {
        'action': 'view_campaign',
        'discount': 25,
      },
    );
  }

  /// Sipariş bildirimi test et
  static Future<void> testOrderNotification() async {
    await sendTestNotification(
      title: '✅ Test Sipariş Bildirimi',
      body: 'Siparişiniz onaylandı! #12345',
      type: 'order',
      data: {
        'action': 'view_order',
        'order_id': '12345',
      },
    );
  }
}

