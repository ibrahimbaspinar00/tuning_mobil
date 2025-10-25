# 🔥 Firebase Functions Email Kurulumu

## 📋 Adım Adım Kurulum

### 1. Firebase Console Kurulumu
1. **Firebase Console'a git**: https://console.firebase.google.com
2. **Projenizi seçin** (tuning-mobil)
3. **Functions** bölümüne git
4. **"Get started"** butonuna tıkla
5. **Billing** planını seç (Blaze - Pay as you go)

### 2. Gmail SMTP Ayarları
1. **Gmail hesabınızda** 2-Factor Authentication'ı aktifleştirin
2. **Google Account** > **Security** > **2-Step Verification**
3. **App passwords** bölümünden yeni bir app password oluşturun
4. **"Mail"** seçin ve password oluşturun
5. **16 haneli kodu** kopyalayın

### 3. Firebase Functions Kodu Güncelle
`firebase-functions/index.js` dosyasında şu satırları güncelleyin:

```javascript
// Gmail SMTP ayarları - BURAYA KENDİ BİLGİLERİNİ YAZ
const gmailTransporter = nodemailer.createTransporter({
  service: 'gmail',
  auth: {
    user: 'your-email@gmail.com', // KENDİ GMAIL ADRESİN
    pass: 'your-app-password' // GMAIL APP PASSWORD
  }
});
```

### 4. Firebase CLI ile Deploy
```bash
# Firebase login (tarayıcıda giriş yap)
firebase login

# Functions deploy et
cd firebase-functions
firebase deploy --only functions
```

### 5. Test Et
1. **Firebase Console** > **Functions**
2. **"sendPasswordResetEmail"** fonksiyonunu test et
3. **Flutter uygulamasında** şifre unutma test et

## 🚀 Kullanım

### Flutter'da Email Gönderme
```dart
// Firebase Functions ile email gönder
final success = await FirebaseEmailService.sendPasswordResetCode(
  'user@example.com', 
  '123456'
);
```

### Test Email Gönderme
```dart
// Test email gönder
final success = await FirebaseEmailService.sendTestEmail(
  'user@example.com'
);
```

## 🔧 Sorun Giderme

### Hata: "Functions not deployed"
- Firebase Functions'ı deploy et: `firebase deploy --only functions`

### Hata: "Gmail authentication failed"
- Gmail App Password'ü kontrol et
- 2-Factor Authentication aktif mi kontrol et

### Hata: "Billing not enabled"
- Firebase Console'da Billing'i aktifleştir
- Blaze planını seç

## 📧 Email Özellikleri

- ✅ **HTML email** desteği
- ✅ **Güvenli SMTP** bağlantısı
- ✅ **Hata yönetimi**
- ✅ **Logging** sistemi
- ✅ **Ölçeklenebilir** yapı

## 🎯 Sonuç

Firebase Functions ile email gönderimi:
- **Güvenli** ✅
- **Ölçeklenebilir** ✅
- **Profesyonel** ✅
- **Maliyet etkin** ✅

Artık gerçek email gönderimi yapabilirsiniz! 🎉
