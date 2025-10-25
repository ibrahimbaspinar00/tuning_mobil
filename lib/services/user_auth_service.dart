import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;

  // Initialize service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Pre-load critical data
      await _preloadAuthData();
      _isInitialized = true;
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _preloadAuthData() async {
    // Pre-load current user if exists
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Pre-load user data
        await _firestore.collection('users').doc(user.uid).get();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Kullanıcı adı ile giriş yapma - Optimized with timeout
  Future<User?> signInWithUsername(String username, String password) async {
    try {
      // Önce kullanıcı adına karşılık gelen e-postayı bul - timeout ile
      final userDoc = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (userDoc.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Bu kullanıcı adı ile kayıtlı kullanıcı bulunamadı.',
        );
      }

      final userData = userDoc.docs.first.data();
      final email = userData['email'] as String?;

      if (email == null || email.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Kullanıcı e-posta bilgisi bulunamadı.',
        );
      }

      // E-posta ile giriş yap - timeout ile
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 10));

      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Kullanıcı adı ile kayıt olma
  Future<User?> signUpWithUsername(String fullName, String username, String email, String password) async {
    try {
      // Kullanıcı adının benzersiz olup olmadığını kontrol et
      final existingUser = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'username-already-in-use',
          message: 'Bu kullanıcı adı zaten kullanımda.',
        );
      }

      // E-posta adresinin benzersiz olup olmadığını kontrol et
      final existingEmail = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingEmail.docs.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Bu e-posta adresi zaten kullanımda.',
        );
      }

      // E-posta ile kayıt ol
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Kullanıcı adını güncelle
        await user.updateDisplayName(fullName);

        // Firestore'da kullanıcı bilgilerini sakla
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': fullName,
          'username': username,
          'email': email,
          'displayName': fullName,
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'user',
          'isActive': true,
        });
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Mevcut kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // Çıkış yapma
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Şifre sıfırlama
  Future<void> resetPassword(String username) async {
    try {
      // Kullanıcı adına karşılık gelen e-postayı bul
      final userDoc = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Bu kullanıcı adı ile kayıtlı kullanıcı bulunamadı.',
        );
      }

      final userData = userDoc.docs.first.data();
      final email = userData['email'] as String?;

      if (email == null || email.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Kullanıcı e-posta bilgisi bulunamadı.',
        );
      }

      // E-posta ile şifre sıfırlama
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Şifre sıfırlama e-postası gönderilirken hata oluştu: $e');
    }
  }

  // Kullanıcı adı kontrolü
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return userDoc.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  // Kullanıcı bilgilerini al
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      return userDoc.data();
    } catch (e) {
      return null;
    }
  }

  // Mevcut kullanıcıyı getir
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
