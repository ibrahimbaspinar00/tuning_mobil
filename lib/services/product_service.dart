import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../model/product.dart';
import '../model/product_review.dart';

/// Ürün yönetimi için ana servis
class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı ID'sini al
  String? get _currentUserId => _auth.currentUser?.uid;

  // ==================== ÜRÜN YÖNETİMİ ====================

  /// Tüm ürünleri getir (Stream - anlık güncelleme)
  Stream<List<Product>> getAllProductsStream() {
    try {
      return _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .limit(50) // Limit ekleyerek performansı artır
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            final data = doc.data();
            data['id'] = doc.id;
            return Product.fromMap(data);
          } catch (e) {
            debugPrint('Error parsing product ${doc.id}: $e');
            return null;
          }
        }).where((product) => product != null).cast<Product>().toList();
      });
    } catch (e) {
      debugPrint('Error getting products stream: $e');
      // Hata durumunda boş stream döndür
      return Stream.value([]);
    }
  }

  /// Tüm ürünleri getir
  Future<List<Product>> getAllProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .limit(50) // Limit ekleyerek performansı artır
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting products: $e');
      return _getDummyProducts();
    }
  }

  /// Kategoriye göre ürünleri getir
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .limit(30) // Limit ekleyerek performansı artır
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting products by category: $e');
      return _getDummyProducts().where((p) => p.category == category).toList();
    }
  }

  /// Ürün detayını getir
  Future<Product?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Product.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting product: $e');
      return _getDummyProducts().firstWhere((p) => p.id == productId);
    }
  }

  /// Ürün ara
  Future<List<Product>> searchProducts(String query) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();

      // Client-side filtering for better performance
      return products.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
               product.description.toLowerCase().contains(query.toLowerCase()) ||
               product.category.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      debugPrint('Error searching products: $e');
      return _getDummyProducts().where((p) => 
        p.name.toLowerCase().contains(query.toLowerCase()) ||
        p.description.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  /// Popüler ürünleri getir - En çok alınan ve yorumu yüksek olan ürünler
  Future<List<Product>> getPopularProducts({int limit = 10}) async {
    try {
      // Offline-first approach
      final snapshot = await _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .limit(50) // Daha fazla ürün al ki sıralama daha iyi olsun
          .get();

      // Client-side sorting for better performance
      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();

      // Popülerlik skorunu hesapla (satış sayısı + yorum sayısı + ortalama puan)
      products.sort((a, b) {
        // Popülerlik skoru = satış sayısı * 0.4 + yorum sayısı * 0.3 + ortalama puan * 10 * 0.3
        final scoreA = (a.salesCount * 0.4) + (a.reviewCount * 0.3) + (a.averageRating * 10 * 0.3);
        final scoreB = (b.salesCount * 0.4) + (b.reviewCount * 0.3) + (b.averageRating * 10 * 0.3);
        
        return scoreB.compareTo(scoreA);
      });
      
      return products.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting popular products: $e');
      return _getDummyProducts().take(limit).toList();
    }
  }

  /// Yeni ürünleri getir
  Future<List<Product>> getNewProducts({int limit = 10}) async {
    try {
      // Offline-first approach
      final snapshot = await _firestore
          .collection('products')
          .limit(limit)
          .get();

      // Client-side sorting for better performance
      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();

      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting new products: $e');
      return _getDummyProducts().take(limit).toList();
    }
  }

  /// İndirimli ürünleri getir
  Future<List<Product>> getDiscountedProducts() async {
    try {
      // Offline-first approach
      final snapshot = await _firestore
          .collection('products')
          .limit(20) // Küçük limit
          .get();

      // Client-side filtering and sorting for better performance
      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();

      final discountedProducts = products.where((p) => p.discountPercentage > 0).toList();
      discountedProducts.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
      return discountedProducts;
    } catch (e) {
      debugPrint('Error getting discounted products: $e');
      return _getDummyProducts().where((p) => p.discountPercentage > 0).toList();
    }
  }

  /// Ürün stok durumunu güncelle
  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating product stock: $e');
    }
  }

  /// Ürün satış sayısını artır
  Future<void> incrementProductSales(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'salesCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error incrementing product sales: $e');
    }
  }

  // ==================== ÜRÜN YORUMLARI ====================

  /// Ürün yorumlarını getir
  Future<List<ProductReview>> getProductReviews(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProductReview.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting product reviews: $e');
      return [];
    }
  }

  /// Ürün yorumu ekle
  Future<void> addProductReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    if (_currentUserId == null) throw Exception('Kullanıcı giriş yapmamış');

    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .add({
        'userId': _currentUserId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Ürünün ortalama puanını güncelle
      await _updateProductAverageRating(productId);
    } catch (e) {
      debugPrint('Error adding product review: $e');
    }
  }

  /// Ürünün ortalama puanını güncelle
  Future<void> _updateProductAverageRating(String productId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .get();

      if (reviewsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      for (final doc in reviewsSnapshot.docs) {
        totalRating += (doc.data()['rating'] ?? 0).toDouble();
      }

      final averageRating = totalRating / reviewsSnapshot.docs.length;

      await _firestore.collection('products').doc(productId).update({
        'averageRating': averageRating,
        'reviewCount': reviewsSnapshot.docs.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating product average rating: $e');
    }
  }

  // ==================== KATEGORİLER ====================

  /// Tüm kategorileri getir
  Future<List<String>> getAllCategories() async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return _getDummyCategories();
    }
  }

  /// Kategori detayını getir
  Future<Map<String, dynamic>?> getCategoryDetails(String categoryName) async {
    try {
      final doc = await _firestore
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        final data = doc.docs.first.data();
        data['id'] = doc.docs.first.id;
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting category details: $e');
      return null;
    }
  }

  // ==================== DUMMY DATA ====================

  /// Demo ürünleri getir
  List<Product> _getDummyProducts() {
    return [
      Product(
        id: '1',
        name: 'Premium Araç Temizlik Bezi',
        description: 'Yüksek kaliteli mikrofiber araç temizlik bezi. Çizik bırakmaz ve su emme kapasitesi yüksek.',
        price: 25.99,
        imageUrl: 'assets/images/placeholder.txt',
        category: 'Araç Temizlik',
        stock: 50,
        discountPercentage: 10,
        averageRating: 4.8,
        reviewCount: 156,
        salesCount: 450,
      ),
      Product(
        id: '2',
        name: 'Araç İçi Hava Temizleyici',
        description: 'Araç içindeki kötü kokuları gideren, doğal içerikli hava temizleyici sprey.',
        price: 18.50,
        imageUrl: 'assets/images/placeholder.txt',
        category: 'Araç Temizlik',
        stock: 30,
        discountPercentage: 0,
        averageRating: 4.2,
        reviewCount: 89,
        salesCount: 234,
      ),
      Product(
        id: '3',
        name: 'Telefon Tutucu',
        description: 'Araçta telefonunuzu güvenli şekilde tutan, 360 derece dönebilen tutucu.',
        price: 35.00,
        imageUrl: 'assets/images/placeholder.txt',
        category: 'Telefon Aksesuar',
        stock: 100,
        discountPercentage: 15,
        averageRating: 4.9,
        reviewCount: 287,
        salesCount: 678,
      ),
      Product(
        id: '4',
        name: 'Araç Kokusu',
        description: 'Uzun süreli etkili araç kokusu. Doğal içerikli ve sağlıklı.',
        price: 12.99,
        imageUrl: 'assets/images/placeholder.txt',
        category: 'Araç Temizlik',
        stock: 75,
        discountPercentage: 20,
        averageRating: 4.6,
        reviewCount: 198,
        salesCount: 567,
      ),
      Product(
        id: '5',
        name: 'Araç Şarj Cihazı',
        description: 'Hızlı şarj destekli araç şarj cihazı. USB-C ve USB-A çıkışları.',
        price: 45.99,
        imageUrl: 'assets/images/placeholder.txt',
        category: 'Elektronik',
        stock: 40,
        discountPercentage: 5,
        averageRating: 4.7,
        reviewCount: 134,
        salesCount: 389,
      ),
      Product(
        id: '6',
        name: 'Araç Halısı',
        description: 'Su geçirmez araç halısı. Kolay temizlenir ve dayanıklı.',
        price: 29.99,
        imageUrl: 'assets/images/placeholder.txt',
        category: 'Araç Aksesuar',
        stock: 60,
        discountPercentage: 0,
        averageRating: 4.4,
        reviewCount: 67,
        salesCount: 198,
      ),
      Product(
        id: '7',
        name: 'Araç Kamerası',
        description: '4K çözünürlüklü araç kamerası. Gece görüş özellikli.',
        price: 199.99,
        imageUrl: 'assets/images/placeholder.txt',
        category: 'Güvenlik',
        stock: 25,
        discountPercentage: 10,
        averageRating: 4.9,
        reviewCount: 312,
        salesCount: 789,
      ),
      Product(
        id: '8',
        name: 'Araç Temizlik Seti',
        description: 'Komplet araç temizlik seti. Tüm gerekli malzemeler dahil.',
        price: 89.99,
        imageUrl: 'assets/images/placeholder.txt',
        category: 'Araç Temizlik',
        stock: 45,
        discountPercentage: 15,
        averageRating: 4.8,
        reviewCount: 245,
        salesCount: 623,
      ),
    ];
  }

  /// Demo kategorileri getir
  List<String> _getDummyCategories() {
    return [
      'Araç Temizlik',
      'Telefon Aksesuar',
      'Elektronik',
      'Araç Aksesuar',
      'Güvenlik',
      'Performans',
    ];
  }
}
