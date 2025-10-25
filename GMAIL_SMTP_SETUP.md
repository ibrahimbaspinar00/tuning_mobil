# 📧 Gmail SMTP Kurulumu - Ücretsiz Gerçek Email

## 🎯 **Gmail SMTP ile Gerçek Email Gönderimi**

### ** ✅ Avantajlar**
- **Maliyet**: 0 TL (tamamen ücretsiz)
- **Limit**: 500 email/gün
- **Kurulum**: 5 dakika
- **Güvenlik**: Gmail güvenliği
- **Gerçek email**: Evet, email adresine gelir

## 📋 **Adım Adım Kurulum**

### **1. Gmail Hesabında 2FA Aktifleştir**
1. **Gmail**'e git: https://gmail.com
2. **Sağ üst köşe** > **Google Account** (profil fotoğrafı)
3. **Security** > **2-Step Verification**
4. **Get started** butonuna tıkla
5. **Telefon numarası** gir
6. **SMS kodu** gir ve aktifleştir

### **2. App Password Oluştur**
1. **Google Account** > **Security**
2. **2-Step Verification** > **App passwords**
3. **Select app**: **Mail** seç
4. **Select device**: **Other (Custom name)** seç
5. **Name**: "Tuning App" yaz
6. **Generate** butonuna tıkla
7. **16 haneli kodu** kopyala (örn: `abcd efgh ijkl mnop`)

### **3. Flutter Kodunu Güncelle**
`lib/services/gmail_smtp_service.dart` dosyasını aç:

```dart
// Gmail SMTP ayarları - BURAYA KENDİ BİLGİLERİNİ YAZ
static const String _gmailUsername = 'your-email@gmail.com'; // KENDİ GMAIL ADRESİN
static const String _gmailAppPassword = 'your-app-password'; // GMAIL APP PASSWORD (16 haneli)
```

**Örnek:**
```dart
static const String _gmailUsername = 'ibrahim@gmail.com'; // KENDİ GMAIL ADRESİN
static const String _gmailAppPassword = 'abcd efgh ijkl mnop'; // GMAIL APP PASSWORD
```

### **4. Test Et**
1. **Flutter uygulamasını** çalıştır
2. **Şifremi Unuttum** butonuna tıkla
3. **Email adresi** gir
4. **Gmail SMTP** seç
5. **Kod gönder** butonuna tıkla
6. **Email adresine** gelen kodu kontrol et

## 🔧 **Gerçek Email Gönderimi İçin**

### **mailer Paketi Ekle**
`pubspec.yaml` dosyasına ekle:

```yaml
dependencies:
  mailer: ^6.0.0
```

### **Gmail SMTP Kodu**
```dart
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

// Gmail SMTP ile gerçek email gönder
static Future<bool> sendRealEmail(String email, String code) async {
  try {
    final smtpServer = gmail(_gmailUsername, _gmailAppPassword);
    
    final message = Message()
      ..from = Address(_gmailUsername, 'Tuning App Admin')
      ..recipients.add(email)
      ..subject = 'Şifre Sıfırlama Kodunuz'
      ..text = '''
Merhaba,

Şifre sıfırlama talebiniz alınmıştır.

Doğrulama Kodunuz: $code

Bu kodu kullanarak yeni şifrenizi belirleyebilirsiniz.

Not: Bu kod 10 dakika geçerlidir.

Güvenliğiniz için bu kodu kimseyle paylaşmayın.

İyi günler,
Tuning App Admin Paneli
      ''';
    
    final sendReport = await send(message, smtpServer);
    print('Email gönderildi: ${sendReport.toString()}');
    return sendReport.successful.isNotEmpty;
    
  } catch (e) {
    print('Email gönderim hatası: $e');
    return false;
  }
}
```

## 🚀 **Kullanım**

### **Web Admin Panel'de**
1. **Şifremi Unuttum** butonuna tıkla
2. **Email adresi** gir
3. **Gmail SMTP** seç
4. **Kod gönder** butonuna tıkla
5. **Email adresine** gelen kodu kontrol et

### **Konsol Çıktısı**
```
📧 Gmail SMTP ile gerçek email gönderiliyor...
📧 Gönderen: ibrahim@gmail.com
📧 Alıcı: user@example.com
📧 Kod: 123456
✅ Gmail SMTP ile email gönderildi!
📧 Email adresinize gelen kodu kontrol edin: user@example.com
```

## 🔒 **Güvenlik**

### **App Password Güvenliği**
- ✅ **Sadece uygulama** için kullanılır
- ✅ **Gmail hesabı** güvenli kalır
- ✅ **İstediğin zaman** silebilirsin
- ✅ **2FA koruması** altında

### **Gmail Limitleri**
- ✅ **Günlük limit**: 500 email
- ✅ **Saatlik limit**: 100 email
- ✅ **Güvenlik**: Gmail güvenliği
- ✅ **Spam koruması**: Gmail spam koruması

## 🎯 **Sonuç**

**Gmail SMTP** ile:
- ✅ **Gerçek email** gönderirsin
- ✅ **Para ödemezsin** (tamamen ücretsiz)
- ✅ **Güvenli** (Gmail güvenliği)
- ✅ **Hızlı** (5 dakika kurulum)
- ✅ **Profesyonel** (gerçek email)

**Artık gerçek email gönderimi yapabilirsin!** 🎉
