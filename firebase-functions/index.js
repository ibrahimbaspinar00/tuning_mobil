const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Firebase Admin SDK'yı başlat
admin.initializeApp();

// Gmail SMTP ayarları - BURAYA KENDİ BİLGİLERİNİ YAZ
const gmailTransporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'your-email@gmail.com', // KENDİ GMAIL ADRESİN
    pass: 'your-app-password' // GMAIL APP PASSWORD
  }
});

// Şifre sıfırlama emaili gönder
exports.sendPasswordResetEmail = functions.https.onCall(async (data, context) => {
  try {
    const { email, code, subject = 'Şifre Sıfırlama Kodu' } = data;
    
    // Email içeriği
    const emailContent = `
Merhaba,

Şifre sıfırlama talebiniz alınmıştır.

Doğrulama Kodunuz: ${code}

Bu kodu kullanarak yeni şifrenizi belirleyebilirsiniz.

Not: Bu kod 10 dakika geçerlidir.

Güvenliğiniz için bu kodu kimseyle paylaşmayın.

İyi günler,
Tuning App Admin Paneli
    `;
    
    // Email gönder
    const mailOptions = {
      from: 'your-email@gmail.com', // KENDİ GMAIL ADRESİN
      to: email,
      subject: subject,
      text: emailContent,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #333;">Şifre Sıfırlama</h2>
          <p>Merhaba,</p>
          <p>Şifre sıfırlama talebiniz alınmıştır.</p>
          <div style="background-color: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0;">
            <h1 style="color: #007bff; font-size: 32px; margin: 0;">${code}</h1>
          </div>
          <p>Bu kodu kullanarak yeni şifrenizi belirleyebilirsiniz.</p>
          <p><strong>Not:</strong> Bu kod 10 dakika geçerlidir.</p>
          <p>Güvenliğiniz için bu kodu kimseyle paylaşmayın.</p>
          <hr style="margin: 20px 0;">
          <p style="color: #666; font-size: 12px;">İyi günler,<br>Tuning App Admin Paneli</p>
        </div>
      `
    };
    
    // Email gönder
    const result = await gmailTransporter.sendMail(mailOptions);
    
    console.log('Email gönderildi:', result.messageId);
    
    return {
      success: true,
      messageId: result.messageId,
      message: 'Email başarıyla gönderildi'
    };
    
  } catch (error) {
    console.error('Email gönderim hatası:', error);
    
    return {
      success: false,
      error: error.message,
      message: 'Email gönderilemedi'
    };
  }
});

// Test fonksiyonu
exports.testEmail = functions.https.onCall(async (data, context) => {
  try {
    const { email } = data;
    
    const mailOptions = {
      from: 'your-email@gmail.com',
      to: email,
      subject: 'Test Email',
      text: 'Bu bir test emailidir.',
      html: '<h1>Test Email</h1><p>Bu bir test emailidir.</p>'
    };
    
    const result = await gmailTransporter.sendMail(mailOptions);
    
    return {
      success: true,
      messageId: result.messageId,
      message: 'Test email gönderildi'
    };
    
  } catch (error) {
    console.error('Test email hatası:', error);
    
    return {
      success: false,
      error: error.message,
      message: 'Test email gönderilemedi'
    };
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

// Firestore'dan bildirim kuyruğunu dinle ve FCM bildirimi gönder
exports.sendNotificationFromQueue = functions.firestore
  .document('notification_queue/{notificationId}')
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    
    // Sadece pending durumundaki bildirimleri işle
    if (notificationData.status !== 'pending') {
      console.log('⚠️ Bildirim zaten işlenmiş veya farklı durumda:', notificationData.status);
      return null;
    }

    let fcmToken = notificationData.fcmToken;
    const userId = notificationData.userId;

    // Eğer FCM token yoksa ve userId varsa, kullanıcının tokenını al ve bildirim ayarlarını kontrol et
    if (!fcmToken && userId) {
      try {
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        if (userDoc.exists) {
          fcmToken = userDoc.data()?.fcmToken;
          console.log('📱 Kullanıcının FCM Token\'ı alındı:', fcmToken ? fcmToken.substring(0, 20) + '...' : 'yok');
          
          // Bildirim ayarlarını kontrol et
          const settingsDoc = await admin.firestore().collection('notification_settings').doc(userId).get();
          if (settingsDoc.exists) {
            const settings = settingsDoc.data();
            const pushEnabled = settings?.pushNotifications ?? true;
            const notificationType = notificationData.type || 'system';
            
            // Bildirim tipine göre kontrol
            let shouldSend = pushEnabled;
            if (pushEnabled) {
              switch (notificationType) {
                case 'promotion':
                  shouldSend = settings?.promotionalOffers ?? false;
                  break;
                case 'order':
                  shouldSend = settings?.orderUpdates ?? true;
                  break;
                case 'product':
                case 'new_product':
                  shouldSend = settings?.newProductAlerts ?? true;
                  break;
                case 'price':
                  shouldSend = settings?.priceAlerts ?? true;
                  break;
                case 'security':
                  shouldSend = settings?.securityAlerts ?? true;
                  break;
                default:
                  shouldSend = pushEnabled; // Sistem bildirimleri için push ayarına bak
              }
            }
            
            if (!shouldSend) {
              console.log('⚠️ Kullanıcı bu bildirim tipini devre dışı bırakmış:', notificationType);
              await snap.ref.update({
                status: 'skipped',
                reason: 'Kullanıcı bildirim ayarları nedeniyle atlandı',
                skippedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
              return null;
            }
          }
        }
      } catch (error) {
        console.error('❌ Kullanıcı bilgisi alınamadı:', error);
      }
    }

    // Eğer hala token yoksa, tüm kullanıcıların tokenlarını al ve gönder
    if (!fcmToken) {
      console.log('⚠️ FCM Token bulunamadı, tüm kullanıcılara gönderilecek');
      try {
        const usersSnapshot = await admin.firestore().collection('users')
          .where('fcmToken', '!=', null)
          .get();
        
        // Her kullanıcının bildirim ayarlarını kontrol et ve sadece bildirim almak isteyenleri ekle
        const allTokens = [];
        const allUserIds = [];
        
        usersSnapshot.forEach(doc => {
          const token = doc.data().fcmToken;
          const uid = doc.id;
          if (token) {
            allTokens.push(token);
            allUserIds.push(uid);
          }
        });
        
        // Bildirim ayarlarını kontrol et
        const notificationType = notificationData.type || 'system';
        const tokens = [];
        
        for (let i = 0; i < allTokens.length; i++) {
          const userId = allUserIds[i];
          let shouldSend = true;
          
          try {
            const settingsDoc = await admin.firestore().collection('notification_settings').doc(userId).get();
            if (settingsDoc.exists) {
              const settings = settingsDoc.data();
              const pushEnabled = settings?.pushNotifications ?? true;
              
              if (!pushEnabled) {
                shouldSend = false;
              } else {
                // Bildirim tipine göre kontrol
                switch (notificationType) {
                  case 'promotion':
                    shouldSend = settings?.promotionalOffers ?? false;
                    break;
                  case 'order':
                    shouldSend = settings?.orderUpdates ?? true;
                    break;
                  case 'product':
                  case 'new_product':
                    shouldSend = settings?.newProductAlerts ?? true;
                    break;
                  case 'price':
                    shouldSend = settings?.priceAlerts ?? true;
                    break;
                  case 'security':
                    shouldSend = settings?.securityAlerts ?? true;
                    break;
                  default:
                    shouldSend = pushEnabled;
                }
              }
            }
          } catch (error) {
            // Hata durumunda gönder (varsayılan olarak gönder)
            console.error(`⚠️ Kullanıcı ${userId} ayarları alınamadı, gönderilecek:`, error);
          }
          
          if (shouldSend) {
            tokens.push(allTokens[i]);
          }
        }

        if (tokens.length === 0) {
          console.error('❌ Hiçbir kullanıcının FCM Token\'ı yok');
          await snap.ref.update({
            status: 'failed',
            error: 'FCM Token bulunamadı',
            failedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          return null;
        }

        // Toplu bildirim gönder
        const message = {
          notification: {
            title: notificationData.title,
            body: notificationData.body,
          },
          data: {
            type: notificationData.type || 'system',
            ...(notificationData.data || {}),
          },
          android: {
            priority: 'high',
            notification: {
              channelId: getChannelId(notificationData.type || 'system'),
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

        // Multicast mesaj gönder (max 500 token)
        const batchSize = 500;
        for (let i = 0; i < tokens.length; i += batchSize) {
          const batch = tokens.slice(i, i + batchSize);
          const multicastMessage = {
            ...message,
            tokens: batch,
          };

          try {
            const response = await admin.messaging().sendEachForMulticast(multicastMessage);
            console.log(`✅ ${response.successCount} bildirim gönderildi, ${response.failureCount} hata`);
          } catch (error) {
            console.error(`❌ Batch ${i / batchSize + 1} gönderme hatası:`, error);
          }
        }

        await snap.ref.update({
          status: 'sent',
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          sentToCount: tokens.length,
        });

        return { success: true, sentToCount: tokens.length };
      } catch (error) {
        console.error('❌ Toplu bildirim gönderme hatası:', error);
        await snap.ref.update({
          status: 'failed',
          error: error.message,
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return null;
      }
    }

    // Tek kullanıcıya bildirim gönder
    const message = {
      notification: {
        title: notificationData.title,
        body: notificationData.body,
      },
      data: {
        type: notificationData.type || 'system',
        ...(notificationData.data || {}),
      },
      token: fcmToken,
      android: {
        priority: 'high',
        notification: {
          channelId: getChannelId(notificationData.type || 'system'),
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

// HTTP Callable function - Direkt bildirim gönder (admin panel için)
exports.sendNotification = functions.https.onCall(async (data, context) => {
  const { fcmToken, title, body, type = 'system', notificationData = {}, userId } = data;

  if ((!fcmToken && !userId) || !title || !body) {
    throw new functions.https.HttpsError('invalid-argument', 'Eksik parametreler');
  }

  let token = fcmToken;
  
  // Eğer userId verilmişse token'ı al
  if (!token && userId) {
    try {
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      if (userDoc.exists) {
        token = userDoc.data()?.fcmToken;
      }
    } catch (error) {
      console.error('Kullanıcı token alınamadı:', error);
    }
  }

  if (!token) {
    throw new functions.https.HttpsError('not-found', 'FCM Token bulunamadı');
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
    token: token,
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