import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../model/product_review.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collectionName = 'product_reviews';

  // Ürün için tüm yorumları getir
  static Future<List<ProductReview>> getProductReviews(String productId) async {
    try {
      debugPrint('=== YORUMLAR GETİRİLİYOR ===');
      debugPrint('Product ID: $productId');
      
      // Önce tüm yorumları getir (isApproved kontrolü olmadan)
      // Source.server kullanarak cache'i bypass et (yeni yorumlar için)
      final allReviewsSnapshot = await _firestore
          .collection(_collectionName)
          .where('productId', isEqualTo: productId)
          .get(const GetOptions(source: Source.server));

      debugPrint('Toplam yorum sayısı (onaysız dahil): ${allReviewsSnapshot.docs.length}');

      // Sonra memory'de filtrele (composite index sorununu önlemek için)
      final allReviews = allReviewsSnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            debugPrint('Review ID: ${doc.id}, isApproved: ${data['isApproved']}');
            return ProductReview.fromJson({
              'id': doc.id,
              ...data,
            });
          })
          .toList();

      // isApproved olanları filtrele
      final approvedReviews = allReviews.where((review) => review.isApproved == true).toList();
      
      // createdAt'e göre sırala
      approvedReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('Onaylı yorum sayısı: ${approvedReviews.length}');

      debugPrint('✓ Yorumlar başarıyla getirildi: ${approvedReviews.length} adet');
      return approvedReviews;
    } catch (e, stackTrace) {
      debugPrint('✗ Yorumlar getirilirken hata oluştu: $e');
      debugPrint('Stack trace: $stackTrace');
      // Hata durumunda boş liste döndür
      return [];
    }
  }


  // Kullanıcının bir ürün için yorumunu getir
  static Future<ProductReview?> getUserReviewForProduct(String productId, String userId) async {
    try {
      // Source.server kullanarak cache'i bypass et (yeni yorumlar için)
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get(const GetOptions(source: Source.server));

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return ProductReview.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }
      return null;
    } catch (e) {
      debugPrint('Kullanıcı yorumu getirilirken hata oluştu: $e');
      return null;
    }
  }

  // Kullanıcının ürünü satın alıp almadığını kontrol et (OrderService kullanarak)
  static Future<bool> hasUserPurchasedProduct(String productId, String userId) async {
    try {
      // OrderService kullanarak kontrol et
      // Not: Bu metod OrderService'den çağrılabilir ama static metod olduğu için
      // direkt olarak OrderService'i import edip kullanacağız
      return await _checkUserPurchaseFromOrders(productId, userId);
    } catch (e) {
      debugPrint('Satın alma kontrolü yapılırken hata: $e');
      return false;
    }
  }

  // OrderService'den bağımsız kontrol metodu
  static Future<bool> _checkUserPurchaseFromOrders(String productId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        final orderData = doc.data();
        final status = orderData['status']?.toString().toLowerCase() ?? '';
        
        // Sadece teslim edilmiş veya onaylanmış siparişlerde kontrol yap
        if (status == 'delivered' || 
            status == 'teslim edildi' ||
            status == 'confirmed' ||
            status == 'onaylandı') {
          final products = orderData['products'] as List<dynamic>?;
          if (products != null) {
            for (var product in products) {
              // Product objesi olabilir veya Map olabilir
              if (product is Map<String, dynamic>) {
                if (product['id'] == productId || product['productId'] == productId) {
                  return true;
                }
              }
            }
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Satın alma kontrolü yapılırken hata: $e');
      return false;
    }
  }

  // Yorum ekle
  static Future<String?> addReview({
    required String productId,
    required int rating,
    required String comment,
    List<String>? imageUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Satın alma kontrolü - sadece sipariş verilen ürünlere yorum yapılabilir
      debugPrint('Satın alma kontrolü yapılıyor...');
      final hasPurchased = await hasUserPurchasedProduct(productId, user.uid);
      debugPrint('Satın alma durumu: $hasPurchased');
      
      if (!hasPurchased) {
        throw Exception('Bu ürünü satın almadığınız için yorum yapamazsınız. Lütfen önce ürünü satın alın.');
      }
      
      debugPrint('✓ Satın alma kontrolü geçildi');

      // Kullanıcının daha önce bu ürün için yorum yapıp yapmadığını kontrol et
      final existingReview = await getUserReviewForProduct(productId, user.uid);
      if (existingReview != null) {
        throw Exception('Bu ürün için zaten yorum yapmışsınız');
      }

      // Firestore'da review oluştur ve ID al
      final reviewData = {
        'productId': productId,
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonim Kullanıcı',
        'userEmail': user.email ?? '',
        'rating': rating,
        'comment': comment,
        'imageUrls': imageUrls ?? [],
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'isApproved': true, // Direkt onaylı olarak yayınla
        'isEdited': false,
      };

      debugPrint('Firestore\'a yorum ekleniyor...');
      debugPrint('Review Data: ${reviewData.toString()}');
      
      // Firestore'a ekle
      final docRef = await _firestore.collection(_collectionName).add(reviewData);
      final reviewId = docRef.id;
      
      debugPrint('✓ Yorum Firestore\'a eklendi! Review ID: $reviewId');
      
      // Eklenen yorumu hemen doğrula (Source.server ile - retry mekanizması ile)
      debugPrint('Eklenen yorum doğrulanıyor (Source.server - max 3 deneme)...');
      DocumentSnapshot? addedDoc;
      
      // Max 3 kez dene (Firestore propagation için)
      for (int attempt = 1; attempt <= 3; attempt++) {
        await Future.delayed(Duration(milliseconds: attempt * 300));
        try {
          addedDoc = await _firestore.collection(_collectionName).doc(reviewId).get(
            const GetOptions(source: Source.server),
          );
          
          if (addedDoc.exists) {
            debugPrint('✓ Yorum doğrulandı (deneme $attempt/3)');
            break;
          } else {
            debugPrint('⚠ Deneme $attempt/3: Yorum henüz görünmüyor...');
          }
        } catch (e) {
          debugPrint('⚠ Deneme $attempt/3 hatası: $e');
          if (attempt == 3) rethrow;
        }
      }
      
      if (addedDoc == null || !addedDoc.exists) {
        debugPrint('✗ UYARI: Yorum 3 denemede de görünmedi!');
        debugPrint('⚠ Yine de devam ediliyor, belki sonra görünür...');
        // Yine de reviewId döndür (belki sonra görünür)
      } else {
        final addedData = addedDoc.data()! as Map<String, dynamic>;
        debugPrint('✓ Eklenen yorum doğrulandı:');
        debugPrint('  - ID: $reviewId');
        debugPrint('  - Product ID: ${addedData['productId']}');
        debugPrint('  - isApproved: ${addedData['isApproved']}');
        debugPrint('  - Rating: ${addedData['rating']}');
        debugPrint('  - ImageUrls: ${(addedData['imageUrls'] as List?)?.length ?? 0} adet');
      }
      
      // Ürünün ortalama rating'ini güncelle (async - blocking yapma)
      _updateProductRating(productId).catchError((e) {
        debugPrint('Rating güncelleme hatası (non-blocking): $e');
      });
      
      return reviewId;
    } catch (e) {
      debugPrint('Yorum eklenirken hata oluştu: $e');
      rethrow;
    }
  }

  // Yorum güncelle
  static Future<bool> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
    List<String>? imageUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Yorumun kullanıcıya ait olup olmadığını kontrol et
      final reviewDoc = await _firestore.collection(_collectionName).doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw Exception('Yorum bulunamadı');
      }

      final reviewData = reviewDoc.data()!;
      if (reviewData['userId'] != user.uid) {
        throw Exception('Bu yorumu düzenleme yetkiniz yok');
      }

      final updateData = <String, dynamic>{
        'rating': rating,
        'comment': comment,
        'updatedAt': Timestamp.now(),
        'isEdited': true,
      };

      if (imageUrls != null) {
        updateData['imageUrls'] = imageUrls;
      }

      await _firestore.collection(_collectionName).doc(reviewId).update(updateData);

      // Ürünün ortalama rating'ini güncelle
      final productId = reviewData['productId'];
      if (productId != null) {
        await _updateProductRating(productId);
      }

      return true;
    } catch (e) {
      debugPrint('Yorum güncellenirken hata oluştu: $e');
      return false;
    }
  }

  // Sadece fotoğraf URL'lerini güncelle
  static Future<bool> updateReviewImages({
    required String reviewId,
    required List<String> imageUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Yorumun kullanıcıya ait olup olmadığını kontrol et (Source.server ile)
      final reviewDoc = await _firestore.collection(_collectionName).doc(reviewId).get(
        const GetOptions(source: Source.server),
      );
      if (!reviewDoc.exists) {
        throw Exception('Yorum bulunamadı');
      }

      final reviewData = reviewDoc.data()!;
      if (reviewData['userId'] != user.uid) {
        throw Exception('Bu yorumu düzenleme yetkiniz yok');
      }

      // Sadece imageUrls'i güncelle
      await _firestore.collection(_collectionName).doc(reviewId).update({
        'imageUrls': imageUrls,
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✓ Yorum fotoğrafları güncellendi! Review ID: $reviewId');
      debugPrint('  - Fotoğraf sayısı: ${imageUrls.length}');

      return true;
    } catch (e, stackTrace) {
      debugPrint('✗ Yorum fotoğrafları güncellenirken hata oluştu: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // Yorum sil
  static Future<bool> deleteReview(String reviewId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Yorumun kullanıcıya ait olup olmadığını kontrol et
      final reviewDoc = await _firestore.collection(_collectionName).doc(reviewId).get();
      if (!reviewDoc.exists) {
        throw Exception('Yorum bulunamadı');
      }

      final reviewData = reviewDoc.data()!;
      if (reviewData['userId'] != user.uid) {
        throw Exception('Bu yorumu silme yetkiniz yok');
      }

      await _firestore.collection(_collectionName).doc(reviewId).delete();

      // Ürünün ortalama rating'ini güncelle
      final productId = reviewData['productId'];
      if (productId != null) {
        await _updateProductRating(productId);
      }

      return true;
    } catch (e) {
      debugPrint('Yorum silinirken hata oluştu: $e');
      return false;
    }
  }

  // Admin: Yorum onayla/reddet
  // Not: Yeni yorumlar otomatik olarak onaylı (isApproved: true) olarak ekleniyor
  // Admin panelinde yorumları reddetmek veya tekrar onaylamak için kullanılabilir
  static Future<bool> approveReview(String reviewId, bool isApproved) async {
    try {
      await _firestore.collection(_collectionName).doc(reviewId).update({
        'isApproved': isApproved,
        'updatedAt': Timestamp.now(),
      });

      // Ürünün ortalama rating'ini güncelle
      final reviewDoc = await _firestore.collection(_collectionName).doc(reviewId).get();
      if (reviewDoc.exists) {
        final productId = reviewDoc.data()?['productId'];
        if (productId != null) {
          await _updateProductRating(productId);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Yorum onay durumu güncellenirken hata oluştu: $e');
      return false;
    }
  }

  // Admin: Yorum yanıtla
  static Future<bool> respondToReview({
    required String reviewId,
    required String adminResponse,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(reviewId).update({
        'adminResponse': adminResponse,
        'adminResponseDate': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Admin yanıtı eklenirken hata oluştu: $e');
      return false;
    }
  }

  // Admin: Tüm yorumları getir (onay bekleyenler dahil)
  static Future<List<ProductReview>> getAllReviews({bool? isApproved}) async {
    try {
      Query query = _firestore.collection(_collectionName);
      
      if (isApproved != null) {
        query = query.where('isApproved', isEqualTo: isApproved);
      }
      
      final querySnapshot = await query
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return ProductReview.fromJson({
              'id': doc.id,
              ...data,
            });
          })
          .toList();
    } catch (e) {
      debugPrint('Tüm yorumlar getirilirken hata oluştu: $e');
      return [];
    }
  }

  // Ürünün ortalama rating'ini güncelle
  static Future<void> _updateProductRating(String productId) async {
    try {
      final reviews = await getProductReviews(productId);
      final averageRating = ProductReview.calculateAverageRating(reviews);
      final totalReviews = reviews.length;

      // Ürünün rating bilgilerini güncelle
      await _firestore.collection('products').doc(productId).update({
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'lastRatingUpdate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Ürün rating güncellenirken hata oluştu: $e');
    }
  }

  // Kullanıcının tüm yorumlarını getir
  static Future<List<ProductReview>> getUserReviews(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductReview.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      debugPrint('Kullanıcı yorumları getirilirken hata oluştu: $e');
      return [];
    }
  }

  // En çok yorum alan ürünleri getir
  static Future<List<Map<String, dynamic>>> getTopRatedProducts({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .orderBy('averageRating', descending: true)
          .orderBy('totalReviews', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      debugPrint('En çok yorum alan ürünler getirilirken hata oluştu: $e');
      return [];
    }
  }
}
