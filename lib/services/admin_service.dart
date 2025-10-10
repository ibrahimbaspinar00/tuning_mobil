import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../model/admin_product.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Ürün ekleme
  Future<String> addProduct(AdminProduct product) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('products')
          .add(product.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Ürün eklenirken hata oluştu: $e');
    }
  }

  // Ürün güncelleme
  Future<void> updateProduct(String productId, AdminProduct product) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update(product.toFirestore());
    } catch (e) {
      throw Exception('Ürün güncellenirken hata oluştu: $e');
    }
  }

  // Ürün silme
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .delete();
    } catch (e) {
      throw Exception('Ürün silinirken hata oluştu: $e');
    }
  }

  // Tüm ürünleri getirme
  Stream<List<AdminProduct>> getProducts() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdminProduct.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Tek ürün getirme
  Future<AdminProduct?> getProduct(String productId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('products')
          .doc(productId)
          .get();
      
      if (doc.exists) {
        return AdminProduct.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Ürün getirilirken hata oluştu: $e');
    }
  }

  // Stok güncelleme
  Future<void> updateStock(String productId, int newStock) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Stok güncellenirken hata oluştu: $e');
    }
  }

  // Stok artırma
  Future<void> increaseStock(String productId, int amount) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({
        'stock': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Stok artırılırken hata oluştu: $e');
    }
  }

  // Stok azaltma
  Future<void> decreaseStock(String productId, int amount) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({
        'stock': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Stok azaltılırken hata oluştu: $e');
    }
  }

  // Ürün durumu değiştirme (aktif/pasif)
  Future<void> toggleProductStatus(String productId, bool isActive) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ürün durumu güncellenirken hata oluştu: $e');
    }
  }

  // Resim yükleme
  Future<String> uploadImage(File imageFile, String productId) async {
    try {
      String fileName = 'products/$productId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Resim yüklenirken hata oluştu: $e');
    }
  }

  // Kategori ekleme
  Future<String> addCategory(ProductCategory category) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('categories')
          .add(category.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Kategori eklenirken hata oluştu: $e');
    }
  }

  // Kategorileri getirme
  Stream<List<ProductCategory>> getCategories() {
    return _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductCategory.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Ürün arama
  Stream<List<AdminProduct>> searchProducts(String query) {
    return _firestore
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdminProduct.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Kategoriye göre ürün getirme
  Stream<List<AdminProduct>> getProductsByCategory(String category) {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AdminProduct.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }
}
