import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/no_overflow.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/error_handler.dart';
import '../services/user_auth_service.dart';
import '../config/app_routes.dart';

class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({super.key});

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userAuthService = UserAuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isInitialized = false;
  DateTime? _lastSignInAttempt;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    if (_isInitialized) return;
    
    // Pre-load critical data
    await _preloadData();
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _preloadData() async {
    // Pre-load user auth service
    try {
      // Initialize auth service
      await _userAuthService.initialize();
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    // Prevent rapid successive attempts
    final now = DateTime.now();
    if (_lastSignInAttempt != null && 
        now.difference(_lastSignInAttempt!).inSeconds < 2) {
      return;
    }
    _lastSignInAttempt = now;

    // Prevent duplicate operations
    if (_isLoading) return;
    
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Network bağlantısını kontrol et - timeout ile
      final connectivityResult = await Connectivity().checkConnectivity()
          .timeout(const Duration(seconds: 5));
      
      if (connectivityResult.contains(ConnectivityResult.none)) {
        if (mounted) {
          ErrorHandler.showError(context, 'İnternet bağlantınızı kontrol edin. Giriş yapabilmek için internet bağlantısı gereklidir.');
        }
        return;
      }

      // Giriş işlemini timeout ile sınırla
      final user = await _userAuthService.signInWithUsername(
        _emailController.text.trim(),
        _passwordController.text,
      ).timeout(const Duration(seconds: 15));

      if (user != null && mounted) {
        Navigator.pop(context, true); // true değeri ile giriş başarılı olduğunu belirt
        ErrorHandler.showSuccess(context, 'Giriş başarılı! Hoş geldiniz!');
      } else if (mounted) {
        ErrorHandler.showError(context, 'Giriş yapılamadı. Lütfen bilgilerinizi kontrol edin.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'Bu kullanıcı adı ile kayıtlı kullanıcı bulunamadı.';
            break;
          case 'wrong-password':
            errorMessage = 'Hatalı şifre girdiniz.';
            break;
          case 'invalid-email':
            errorMessage = 'Geçersiz kullanıcı adı.';
            break;
          case 'user-disabled':
            errorMessage = 'Bu hesap devre dışı bırakılmış.';
            break;
          case 'too-many-requests':
            errorMessage = 'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin.';
            break;
          case 'invalid-credential':
            errorMessage = 'Kullanıcı adı veya şifre hatalı.';
            break;
          case 'network-request-failed':
            errorMessage = 'İnternet bağlantınızı kontrol edin.';
            break;
          default:
            errorMessage = 'Giriş yapılırken hata oluştu: ${e.message}';
        }
        ErrorHandler.showError(context, errorMessage);
      }
    } on TimeoutException {
      if (mounted) {
        ErrorHandler.showError(context, 'Giriş işlemi zaman aşımına uğradı. Lütfen tekrar deneyin.');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Beklenmeyen bir hata oluştu: $e';
        if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'İnternet bağlantınızı kontrol edin.';
        }
        ErrorHandler.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ErrorHandler.showError(context, 'Lütfen kullanıcı adınızı girin');
      return;
    }

    try {
      // Network bağlantısını kontrol et
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        if (mounted) {
          ErrorHandler.showError(context, 'İnternet bağlantınızı kontrol edin. Şifre sıfırlama için internet bağlantısı gereklidir.');
        }
        return;
      }

      await _userAuthService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Şifre sıfırlama e-postası gönderildi!');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Şifre sıfırlama hatası: $e';
        if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = 'İnternet bağlantınızı kontrol edin.';
        }
        ErrorHandler.showError(context, errorMessage);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
    
    // Show loading screen until initialized
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      resizeToAvoidBottomInset: false, // Klavye performansı için
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[800]!,
              Colors.purple[700]!,
              Colors.indigo[600]!,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: NoOverflow(
          padding: const EdgeInsets.all(20),
          child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo ve başlık
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.storefront,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tuning Store',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hesabınıza Giriş Yapın',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Giriş formu
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Giriş Bilgileri',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Kullanıcı adı ve şifrenizi girin',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        
                        // Kullanıcı adı alanı
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Kullanıcı Adı',
                            hintText: 'kullanici_adi',
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.person, color: Colors.blue[600], size: 20),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Kullanıcı adı gerekli';
                            }
                            if (value.length < 3) {
                              return 'Kullanıcı adı en az 3 karakter olmalı';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Şifre alanı
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            hintText: 'Şifrenizi girin',
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.lock, color: Colors.red[600], size: 20),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Şifre gerekli';
                            }
                            if (value.length < 6) {
                              return 'Şifre en az 6 karakter olmalı';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // Şifremi Unuttum butonu
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: Text(
                              'Şifremi Unuttum',
                              style: TextStyle(
                                color: Colors.purple[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Giriş butonu
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue[600]!,
                                Colors.purple[600]!,
                                Colors.indigo[600]!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.purple.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.login,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Giriş Yap',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Kayıt ol bölümü
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_add,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Yeni Hesap Oluşturun',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hesabınız yok mu? Hemen kayıt olun ve alışverişe başlayın!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green[600]!,
                              Colors.teal[600]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            AppRoutes.navigateToRegister(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.app_registration,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Kayıt Ol',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
    );
  }
}
