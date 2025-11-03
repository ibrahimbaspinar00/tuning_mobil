# 🚗 Tuning Mobil - Otomotiv Tuning E-Ticaret Uygulaması

Modern ve performanslı Flutter ile geliştirilmiş otomotiv tuning ürünleri için e-ticaret mobil uygulaması.

## 📋 Proje Özeti

**Tuning Mobil**, otomotiv tuning ürünlerini satın almak isteyen kullanıcılar için tasarlanmış, tam özellikli bir mobil e-ticaret uygulamasıdır. Firebase backend altyapısı ile güçlendirilmiş, modern UI/UX tasarımına sahip, performans odaklı bir Flutter uygulamasıdır.

### 🎯 Temel Özellikler

- **🛍️ E-Ticaret Fonksiyonları**
  - Ürün katalogu ve kategoriler
  - Ürün detay sayfaları
  - Favoriler (Listelerim)
  - Sepet yönetimi
  - Sipariş takibi
  - İndirim ve kampanya sistemi
  - Ürün değerlendirmeleri

- **👤 Kullanıcı Yönetimi**
  - Firebase Authentication ile güvenli giriş/kayıt
  - Profil yönetimi ve düzenleme
  - Adres yönetimi (çoklu adres desteği)
  - Ödeme yöntemleri yönetimi
  - Cüzdan sistemi (para yükleme)

- **🔔 Bildirim Sistemi**
  - Firebase Cloud Messaging (FCM) entegrasyonu
  - Push notification desteği (foreground & background)
  - Kampanya bildirimleri
  - Bildirim ayarları ve özelleştirme
  - Service Account ile gelişmiş bildirim gönderimi

- **🎨 Kullanıcı Deneyimi**
  - Modern ve profesyonel UI tasarımı
  - Dark/Light tema desteği
  - Responsive tasarım (telefon, tablet uyumlu)
  - Animasyonlar ve geçiş efektleri
  - AI tabanlı ürün önerileri

- **⚡ Performans Optimizasyonları**
  - Gelişmiş cache yönetimi
  - Bellek optimizasyonu
  - Görüntü cache sistemi
  - Lazy loading ve performans iyileştirmeleri
  - Network yönetimi ve offline destek

## 🏗️ Yapım Aşaması ve Teknolojiler

### Geliştirme Durumu
✅ **Tamamlanan Özellikler:**
- Kullanıcı kimlik doğrulama sistemi
- Ürün katalogu ve görüntüleme
- Sepet ve favoriler yönetimi
- Sipariş oluşturma ve takip
- Profil ve adres yönetimi
- Push notification altyapısı
- Firebase backend entegrasyonu
- Tema sistemi (dark/light mode)
- Performans optimizasyonları
- AI öneri servisi entegrasyonu

🔄 **Geliştirme Aşamasında:**
- Ödeme entegrasyonu
- Admin paneli
- Raporlama sistemi
- İleri seviye bildirim özelleştirmeleri

### Kullanılan Teknolojiler

#### Frontend (Flutter/Dart)
- **Framework**: Flutter 3.9.2+
- **State Management**: Provider
- **UI Components**: Material Design
- **Image Loading**: Cached Network Image
- **Local Storage**: Shared Preferences

#### Backend (Firebase)
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Cloud Functions**: Node.js
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Google APIs**: Service Account ile FCM v1 API

#### Diğer Teknolojiler
- **HTTP Requests**: http package
- **File Operations**: path_provider, open_file
- **PDF/Excel**: pdf, excel, printing
- **Image Picker**: image_picker
- **Permissions**: permission_handler
- **Connectivity**: connectivity_plus
- **Internationalization**: intl

## 📱 Uygulama Yapısı

### Proje Klasör Yapısı

```
lib/
├── config/              # Uygulama konfigürasyonları
│   └── app_routes.dart  # Route yönetimi
├── model/               # Veri modelleri
│   ├── product.dart
│   ├── order.dart
│   └── ...
├── sayfalar/           # Sayfa widget'ları
│   ├── main_screen.dart
│   ├── ana_sayfa.dart
│   ├── giris_sayfasi.dart
│   ├── sepetim_sayfasi.dart
│   ├── siparisler_sayfasi.dart
│   └── ...
├── services/           # İş mantığı servisleri
│   ├── firebase_data_service.dart
│   ├── product_service.dart
│   ├── order_service.dart
│   ├── notification_service.dart
│   ├── enhanced_notification_service.dart
│   └── ...
├── utils/              # Yardımcı fonksiyonlar
│   ├── performance_optimizer.dart
│   ├── advanced_cache_manager.dart
│   ├── memory_manager.dart
│   └── ...
├── widgets/            # Özel widget'lar
├── providers/           # State management
├── theme/              # Tema tanımları
└── main.dart           # Uygulama giriş noktası
```

### Sayfalar ve Özellikleri

1. **Ana Sayfa** (`ana_sayfa.dart`)
   - Ürün listesi ve kategoriler
   - Arama fonksiyonu
   - Kampanyalar ve indirimler

2. **Kategoriler** (`kategoriler_sayfasi.dart`)
   - Ürün kategorileri
   - Kategori bazlı filtreleme

3. **Ürün Detay** (`urun_detay_sayfasi.dart`)
   - Ürün bilgileri ve görselleri
   - Favorilere ekleme
   - Sepete ekleme
   - Ürün yorumları

4. **Sepetim** (`sepetim_sayfasi.dart`)
   - Sepet içeriği görüntüleme
   - Miktar güncelleme
   - Kupon uygulama
   - Sipariş oluşturma

5. **Siparişler** (`siparisler_sayfasi.dart`)
   - Sipariş geçmişi
   - Sipariş detayları
   - Sipariş durumu takibi

6. **Hesabım** (`hesabim_sayfasi.dart`)
   - Kullanıcı bilgileri
   - Siparişler, favoriler, adresler
   - Ayarlar

7. **Profil** (`profil_sayfasi.dart`)
   - Profil düzenleme
   - Fotoğraf yükleme

8. **Adres Yönetimi** (`adres_yonetimi_sayfasi.dart`)
   - Adres ekleme/düzenleme/silme
   - Varsayılan adres seçimi

9. **Bildirimler** (`bildirimler_sayfasi.dart`)
   - Bildirim geçmişi
   - Bildirim detayları

10. **Bildirim Ayarları** (`bildirim_ayarlari_sayfasi.dart`)
    - Bildirim tercihleri
    - Kampanya bildirimleri açma/kapama

## 🔧 Kurulum ve Çalıştırma

### Gereksinimler

- Flutter SDK 3.9.2 veya üzeri
- Dart SDK
- Android Studio / Xcode (mobil geliştirme için)
- Firebase hesabı ve proje
- Google Service Account JSON dosyası (bildirimler için)

### Kurulum Adımları

1. **Projeyi klonlayın**
```bash
git clone <repository-url>
cd tuning_mobil
```

2. **Bağımlılıkları yükleyin**
```bash
flutter pub get
```

3. **Firebase yapılandırması**
   - Firebase Console'dan `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarını indirin
   - Android için: `android/app/google-services.json`
   - iOS için: `ios/Runner/GoogleService-Info.plist`

4. **Service Account yapılandırması**
   - Google Cloud Console'dan Service Account JSON dosyasını indirin
   - Dosyayı `assets/service_account.json` konumuna koyun
   - `pubspec.yaml` dosyasında asset olarak tanımlı olduğundan emin olun

5. **Firebase Functions kurulumu** (opsiyonel)
```bash
cd firebase-functions
npm install
```

6. **Uygulamayı çalıştırın**
```bash
flutter run
```

### Build İşlemleri

**Android APK oluşturma:**
```bash
flutter build apk --release
```

**iOS build:**
```bash
flutter build ios --release
```

## 📦 Firebase Yapılandırması

### Gerekli Firebase Servisleri

1. **Firebase Authentication**
   - Email/Password authentication aktif
   - Google Sign-In (opsiyonel)

2. **Cloud Firestore**
   - Veritabanı kuralları yapılandırılmış olmalı
   - Collections: `users`, `products`, `orders`, `notifications`

3. **Firebase Storage**
   - Ürün görselleri ve kullanıcı profilleri için

4. **Firebase Cloud Messaging**
   - Push notification için FCM token yönetimi
   - Background message handler yapılandırılmış

5. **Cloud Functions**
   - Bildirim gönderme fonksiyonları
   - Email gönderimi (opsiyonel)

### Firestore Veri Yapısı

```
users/
  └── {userId}/
      ├── profile (kullanıcı bilgileri)
      ├── addresses (adresler)
      ├── paymentMethods (ödeme yöntemleri)
      └── wallet (cüzdan bilgileri)

products/
  └── {productId}/
      ├── name, price, description
      ├── category, stock
      ├── images, reviews
      └── ...

orders/
  └── {orderId}/
      ├── userId, products
      ├── totalAmount, status
      ├── address, paymentMethod
      └── createdAt, updatedAt

notifications/
  └── {notificationId}/
      ├── userId, title, body
      ├── type, data
      └── createdAt, read
```

## 🔔 Bildirim Sistemi

### Özellikler

- **Foreground Bildirimleri**: Uygulama açıkken gelen bildirimler
- **Background Bildirimleri**: Uygulama kapalıyken gelen bildirimler
- **Kampanya Bildirimleri**: Otomatik kampanya duyuruları
- **Service Account ile Gönderim**: FCM v1 API kullanımı

### Bildirim Gönderme

Firebase Cloud Functions veya direkt FCM API ile bildirim gönderilebilir. Service Account JSON dosyası ile güvenli bildirim gönderimi desteklenmektedir.

## 🎨 Tema Sistemi

Uygulama dark ve light tema desteğine sahiptir. Kullanıcı tercihleri `SharedPreferences` ile saklanır ve `ThemeProvider` ile yönetilir.

## ⚡ Performans Optimizasyonları

- **Cache Yönetimi**: Görüntüler ve veriler için akıllı cache sistemi
- **Bellek Yönetimi**: Otomatik bellek temizleme ve optimizasyon
- **Lazy Loading**: Sayfalar için lazy loading uygulaması
- **Image Optimization**: Görüntü cache ve resize işlemleri
- **Network Optimization**: İstek optimizasyonu ve offline destek

## 📊 Proje İstatistikleri

- **Toplam Sayfa**: 20+ sayfa
- **Servis Sayısı**: 17 servis
- **Widget Sayısı**: 9+ özel widget
- **Utility Fonksiyonlar**: 14+ yardımcı modül
- **Platform Desteği**: Android, iOS, Web, Windows, macOS, Linux

## 🚀 Deployment

### Android
- Google Play Store için APK/AAB oluşturma
- Firebase App Distribution ile beta test

### iOS
- App Store Connect'e yükleme
- TestFlight ile beta test

### Web
```bash
flutter build web
```

## 📝 Lisans

Bu proje özel bir projedir. Tüm hakları saklıdır.

## 👥 Geliştirici

Tuning Mobil uygulaması modern Flutter teknolojileri ve Firebase backend altyapısı kullanılarak geliştirilmiştir.

---

**Not**: Bu uygulama production kullanımı için hazırdır. Firebase yapılandırmaları ve güvenlik kurallarının düzgün şekilde ayarlandığından emin olun.
