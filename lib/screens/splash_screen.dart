import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import '../utils/advanced_memory_manager.dart';
import '../utils/network_manager.dart';
import '../config/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;

  double _progress = 0.0;
  String _loadingText = 'Uygulama başlatılıyor...';
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkInitialLink();
    _startLoadingSequence();
    _listenToDeepLinks();
  }

  /// Deep link dinle
  void _listenToDeepLinks() {
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });
  }

  /// İlk açılışta gelen deep link'i kontrol et
  Future<void> _checkInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleDeepLink(uri);
      }
    } catch (e) {
      debugPrint('Initial link check error: $e');
    }
  }

  /// Deep link'i işle
  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link alındı (SplashScreen): $uri');
    debugPrint('Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
    
    String? productId;
    
    // HTTPS formatında deep link (https://tuning-app-789ce.web.app/product/{productId})
    if ((uri.scheme == 'https' || uri.scheme == 'http') && 
        (uri.host == 'tuning-app-789ce.web.app' || uri.host.contains('tuning-app'))) {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'product') {
        if (uri.pathSegments.length > 1) {
          productId = uri.pathSegments[1];
          debugPrint('Got productId from HTTPS link: $productId');
        }
      }
    }
    // Custom scheme formatında deep link (tuningapp://product/{productId})
    else if (uri.scheme == 'tuningapp' && uri.host == 'product') {
      debugPrint('Full URI: $uri');
      debugPrint('Path segments: ${uri.pathSegments}');
      debugPrint('Path: ${uri.path}');
      debugPrint('Query params: ${uri.queryParameters}');
      
      // Önce pathSegments'i kontrol et (en güvenilir)
      if (uri.pathSegments.isNotEmpty) {
        productId = uri.pathSegments.first;
        debugPrint('Got productId from pathSegments: $productId');
      }
      // Path'ten al (tuningapp://product/123 formatı için)
      else if (uri.path.isNotEmpty && uri.path != '/') {
        productId = uri.path.replaceFirst('/', '').replaceAll('/', '').trim();
        debugPrint('Got productId from path: $productId');
      }
      // Query parametrelerinden al (tuningapp://product?id=123 formatı için)
      else if (uri.queryParameters.containsKey('id')) {
        productId = uri.queryParameters['id']!;
        debugPrint('Got productId from query: $productId');
      }
      // Authority'den al (product:productId formatında ise)
      else if (uri.authority.contains(':')) {
        productId = uri.authority.split(':').last;
        debugPrint('Got productId from authority: $productId');
      }
      
      debugPrint('Final extracted productId: "$productId"');
    }
    
    // ProductId bulunduysa yönlendir
    if (productId != null && productId.isNotEmpty && productId != 'product' && productId != '/') {
      debugPrint('✓ ProductId bulundu (SplashScreen): $productId');
      debugPrint('✓ Navigate işlemi başlatılıyor...');
      
      // Uygulama yüklendikten sonra ürün sayfasına git
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          debugPrint('✓ SplashScreen - Navigating to product: $productId');
          try {
            AppRoutes.navigateToProductDetailById(context, productId!);
            debugPrint('✓ SplashScreen - Navigate işlemi tamamlandı');
          } catch (e, stackTrace) {
            debugPrint('✗ SplashScreen - Navigate hatası: $e');
            debugPrint('Stack trace: $stackTrace');
          }
        } else {
          debugPrint('✗ SplashScreen - Widget unmounted, navigate yapılamadı');
        }
      });
    } else {
      debugPrint('✗ SplashScreen - Product ID bulunamadı veya geçersiz');
      debugPrint('  - productId: $productId');
    }
  }

  void _initializeAnimations() {
    // Logo animasyonu
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Text animasyonu
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Progress animasyonu
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Slide animasyonu
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutBack,
    ));
  }

  Future<void> _startLoadingSequence() async {
    // Animasyonları başlat
    _logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _progressController.forward();

    // Loading sequence
    await _loadApp();
  }

  Future<void> _loadApp() async {
    try {
      // 0. İnternet bağlantısı kontrolü (İLK ADIM)
      _updateProgress(0.1, 'İnternet bağlantısı kontrol ediliyor...');
      
      // NetworkManager'ı başlat
      await NetworkManager.instance.initialize();
      
      // Gerçek internet bağlantısını test et
      final hasInternet = await NetworkManager.instance.testInternetConnection();
      
      if (!hasInternet || !NetworkManager.instance.isOnline) {
        // İnternet yoksa hata göster ve uygulamayı başlatma
        if (mounted) {
          _showNoInternetError();
        }
        return;
      }
      
      await Future.delayed(const Duration(milliseconds: 300));

      // 1. Tema servisi
      _updateProgress(0.3, 'Tema yükleniyor...');
      await ThemeService.loadTheme();
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. Bildirim servisi
      _updateProgress(0.5, 'Bildirimler hazırlanıyor...');
      await NotificationService().initialize();
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Memory manager
      _updateProgress(0.7, 'Bellek optimizasyonu...');
      AdvancedMemoryManager.initialize();
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. Cache temizleme
      _updateProgress(0.9, 'Önbellek temizleniyor...');
      await _clearCaches();
      await Future.delayed(const Duration(milliseconds: 500));

      // 5. Son hazırlıklar
      _updateProgress(1.0, 'Hazır!');
      await Future.delayed(const Duration(milliseconds: 500));

      // İnternet kontrolü (son kez)
      final finalInternetCheck = await NetworkManager.instance.testInternetConnection();
      if (!finalInternetCheck || !NetworkManager.instance.isOnline) {
        if (mounted) {
          _showNoInternetError();
        }
        return;
      }

      // Ana sayfaya geç
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/main',
        );
      }
    } catch (e) {
      debugPrint('Splash screen error: $e');
      
      // Hata durumunda internet kontrolü yap
      final hasInternet = await NetworkManager.instance.testInternetConnection();
      if (!hasInternet || !NetworkManager.instance.isOnline) {
        if (mounted) {
          _showNoInternetError();
        }
        return;
      }
      
      // İnternet varsa ama başka bir hata varsa uygulamayı başlat
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    }
  }

  void _showNoInternetError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'İnternet Bağlantısı Gerekli',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Uygulama çalışması için internet bağlantısı gereklidir.\n\n'
            'Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Tekrar kontrol et
                final hasInternet = await NetworkManager.instance.testInternetConnection();
                if (hasInternet && NetworkManager.instance.isOnline) {
                  // İnternet varsa uygulamayı başlat
                  _loadApp();
                } else {
                  // Yoksa tekrar göster
                  if (mounted) {
                    _showNoInternetError();
                  }
                }
              },
              child: const Text('Tekrar Dene', style: TextStyle(fontSize: 16)),
            ),
            TextButton(
              onPressed: () {
                // Uygulamayı kapat
                SystemNavigator.pop();
              },
              child: const Text('Çıkış', style: TextStyle(fontSize: 16, color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _updateProgress(double progress, String text) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _loadingText = text;
      });
    }
  }

  Future<void> _clearCaches() async {
    // Image cache temizle
    await Future.delayed(const Duration(milliseconds: 200));
    // Diğer cache temizleme işlemleri
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo animasyonu
                      AnimatedBuilder(
                        animation: _logoAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _logoAnimation.value,
                            child: Transform.rotate(
                              angle: _logoAnimation.value * 0.1,
                              child: Container(
                                width: isSmallScreen ? 120 : 150,
                                height: isSmallScreen ? 120 : 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF2E7D32),
                                      Color(0xFF1B5E20),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.shopping_cart,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // App name animasyonu
                      AnimatedBuilder(
                        animation: _textAnimation,
                        builder: (context, child) {
                          return SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _textAnimation,
                              child: Column(
                                children: [
                                  Text(
                                    'TUNING STORE',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 24 : 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Premium E-Ticaret Deneyimi',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      color: Colors.white70,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Progress section
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _progressAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _progressAnimation,
                        curve: Curves.easeOutBack,
                      )),
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          children: [
                            // Progress bar
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: AnimatedBuilder(
                                animation: _progressController,
                                builder: (context, child) {
                                  return LinearProgressIndicator(
                                    value: _progress,
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.green.withOpacity(0.8),
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Loading text
                            Text(
                              _loadingText,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            
                            const SizedBox(height: 10),
                            
                            // Loading indicator
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
