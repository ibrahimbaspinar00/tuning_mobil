/**
 * Firebase Cloud Functions - Bildirim Gönderme Örneği
 * 
 * Bu dosyayı firebase-functions/index.js dosyasına ekleyebilirsiniz
 * veya ayrı bir fonksiyon olarak deploy edebilirsiniz
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Firestore'dan bildirim kuyruğunu dinle ve gönder
exports.sendNotificationFromQueue = functions.firestore
  .document('notification_queue/{notificationId}')
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    
    // Sadece pending durumundaki bildirimleri işle
    if (notificationData.status !== 'pending') {
      return null;
    }

    const message = {
      notification: {
        title: notificationData.title,
        body: notificationData.body,
      },
      data: {
        type: notificationData.type || 'system',
        ...notificationData.data,
      },
      token: notificationData.fcmToken,
      android: {
        priority: 'high',
        notification: {
          channelId: getChannelId(notificationData.type),
          sound: 'default',
          icon: '@mipmap/ic_launcher',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('✅ Bildirim gönderildi:', response);
      
      // Durumu güncelle
      await snap.ref.update({
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        messageId: response,
      });
      
      return response;
    } catch (error) {
      console.error('❌ Bildirim gönderme hatası:', error);
      
      // Hata durumunu kaydet
      await snap.ref.update({
        status: 'failed',
        error: error.message,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return null;
    }
  });

// HTTP Callable function - Direkt bildirim gönder
exports.sendNotification = functions.https.onCall(async (data, context) => {
  // Auth kontrolü (isteğe bağlı)
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Giriş yapmanız gerekiyor');
  }

  const { fcmToken, title, body, type = 'system', notificationData = {} } = data;

  if (!fcmToken || !title || !body) {
    throw new functions.https.HttpsError('invalid-argument', 'Eksik parametreler');
  }

  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: {
      type: type,
      ...notificationData,
    },
    token: fcmToken,
    android: {
      priority: 'high',
      notification: {
        channelId: getChannelId(type),
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Bildirim gönderme hatası:', error);
    throw new functions.https.HttpsError('internal', 'Bildirim gönderilemedi', error.message);
  }
});

// Channel ID belirleme helper
function getChannelId(type) {
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

// Toplu bildirim gönderme (topic'e göre)
exports.sendNotificationToTopic = functions.https.onCall(async (data, context) => {
  const { topic, title, body, type = 'system', notificationData = {} } = data;

  if (!topic || !title || !body) {
    throw new functions.https.HttpsError('invalid-argument', 'Eksik parametreler');
  }

  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: {
      type: type,
      ...notificationData,
    },
    topic: topic,
    android: {
      priority: 'high',
      notification: {
        channelId: getChannelId(type),
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Bildirim gönderme hatası:', error);
    throw new functions.https.HttpsError('internal', 'Bildirim gönderilemedi', error.message);
  }
});

