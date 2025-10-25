import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import '../utils/advanced_memory_manager.dart';
import '../sayfalar/main_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startLoadingSequence();
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
      // 1. Tema servisi
      _updateProgress(0.2, 'Tema yükleniyor...');
      await ThemeService.loadTheme();
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. Bildirim servisi
      _updateProgress(0.4, 'Bildirimler hazırlanıyor...');
      await NotificationService().initialize();
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Memory manager
      _updateProgress(0.6, 'Bellek optimizasyonu...');
      AdvancedMemoryManager.initialize();
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. Cache temizleme
      _updateProgress(0.8, 'Önbellek temizleniyor...');
      await _clearCaches();
      await Future.delayed(const Duration(milliseconds: 500));

      // 5. Son hazırlıklar
      _updateProgress(1.0, 'Hazır!');
      await Future.delayed(const Duration(milliseconds: 500));

      // Ana sayfaya geç
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Splash screen error: $e');
      // Hata durumunda da ana sayfaya geç
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
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
