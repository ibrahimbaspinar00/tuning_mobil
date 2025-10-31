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
    print('Debug: CollectionService - Getting collections for user: ${user?.uid}');
    
    if (user == null) {
      print('Debug: CollectionService - No user logged in, returning empty list');
      // Kullanıcı giriş yapmamışsa boş liste döndür
      return [];
    }

    try {
      // Offline-first approach - önce cache'den dene
      QuerySnapshot snapshot;
      try {
        snapshot = await _firestore
            .collection('collections')
            .where('userId', isEqualTo: user.uid)
            .orderBy('updatedAt', descending: true)
            .limit(50) // Daha fazla koleksiyon gösterebilir
            .get(const GetOptions(source: Source.serverAndCache));
      } catch (e) {
        // Server hatası olursa cache'den oku
        print('Debug: CollectionService - Server error, trying cache: $e');
        snapshot = await _firestore
            .collection('collections')
            .where('userId', isEqualTo: user.uid)
            .orderBy('updatedAt', descending: true)
            .limit(50)
            .get(const GetOptions(source: Source.cache));
      }
      
      print('Debug: CollectionService - Found ${snapshot.docs.length} collections');
      
      // Client-side parsing with error handling
      final collections = <Collection>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          final collection = Collection.fromMap(data);
          collections.add(collection);
        } catch (e) {
          print('Debug: CollectionService - Error parsing collection ${doc.id}: $e');
          // Hatalı dokümanı atla
          continue;
        }
      }

      // Zaten orderBy ile sıralanmış ama yine de sırala
      collections.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      print('Debug: CollectionService - Successfully parsed ${collections.length} collections');
      return collections;
    } catch (e) {
      print('Debug: CollectionService - Error getting collections: $e');
      // Hata durumunda boş liste döndür
      return [];
    }
  }

  // Yeni koleksiyon oluştur
  Future<String> createCollection(Collection collection) async {
    final user = _auth.currentUser;
    print('Debug: CollectionService - Current user: ${user?.uid}');
    
    if (user == null) {
      print('Debug: CollectionService - No user logged in, cannot create collection');
      throw Exception('Koleksiyon oluşturmak için giriş yapmalısınız');
    }

    print('Debug: CollectionService - Creating collection with ID: ${collection.id}');
    print('Debug: CollectionService - User ID: ${user.uid}');
    
    try {
      await _firestore
          .collection('collections')
          .doc(collection.id)
          .set(collection.toMap());
      
      print('Debug: CollectionService - Collection saved to Firestore');
      return collection.id;
    } catch (e) {
      print('Debug: CollectionService - Error saving to Firestore: $e');
      rethrow;
    }
  }

  // Koleksiyona ürün ekle
  Future<void> addProductToCollection(String collectionId, String productId, {String? productImageUrl}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    // Koleksiyon bilgilerini al
    final collectionDoc = await _firestore.collection('collections').doc(collectionId).get();
    if (!collectionDoc.exists) {
      throw Exception('Koleksiyon bulunamadı');
    }
    
    final collectionData = collectionDoc.data()!;
    final currentProductIds = List<String>.from(collectionData['productIds'] ?? []);
    final currentCoverImageUrl = collectionData['coverImageUrl'] as String?;
    
    // Eğer koleksiyon boşsa ve ürün imageUrl'i varsa, kapak fotoğrafı olarak ayarla
    Map<String, dynamic> updateData = {
      'productIds': FieldValue.arrayUnion([productId]),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    // Eğer koleksiyon boşsa ve kapak fotoğrafı yoksa, ilk ürünün fotoğrafını kapak yap
    if (currentProductIds.isEmpty && 
        (currentCoverImageUrl == null || currentCoverImageUrl.isEmpty) &&
        productImageUrl != null && productImageUrl.isNotEmpty) {
      updateData['coverImageUrl'] = productImageUrl;
      print('Debug: İlk ürün eklendi, kapak fotoğrafı ayarlandı: $productImageUrl');
    }

    await _firestore.collection('collections').doc(collectionId).update(updateData);
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

  // Koleksiyonu güncelle
  Future<void> updateCollection(Collection collection) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore
        .collection('collections')
        .doc(collection.id)
        .update(collection.toMap());
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
