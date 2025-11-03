import 'dart:convert';
import 'package:googleapis/fcm/v1.dart' as fcm;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// FCM v1 API kullanarak bildirim gönderme servisi
/// ⚠️ UYARI: Service Account JSON'u client-side'da tutmak güvenlik riski taşır!
/// Production'da backend'de kullanılmalı.
class FCMServiceAccountService {
  // Service Account JSON içeriği (assets klasöründen okunur)
  // ⚠️ GÜVENLİK: Bu dosyayı .gitignore'a ekleyin ve public repo'ya koymayın!
  
  /// Service Account JSON'u yükle (assets'ten veya cache'ten)
  static Future<Map<String, dynamic>?> _loadServiceAccountJson() async {
    try {
      // Önce assets'ten okumayı dene
      try {
        final jsonString = await rootBundle.loadString('assets/service_account.json');
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('⚠️ assets/service_account.json bulunamadı');
        
        // Assets'te yoksa, kullanıcıya bilgi ver ve null döndür
        debugPrint('💡 Çözüm: İndirdiğiniz JSON dosyasını assets/service_account.json olarak kaydedin');
        debugPrint('💡 Detaylar için: SERVICE_ACCOUNT_KURULUM.md dosyasına bakın');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Service Account JSON yüklenemedi: $e');
      return null;
    }
  }

  /// Service Account ile bildirim gönder
  /// ⚠️ NOT: Service Account JSON'unu buraya yapıştırmanız gerekiyor
  static Future<bool> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    String type = 'system',
    Map<String, dynamic>? data,
  }) async {
    try {
      // Service Account JSON'unu yükle
      final serviceAccountMap = await _loadServiceAccountJson();
      
      if (serviceAccountMap == null) {
        debugPrint('❌ Service Account JSON bulunamadı, bildirim gönderilemedi');
        debugPrint('💡 assets/service_account.json dosyasını oluşturun');
        return false;
      }

      // Credentials oluştur
      final credentials = ServiceAccountCredentials.fromJson(serviceAccountMap);
      
      // Auth client oluştur
      final authClient = await clientViaServiceAccount(
        credentials,
        [fcm.FirebaseCloudMessagingApi.cloudPlatformScope],
      );

      try {
        // FCM API client oluştur
        final fcmApi = fcm.FirebaseCloudMessagingApi(authClient);

        // Channel ID belirle
        String channelId;
        switch (type) {
          case 'promotion':
            channelId = 'promotion_notifications';
            break;
          case 'order':
            channelId = 'order_notifications';
            break;
          case 'shipping':
            channelId = 'shipping_notifications';
            break;
          case 'payment':
            channelId = 'payment_notifications';
            break;
          default:
            channelId = 'system_notifications';
        }

        // Bildirim mesajı oluştur
        final message = fcm.Message(
          notification: fcm.Notification(
            title: title,
            body: body,
          ),
          token: fcmToken,
          data: data?.map((key, value) => MapEntry(key, value.toString())),
          android: fcm.AndroidConfig(
            priority: 'high',
            notification: fcm.AndroidNotification(
              channelId: channelId,
              sound: 'default',
            ),
          ),
          apns: fcm.ApnsConfig(
            headers: {
              'apns-priority': '10',
            },
            payload: {
              'aps': {
                'sound': 'default',
                'badge': 1,
              },
            },
          ),
        );

        // Firebase Project ID
        const projectId = 'tuning-app-789ce';
        final projectPath = 'projects/$projectId';

        // SendMessageRequest oluştur
        final request = fcm.SendMessageRequest(
          message: message,
        );

        // Bildirim gönder
        final response = await fcmApi.projects.messages.send(
          request,
          projectPath,
        );

        debugPrint('✅ FCM bildirimi gönderildi: ${response.name}');
        return true;
      } finally {
        authClient.close();
      }
    } catch (e) {
      debugPrint('❌ FCM bildirimi gönderilemedi: $e');
      debugPrint('❌ Hata detayı: ${e.toString()}');
      if (e is Exception) {
        debugPrint('❌ Exception: ${e.toString()}');
      }
      return false;
    }
  }
}

