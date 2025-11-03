import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Storage yönetimi için servis
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fotoğrafı Firebase Storage'a yükle
  Future<String> uploadReviewImage(File imageFile, String reviewId, {int? index}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Dosya varlığını kontrol et
      if (!await imageFile.exists()) {
        throw Exception('Fotoğraf dosyası bulunamadı');
      }

      // Dosya boyutunu kontrol et (max 10MB)
      final fileSize = await imageFile.length();
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        throw Exception('Fotoğraf çok büyük (Maksimum 10MB). Boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      }

      // Dosya uzantısını kontrol et
      final fileName = imageFile.path.split('/').last.toLowerCase();
      String contentType = 'image/jpeg'; // Varsayılan
      String fileExtension = '.jpg';
      
      // Dosya uzantısını belirle (daha güvenli)
      if (fileName.contains('.png')) {
        contentType = 'image/png';
        fileExtension = '.png';
      } else if (fileName.contains('.jpg') || fileName.contains('.jpeg')) {
        contentType = 'image/jpeg';
        fileExtension = '.jpg';
      } else if (fileName.contains('.webp')) {
        contentType = 'image/webp';
        fileExtension = '.webp';
      } else if (fileName.contains('.gif')) {
        contentType = 'image/gif';
        fileExtension = '.gif';
      }
      
      debugPrint('Dosya uzantısı tespit edildi: $fileExtension, Content Type: $contentType');

      // Dosya adı oluştur: reviews/{userId}/{reviewId}/{timestamp}_{index}.{ext}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = index != null ? '${timestamp}_$index$fileExtension' : '$timestamp$fileExtension';
      
      // ReviewId'yi temizle (özel karakterleri kaldır)
      final cleanReviewId = reviewId.replaceAll(RegExp(r'[^\w\-]'), '_');
      
      final path = 'reviews/${user.uid}/$cleanReviewId/$finalFileName';
      
      // Path'teki özel karakterleri temizle (sadece güvenli karakterler kalmalı)
      final cleanPath = path.replaceAll(RegExp(r'[^\w\-/.]'), '_');
      
      debugPrint('Review ID temizleme: $reviewId -> $cleanReviewId');

      debugPrint('=== FOTOĞRAF YÜKLEME BAŞLIYOR ===');
      debugPrint('Dosya: ${imageFile.path}');
      debugPrint('Boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      debugPrint('Orijinal Path: $path');
      debugPrint('Temizlenmiş Path: $cleanPath');
      debugPrint('Content Type: $contentType');

      // Fotoğrafı yükle (temizlenmiş path ile)
      final ref = _storage.ref().child(cleanPath);
      
      debugPrint('Firebase Storage referansı oluşturuldu: $cleanPath');
      
      // Upload task'ı başlat
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalFileName': fileName,
          },
        ),
      );

      // Upload progress'i bekle (timeout ile)
      debugPrint('Upload task başlatıldı, bekleniyor...');
      try {
        // Timeout: 60 saniye
        await uploadTask.timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            debugPrint('✗ Upload timeout (60 saniye)');
            throw Exception('Fotoğraf yükleme zaman aşımına uğradı. Lütfen tekrar deneyin.');
          },
        );
        debugPrint('✓ Upload task tamamlandı');
      } catch (e) {
        debugPrint('✗ Upload task hatası: $e');
        rethrow;
      }

      // Download URL'yi al (timeout ile)
      debugPrint('Download URL alınıyor...');
      try {
        final downloadUrl = await ref.getDownloadURL().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('✗ Download URL timeout (30 saniye)');
            throw Exception('Fotoğraf URL alınamadı. Lütfen tekrar deneyin.');
          },
        );
        debugPrint('✓ Download URL alındı: $downloadUrl');
        
        // URL'nin geçerli olduğunu kontrol et
        if (downloadUrl.isEmpty) {
          throw Exception('Geçersiz fotoğraf URL\'si alındı');
        }
        
        return downloadUrl;
      } catch (e) {
        debugPrint('✗ Download URL alma hatası: $e');
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('✗ Fotoğraf yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Birden fazla fotoğrafı yükle
  Future<List<String>> uploadReviewImages(
    List<File> imageFiles,
    String reviewId,
  ) async {
    try {
      if (imageFiles.isEmpty) {
        debugPrint('Yüklenecek fotoğraf yok');
        return [];
      }

      debugPrint('=== TOPLU FOTOĞRAF YÜKLEME BAŞLIYOR ===');
      debugPrint('Fotoğraf sayısı: ${imageFiles.length}');
      debugPrint('Review ID: $reviewId');

      final urls = <String>[];
      int successCount = 0;
      int failCount = 0;
      
      for (int i = 0; i < imageFiles.length; i++) {
        try {
          debugPrint('Fotoğraf ${i + 1}/${imageFiles.length} yükleniyor...');
          
          // Dosya varlığını kontrol et
          if (!await imageFiles[i].exists()) {
            debugPrint('✗ Fotoğraf ${i + 1} dosyası bulunamadı: ${imageFiles[i].path}');
            failCount++;
            continue; // Bu fotoğrafı atla, diğerlerine devam et
          }
          
          final url = await uploadReviewImage(imageFiles[i], reviewId, index: i);
          urls.add(url);
          successCount++;
          debugPrint('✓ Fotoğraf ${i + 1} başarıyla yüklendi: $url');
        } catch (e, stackTrace) {
          debugPrint('✗ Fotoğraf ${i + 1} yüklenemedi: $e');
          debugPrint('Stack trace: $stackTrace');
          failCount++;
          // Bir fotoğraf yüklenemezse diğerlerini denemeye devam et
          // Tüm fotoğraflar başarısız olursa hata fırlat
        }
      }

      debugPrint('=== TOPLU FOTOĞRAF YÜKLEME SONUÇLARI ===');
      debugPrint('Başarılı: $successCount/${imageFiles.length}');
      debugPrint('Başarısız: $failCount/${imageFiles.length}');
      
      // Eğer hiç fotoğraf yüklenemediyse hata fırlat
      if (urls.isEmpty && imageFiles.isNotEmpty) {
        throw Exception('Tüm fotoğraflar yüklenemedi. Lütfen tekrar deneyin.');
      }
      
      // Eğer bazı fotoğraflar yüklenemediyse uyarı ver ama devam et
      if (failCount > 0 && urls.isNotEmpty) {
        debugPrint('⚠ UYARI: $failCount fotoğraf yüklenemedi ama $successCount fotoğraf başarıyla yüklendi');
      }

      debugPrint('=== TOPLU FOTOĞRAF YÜKLEME TAMAMLANDI ===');
      debugPrint('Başarıyla yüklenen: ${urls.length}/${imageFiles.length}');
      
      return urls;
    } catch (e, stackTrace) {
      debugPrint('✗ Toplu fotoğraf yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fotoğrafı sil
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
      // Hata durumunda sessizce devam et
    }
  }

  /// Birden fazla fotoğrafı sil
  Future<void> deleteImages(List<String> imageUrls) async {
    try {
      for (final url in imageUrls) {
        await deleteImage(url);
      }
    } catch (e) {
      debugPrint('Error deleting images: $e');
    }
  }
}

