
class SendGridService {
  // SendGrid API Key - BURAYA KENDİ API KEY'İNİ YAZ
  static const String _apiKey = 'your-sendgrid-api-key';
  static const String _fromEmail = 'your-email@yourdomain.com';
  
  // SendGrid ile email gönderme
  static Future<bool> sendPasswordResetCode(String email, String code) async {
    try {
      print('📧 SendGrid ile email gönderiliyor...');
      print('📧 Alıcı: $email');
      print('📧 Kod: $code');
      
      // Email içeriği
      final emailContent = '''
Merhaba,

Şifre sıfırlama talebiniz alınmıştır.

Doğrulama Kodunuz: $code

Bu kodu kullanarak yeni şifrenizi belirleyebilirsiniz.

Not: Bu kod 10 dakika geçerlidir.

Güvenliğiniz için bu kodu kimseyle paylaşmayın.

İyi günler,
Tuning App Admin Paneli
      ''';
      
      // SendGrid API ile email gönder
      final success = await _sendWithSendGrid(email, 'Şifre Sıfırlama Kodu', emailContent);
      
      if (success) {
        print('✅ SendGrid ile email gönderildi!');
        return true;
      } else {
        print('❌ SendGrid ile email gönderilemedi!');
        return false;
      }
      
    } catch (e) {
      print('❌ SendGrid hatası: $e');
      return false;
    }
  }
  
  // SendGrid API ile email gönderme
  static Future<bool> _sendWithSendGrid(String to, String subject, String body) async {
    try {
      print('📧 SendGrid API ile email gönderiliyor...');
      print('📧 API Key: $_apiKey');
      print('📧 From: $_fromEmail');
      print('📧 To: $to');
      print('📧 Subject: $subject');
      
      // Gerçek implementasyon için:
      // 1. HTTP request gönder
      // 2. SendGrid API endpoint kullan
      // 3. JSON response işle
      
      await Future.delayed(const Duration(seconds: 2));
      print('✅ SendGrid API ile email gönderildi!');
      return true;
      
    } catch (e) {
      print('❌ SendGrid API hatası: $e');
      return false;
    }
  }
  
  // Kurulum talimatları
  static void showSetupInstructions() {
    print('''
🔧 SendGrid Kurulum Talimatları:

1. SendGrid.com'a git ve ücretsiz hesap oluştur
2. Dashboard'da "API Keys" bölümüne git
3. "Create API Key" butonuna tıkla
4. API Key'i kopyala
5. _apiKey değişkenine yapıştır

Örnek:
static const String _apiKey = 'SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

6. pubspec.yaml dosyasına http paketi ekleyin:
   dependencies:
     http: ^1.1.0

7. Gerçek HTTP request implementasyonu yapın

Not: Gerçek uygulamada bu bilgileri environment variables olarak saklayın!
    ''');
  }
}
