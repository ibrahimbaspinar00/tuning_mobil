/// Firestore Quota Manager Kullanım Örnekleri
/// 
/// Bu dosya, FirestoreQuotaManager'ın nasıl kullanılacağını gösterir.
/// Gerçek servislerde bu örnekleri kullanarak quota yönetimini entegre edebilirsiniz.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_quota_manager.dart';

class FirestoreQuotaManagerExample {
  final FirestoreQuotaManager _quotaManager = FirestoreQuotaManager();

  /// Örnek 1: Güvenli get işlemi
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final snapshot = await _quotaManager.safeGet(
      collection: 'users',
      documentId: userId,
      useCache: true, // Cache kullan
    );

    return snapshot?.data() as Map<String, dynamic>?;
  }

  /// Örnek 2: Güvenli set işlemi
  Future<bool> saveUserProfile(String userId, Map<String, dynamic> data) async {
    return await _quotaManager.safeSet(
      collection: 'users',
      documentId: userId,
      data: data,
      merge: true, // Mevcut verileri koru
    );
  }

  /// Örnek 3: Güvenli query işlemi
  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    final snapshot = await _quotaManager.safeQuery(
      collection: 'orders',
      queryBuilder: (query) => query
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true),
      useCache: true,
      limit: 20, // Sadece son 20 sipariş
    );

    if (snapshot == null) return [];

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final result = Map<String, dynamic>.from(data);
      result['id'] = doc.id;
      return result;
    }).toList();
  }

  /// Örnek 4: Güvenli update işlemi
  Future<bool> updateOrderStatus(String orderId, String status) async {
    return await _quotaManager.safeUpdate(
      collection: 'orders',
      documentId: orderId,
      data: {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  /// Örnek 5: Güvenli add işlemi
  Future<String?> createOrder(Map<String, dynamic> orderData) async {
    return await _quotaManager.safeAdd(
      collection: 'orders',
      data: orderData,
    );
  }

  /// Örnek 6: Güvenli delete işlemi
  Future<bool> deleteOrder(String orderId) async {
    return await _quotaManager.safeDelete(
      collection: 'orders',
      documentId: orderId,
    );
  }

  /// Örnek 7: Özel işlem (custom operation)
  Future<List<Map<String, dynamic>>?> getProductsByCategory(String category) async {
    return await _quotaManager.safeFirestoreOperation<List<Map<String, dynamic>>>(
      operation: 'getProductsByCategory_$category',
      cacheKey: 'products_category_$category',
      useCache: true,
      fallbackValue: [],
      operationFn: () async {
        final snapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: category)
            .where('isActive', isEqualTo: true)
            .limit(50)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      },
    );
  }

  /// Örnek 8: Quota durumunu kontrol et
  void checkQuotaStatus() {
    if (_quotaManager.isQuotaExceeded) {
      print('⚠️ Firestore quota aşıldı!');
      print('Aşıldığı zaman: ${_quotaManager.quotaExceededAt}');
    } else {
      print('✅ Firestore quota normal');
    }

    // İstatistikleri al
    final stats = _quotaManager.getStats();
    print('İstatistikler: $stats');
  }

  /// Örnek 9: Cache'i temizle
  void clearCache() {
    _quotaManager.clearCache();
  }

  /// Örnek 10: Quota durumunu sıfırla (manuel)
  void resetQuotaStatus() {
    _quotaManager.resetQuotaStatus();
  }
}

/// Mevcut servislerde kullanım:
/// 
/// 1. WalletService'te:
///    - _saveToFirebase() metodunda safeSet kullan
///    - getWalletBalance() metodunda safeGet kullan
/// 
/// 2. OrderService'te:
///    - createOrder() metodunda safeAdd kullan
///    - getUserOrders() metodunda safeQuery kullan
///    - _updateProductStocks() metodunda safeUpdate kullan
/// 
/// 3. FirebaseDataService'te:
///    - Tüm Firestore işlemlerini safe* metodlarıyla değiştir
/// 
/// 4. ProductService'te:
///    - addProduct() metodunda safeAdd kullan
///    - updateProductStock() metodunda safeUpdate kullan

