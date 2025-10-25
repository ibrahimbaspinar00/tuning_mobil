import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/collection.dart';
import '../model/product.dart';

class CollectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcının koleksiyonlarını getir
  Future<List<Collection>> getUserCollections() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('collections')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return Collection.fromMap(doc.data());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Yeni koleksiyon oluştur
  Future<String> createCollection(Collection collection) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore
        .collection('collections')
        .doc(collection.id)
        .set(collection.toMap());

    return collection.id;
  }

  // Koleksiyona ürün ekle
  Future<void> addProductToCollection(String collectionId, String productId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore.collection('collections').doc(collectionId).update({
      'productIds': FieldValue.arrayUnion([productId]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Koleksiyondan ürün çıkar
  Future<void> removeProductFromCollection(String collectionId, String productId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore.collection('collections').doc(collectionId).update({
      'productIds': FieldValue.arrayRemove([productId]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Koleksiyonu sil
  Future<void> deleteCollection(String collectionId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore.collection('collections').doc(collectionId).delete();
  }

  // Koleksiyonun ürünlerini getir
  Future<List<Product>> getCollectionProducts(String collectionId) async {
    final doc = await _firestore.collection('collections').doc(collectionId).get();
    if (!doc.exists) return [];

    final collection = Collection.fromMap(doc.data()!);
    final products = <Product>[];

    for (final productId in collection.productIds) {
      try {
        final productDoc = await _firestore.collection('products').doc(productId).get();
        if (productDoc.exists) {
          final data = productDoc.data()!;
          products.add(Product(
            id: productId,
            name: data['name'] ?? '',
            description: data['description'] ?? '',
            price: (data['price'] ?? 0).toDouble(),
            imageUrl: data['imageUrl'] ?? '',
            category: data['category'] ?? 'Genel',
            stock: data['stock'] ?? 0,
            quantity: 1,
          ));
        }
      } catch (e) {
        // Ürün bulunamadı, devam et
      }
    }

    return products;
  }
}
