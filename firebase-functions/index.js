const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Firebase Admin SDK'yı başlat
admin.initializeApp();

// Gmail SMTP ayarları - BURAYA KENDİ BİLGİLERİNİ YAZ
const gmailTransporter = nodemailer.createTransporter({
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