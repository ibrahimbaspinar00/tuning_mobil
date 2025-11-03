import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase'de kullanıcı bazlı veri yönetimi için ana servis
class FirebaseDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı ID'sini al
  String? get _currentUserId => _auth.currentUser?.uid;

  // Kullanıcı verilerini kontrol et
  bool get _isUserLoggedIn => _currentUserId != null;

  // ==================== KULLANICI PROFİLİ ====================

  /// Kullanıcı profil bilgilerini kaydet
  Future<void> saveUserProfile({
    required String fullName,
    required String username,
    required String email,
    String? phone,
    String? address,
    String? profileImageUrl,
  }) async {
    if (!_isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore.collection('users').doc(_currentUserId).set({
      'fullName': fullName,
      'username': username,
      'email': email,
      'phone': phone ?? '',
      'address': address ?? '',
      'profileImageUrl': profileImageUrl ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Kullanıcı profil bilgilerini al
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!_isUserLoggedIn) return null;

    try {
      final doc = await _firestore.collection('users').doc(_currentUserId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // ==================== ADRESLER ====================

  /// Adres ekle
  Future<void> addAddress({
    required String title,
    required String fullName,
    required String phone,
    required String address,
    required String city,
    required String district,
    required String postalCode,
    bool isDefault = false,
  }) async {
    if (!_isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    final addressData = {
      'title': title,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'city': city,
      'district': district,
      'postalCode': postalCode,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('addresses')
        .add(addressData);
  }

  /// Adresleri al
  Future<List<Map<String, dynamic>>> getAddresses() async {
    if (!_isUserLoggedIn) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('addresses')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Adres güncelle
  Future<void> updateAddress(String addressId, Map<String, dynamic> addressData) async {
    if (!_isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('addresses')
        .doc(addressId)
        .update(addressData);
  }

  /// Adres sil
  Future<void> deleteAddress(String addressId) async {
    if (!_isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('addresses')
        .doc(addressId)
        .delete();
  }

  // ==================== ÖDEME YÖNTEMLERİ ====================

  /// Ödeme yöntemi ekle
  Future<void> addPaymentMethod({
    required String name,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardHolderName,
    bool isDefault = false,
  }) async {
    if (!_isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    final paymentData = {
      'name': name,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'cardHolderName': cardHolderName,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('paymentMethods')
        .add(paymentData);
  }

  /// Ödeme yöntemlerini al
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    if (!_isUserLoggedIn) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('paymentMethods')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Ödeme yöntemi sil
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    if (!_isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('paymentMethods')
        .doc(paymentMethodId)
        .delete();
  }

  // ==================== FAVORİLER ====================

  /// Ürünü favorilere ekle
  Future<void> addToFavorites(String productId) async {
    if (!_isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('favorites')
        .doc(productId)
        .set({
      'productId': productId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ürünü favorilerden çıkar
  Future<void> removeFromFavorites(String productId) async {
    if (!_isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('favorites')
        .doc(productId)
        .delete();
  }

  /// Favori ürünleri al
  Future<List<String>> getFavoriteProductIds() async {
    if (!_isUserLoggedIn) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('favorites')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  /// Ürün favori mi kontrol et
  Future<bool> isProductFavorite(String productId) async {
    if (!_isUserLoggedIn) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('favorites')
          .doc(productId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ==================== SEPET ====================

  /// Sepete ürün ekle
  Future<void> addToCart(String productId, int quantity) async {
    if (!_isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('cart')
        .doc(productId)
        .set({
      'productId': productId,
      'quantity': quantity,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sepetten ürün çıkar
  Future<void> removeFromCart(String productId) async {
    if (!_isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('cart')
        .doc(productId)
        .delete();
  }

  /// Sepet miktarını güncelle
  Future<void> updateCartQuantity(String productId, int quantity) async {
    if (!_isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    if (quantity <= 0) {
      await removeFromCart(productId);
    } else {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('cart')
          .doc(productId)
          .update({
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Sepet içeriğini al
  Future<List<Map<String, dynamic>>> getCartItems() async {
    if (!_isUserLoggedIn) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('cart')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Sepeti temizle
  Future<void> clearCart() async {
    if (!_isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    final batch = _firestore.batch();
    final cartSnapshot = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('cart')
        .get();

    for (final doc in cartSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ==================== SİPARİŞLER ====================

  /// Sipariş oluştur
  Future<String> createOrder({
    required Map<String, dynamic> orderData,
    required List<Map<String, dynamic>> orderItems,
  }) async {
    if (!_isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    final orderRef = await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('orders')
        .add({
      ...orderData,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    // Sipariş ürünlerini ekle
    for (final item in orderItems) {
      await orderRef.collection('items').add({
        ...item,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return orderRef.id;
  }

  /// Siparişleri al
  Future<List<Map<String, dynamic>>> getOrders() async {
    if (!_isUserLoggedIn) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Sipariş detayını al
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    if (!_isUserLoggedIn) return null;

    try {
      final orderDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) return null;

      final orderData = orderDoc.data()!;
      orderData['id'] = orderId;

      // Sipariş ürünlerini al
      final itemsSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('orders')
          .doc(orderId)
          .collection('items')
          .get();

      orderData['items'] = itemsSnapshot.docs.map((doc) {
        final itemData = doc.data();
        itemData['id'] = doc.id;
        return itemData;
      }).toList();

      return orderData;
    } catch (e) {
      return null;
    }
  }

  // ==================== KULLANICI İSTATİSTİKLERİ ====================

  /// Kullanıcı istatistiklerini al
  Future<Map<String, dynamic>> getUserStats() async {
    if (!_isUserLoggedIn) return {};

    try {
      // Toplam sipariş sayısı - orders koleksiyonundan userId ile çek
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: _currentUserId)
          .get();

      // Toplam harcama
      double totalSpent = 0;
      for (final order in ordersSnapshot.docs) {
        final orderData = order.data();
        totalSpent += (orderData['totalAmount'] ?? 0).toDouble();
      }

      // Sepet tutarı
      final cartSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('cart')
          .get();

      double cartTotal = 0;
      for (final item in cartSnapshot.docs) {
        final itemData = item.data();
        cartTotal += (itemData['price'] ?? 0).toDouble() * (itemData['quantity'] ?? 0);
      }

      // Favori sayısı
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('favorites')
          .get();

      return {
        'totalOrders': ordersSnapshot.docs.length,
        'totalSpent': totalSpent,
        'cartTotal': cartTotal,
        'favoriteCount': favoritesSnapshot.docs.length,
      };
    } catch (e) {
      return {};
    }
  }

  // ==================== VERİ YEDEKLEME ====================

  /// Kullanıcının tüm verilerini al (yedekleme için)
  Future<Map<String, dynamic>> exportUserData() async {
    if (!_isUserLoggedIn) return {};

    try {
      final userData = await getUserProfile();
      final addresses = await getAddresses();
      final paymentMethods = await getPaymentMethods();
      final favorites = await getFavoriteProductIds();
      final cartItems = await getCartItems();
      final orders = await getOrders();

      return {
        'userProfile': userData,
        'addresses': addresses,
        'paymentMethods': paymentMethods,
        'favorites': favorites,
        'cartItems': cartItems,
        'orders': orders,
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {};
    }
  }

  /// Kullanıcının tüm verilerini sil
  Future<void> deleteUserData() async {
    if (!_isUserLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    final batch = _firestore.batch();

    // Tüm alt koleksiyonları sil
    final collections = ['addresses', 'paymentMethods', 'favorites', 'cart', 'orders'];
    
    for (final collection in collections) {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection(collection)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }

    // Ana kullanıcı dökümanını sil
    batch.delete(_firestore.collection('users').doc(_currentUserId));

    await batch.commit();
  }
}
