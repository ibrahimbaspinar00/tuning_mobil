import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase debug ve test utility sınıfı
class FirebaseDebug {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tüm kullanıcıları listele
  static Future<void> listAllUsers() async {
    try {
      print('=== FIREBASE DEBUG: Tüm Kullanıcılar ===');
      
      // Firestore'daki kullanıcıları listele
      final usersSnapshot = await _firestore.collection('users').get();
      print('Firestore Users (${usersSnapshot.docs.length}):');
      
      for (var doc in usersSnapshot.docs) {
        print('  - ID: ${doc.id}');
        print('    Data: ${doc.data()}');
        print('    Username: ${doc.data()['username']}');
        print('    Email: ${doc.data()['email']}');
        print('    FullName: ${doc.data()['fullName']}');
        print('    ---');
      }
      
      // Firebase Auth kullanıcılarını listele
      print('Firebase Auth Current User:');
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('  - UID: ${currentUser.uid}');
        print('  - Email: ${currentUser.email}');
        print('  - DisplayName: ${currentUser.displayName}');
      } else {
        print('  - No current user');
      }
      
    } catch (e) {
      print('Firebase Debug Error: $e');
    }
  }

  // Belirli kullanıcı adını kontrol et
  static Future<void> checkUsername(String username) async {
    try {
      print('=== Kullanıcı Adı Kontrolü: $username ===');
      
      final userDoc = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      print('Bulunan doküman sayısı: ${userDoc.docs.length}');
      
      if (userDoc.docs.isNotEmpty) {
        final doc = userDoc.docs.first;
        print('Kullanıcı bulundu:');
        print('  - ID: ${doc.id}');
        print('  - Data: ${doc.data()}');
      } else {
        print('Kullanıcı bulunamadı');
      }
      
    } catch (e) {
      print('Username Check Error: $e');
    }
  }

  // Test kullanıcısı oluştur
  static Future<void> createTestUser() async {
    try {
      print('=== Test Kullanıcısı Oluşturuluyor ===');
      
      final testData = {
        'fullName': 'Test User',
        'username': 'testuser',
        'email': 'test@example.com',
        'displayName': 'Test User',
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      // Test dokümanı oluştur
      await _firestore.collection('users').doc('test_user_id').set(testData);
      print('Test kullanıcısı oluşturuldu');
      
    } catch (e) {
      print('Test User Creation Error: $e');
    }
  }

  // Tüm kullanıcıları temizle (DİKKAT: Bu tüm verileri siler!)
  static Future<void> clearAllUsers() async {
    try {
      print('=== TÜM KULLANICILAR TEMİZLENİYOR ===');
      
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var doc in usersSnapshot.docs) {
        await doc.reference.delete();
        print('Silinen: ${doc.id}');
      }
      
      print('Tüm kullanıcılar temizlendi');
      
    } catch (e) {
      print('Clear Users Error: $e');
    }
  }

  // Firestore bağlantısını test et
  static Future<void> testFirestoreConnection() async {
    try {
      print('=== Firestore Bağlantı Testi ===');
      
      // Basit bir test dokümanı oluştur
      await _firestore.collection('test').doc('connection_test').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firestore bağlantısı başarılı',
      });
      
      print('Firestore bağlantısı başarılı');
      
      // Test dokümanını sil
      await _firestore.collection('test').doc('connection_test').delete();
      print('Test dokümanı temizlendi');
      
    } catch (e) {
      print('Firestore Connection Error: $e');
    }
  }
}
