# 🆓 Ücretsiz Email Gönderimi Rehberi

## 📧 **4 Farklı Ücretsiz Yöntem**

### **1. 🎯 Simüle Edilmiş Email (Tamamen Ücretsiz)**
- ✅ **Maliyet**: 0 TL
- ✅ **Kurulum**: Gerekmez
- ✅ **Limit**: Sınırsız
- ❌ **Gerçek Email**: Hayır, sadece konsola yazdırır

**Kullanım:**
```dart
// Varsayılan olarak aktif
final success = await EmailService.sendPasswordResetCode(email, code);
```

### **2. 📧 Gmail SMTP (Ücretsiz)**
- ✅ **Maliyet**: 0 TL
- ✅ **Kurulum**: Gmail hesabı + App Password
- ✅ **Limit**: Gmail limitleri (500 email/gün)
- ✅ **Gerçek Email**: Evet

**Kurulum:**
1. **Gmail hesabında** 2-Factor Authentication aktifleştir
2. **Google Account** > **Security** > **2-Step Verification**
3. **App passwords** > **Mail** > Yeni password oluştur
4. **16 haneli kodu** kopyala

**Kod Güncelleme:**
```dart
// lib/services/gmail_smtp_service.dart
static const String _gmailUsername = 'your-email@gmail.com'; // KENDİ GMAIL ADRESİN
static const String _gmailAppPassword = 'your-app-password'; // GMAIL APP PASSWORD
```

### **3. ☁️ SendGrid Ücretsiz Plan**
- ✅ **Maliyet**: 0 TL
- ✅ **Kurulum**: SendGrid hesabı + API Key
- ✅ **Limit**: 100 email/gün
- ✅ **Gerçek Email**: Evet

**Kurulum:**
1. **SendGrid.com**'a git
2. **Ücretsiz hesap** oluştur
3. **API Key** oluştur
4. **API Key'i** kopyala

**Kod Güncelleme:**
```dart
// lib/services/sendgrid_free_service.dart
static const String _sendGridApiKey = 'YOUR_SENDGRID_API_KEY'; // SENDGRID API KEY
static const String _senderEmail = 'noreply@yourdomain.com'; // GÖNDEREN EMAIL
```

### **4. 🔥 Firebase Functions (Ücretli)**
- ❌ **Maliyet**: Billing gerekli
- ✅ **Kurulum**: Firebase Console + Billing
- ✅ **Limit**: Firebase limitleri
- ✅ **Gerçek Email**: Evet

## 🚀 **Hızlı Başlangıç**

### **Simüle Edilmiş Email (Önerilen)**
```dart
// Hiçbir kurulum gerekmez
final success = await EmailService.sendPasswordResetCode(email, code);
```

### **Gmail SMTP (Gerçek Email)**
1. Gmail hesabında 2FA aktifleştir
2. App password oluştur
3. `gmail_smtp_service.dart` dosyasını güncelle
4. Kullan: `GmailSMTPService.sendPasswordResetCode(email, code)`

### **SendGrid (Gerçek Email)**
1. SendGrid.com'da ücretsiz hesap oluştur
2. API Key oluştur
3. `sendgrid_free_service.dart` dosyasını güncelle
4. Kullan: `SendGridFreeService.sendPasswordResetCode(email, code)`

## 🎯 **Önerilen Sıralama**

1. **Simüle Edilmiş** (Test için)
2. **Gmail SMTP** (Kişisel kullanım)
3. **SendGrid** (Profesyonel kullanım)
4. **Firebase Functions** (Kurumsal kullanım)

## 💡 **İpuçları**

- **Test için**: Simüle edilmiş email kullan
- **Kişisel projeler**: Gmail SMTP kullan
- **Profesyonel projeler**: SendGrid kullan
- **Kurumsal projeler**: Firebase Functions kullan

## 🔧 **Sorun Giderme**

### Gmail SMTP Hatası
- 2-Factor Authentication aktif mi?
- App password doğru mu?
- Gmail hesabı aktif mi?

### SendGrid Hatası
- API Key doğru mu?
- Hesap doğrulanmış mı?
- Günlük limit aşıldı mı?

### Firebase Functions Hatası
- Billing aktif mi?
- Functions deploy edildi mi?
- Gmail SMTP ayarları doğru mu?

## 🎉 **Sonuç**

Artık 4 farklı email gönderim yönteminiz var:
- **Simüle** (ücretsiz, test)
- **Gmail** (ücretsiz, gerçek)
- **SendGrid** (ücretsiz, profesyonel)
- **Firebase** (ücretli, kurumsal)

İhtiyacınıza göre seçin ve kullanın! 🚀
