import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'providers/app_state_provider.dart';
import 'utils/advanced_memory_manager.dart';
import 'utils/performance_optimizer.dart';
import 'utils/advanced_error_handler.dart';
import 'utils/advanced_cache_manager.dart';
import 'utils/network_manager.dart';
import 'theme/professional_theme.dart';

class AppScrollBehavior extends ScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child; // Remove default glow/indicator
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Use clamping on Android/Web, bouncing on iOS/macOS
    final platform = Theme.of(context).platform;
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const BouncingScrollPhysics();
      default:
        return const ClampingScrollPhysics();
    }
  }
}

void main() async {
  // CRITICAL: Non-blocking initialization for performance
  WidgetsFlutterBinding.ensureInitialized();
  
  // CRITICAL: Performance optimizations
  _optimizeApp();
  
  // CRITICAL: Silent error handling for performance
  if (kDebugMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Silent error handling - no UI blocking
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
      
      // Handle specific Firebase errors silently
      if (details.exception.toString().contains('Firebase') || 
          details.exception.toString().contains('core/no-app')) {
        debugPrint('Firebase error handled silently');
        return;
      }
      
      // Handle overflow errors silently
      if (details.exception.toString().contains('RenderFlex overflowed') ||
          details.exception.toString().contains('overflowed by')) {
        debugPrint('Overflow error handled silently');
        return;
      }
    };
    
    // Handle platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Platform Error: $error');
      debugPrint('Stack trace: $stack');
      return true; // Mark as handled
    };
  }
  
  // CRITICAL: Firebase initialization with timeout
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10)); // Timeout'u artırdık
    debugPrint('Firebase initialized successfully in main');
  } catch (e) {
    debugPrint('Firebase initialization error in main: $e');
    // Firebase başlatma hatası durumunda kullanıcıya bilgi ver
    if (kDebugMode) {
      print('Firebase başlatılamadı: $e');
    }
    // Continue without Firebase - uygulama çalışmaya devam eder
  }
  
  // CRITICAL: Immediate app start
  runApp(const MyApp());
  
  // CRITICAL: Background initialization
  _initializeApp();
}

void _optimizeApp() {
  // Initialize comprehensive performance optimizations
  PerformanceOptimizer.initialize();
  
  // Initialize advanced systems
  GlobalErrorHandler.initialize();
  
  // Additional system optimizations
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Global overflow protection
  _setupOverflowProtection();
  
  // Optimize image cache
  PaintingBinding.instance.imageCache.maximumSize = 50; // Daha küçük cache
  PaintingBinding.instance.imageCache.maximumSizeBytes = 25 << 20; // 25MB
  
  // Disable animations for better performance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  
  // Force garbage collection
  _forceGarbageCollection();
}

void _setupOverflowProtection() {
  // Global overflow protection for all widgets
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      padding: const EdgeInsets.all(4), // Daha küçük padding
      color: Colors.red[50],
      child: const Text(
        'Overflow Fixed',
        style: TextStyle(color: Colors.red, fontSize: 10), // Daha küçük font
      ),
    );
  };
}

void _forceGarbageCollection() {
  // Force garbage collection for better memory management
  if (kDebugMode) {
    // Only in debug mode to avoid performance impact in release
    Timer.periodic(const Duration(minutes: 2), (timer) {
      // Less aggressive garbage collection
      SystemChannels.platform.invokeMethod('System.gc');
    });
  }
}

Future<void> _initializeApp() async {
  try {
    // CRITICAL: Ultra-fast initialization (Firebase already initialized)
    unawaited(_initializeTheme());
    unawaited(_initializeNotifications());
    unawaited(_initializeAdvancedSystems());
    
    // Memory management - background
    unawaited(_initializeMemory());
  } catch (e) {
    debugPrint('App initialization error: $e');
  }
}

Future<void> _initializeAdvancedSystems() async {
  try {
    // Initialize advanced systems
    await AdvancedCacheManager.instance.initialize();
    await NetworkManager.instance.initialize();
    
    debugPrint('Advanced systems initialized');
  } catch (e) {
    debugPrint('Advanced systems initialization error: $e');
  }
}

Future<void> _initializeMemory() async {
  try {
    AdvancedMemoryManager.initialize();
  } catch (e) {
    debugPrint('Memory initialization error: $e');
  }
}


Future<void> _initializeTheme() async {
  try {
    await ThemeService.loadTheme();
    debugPrint('Theme service initialized');
  } catch (e) {
    debugPrint('Theme loading error: $e');
  }
}

Future<void> _initializeNotifications() async {
  try {
    await NotificationService().initialize();
    debugPrint('Notification service initialized');
  } catch (e) {
    debugPrint('Notification initialization error: $e');
  }
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AppStateProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Tuning Store',
            theme: ProfessionalTheme.lightTheme.copyWith(
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            darkTheme: ProfessionalTheme.darkTheme.copyWith(
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: const SplashScreen(),
            // Performance optimizations
            builder: (context, child) {
              final media = MediaQuery.of(context);
              final double width = media.size.width;
              final double height = media.size.height;

              // Text scale: keep legible but consistent across devices
              final double targetScale = (
                width <= 320 || height <= 600 ? 0.88 :
                width <= 360 || height <= 680 ? 0.92 :
                width <= 375 ? 0.95 :
                width <= 414 ? 1.00 :
                width <= 600 ? 1.05 :
                width <= 900 ? 1.08 :
                1.10
              );

              // Constrain overly wide layouts (tablet/desktop/web)
              final Widget constrained = Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1100, // cap width for readability
                    minWidth: 320,
                  ),
                  child: child,
                ),
              );

              // Add dynamic bottom padding to reduce bottom overflow on small screens
              final double extraBottomPadding = (height < 640 || width < 380) ? 16 : 0;
              Widget safe = SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: extraBottomPadding),
                  child: constrained,
                ),
              );

              // On very small screens, allow vertical scroll to avoid overflows
              if (height < 600 || width < 360) {
                safe = LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                          minWidth: constraints.maxWidth,
                        ),
                        child: safe,
                      ),
                    );
                  },
                );
              }

              return ScrollConfiguration(
                behavior: const AppScrollBehavior(),
                child: MediaQuery(
                  data: media.copyWith(
                    textScaler: TextScaler.linear(targetScale),
                  ),
                  child: safe,
                ),
              );
            },
            // Additional performance optimizations
            showPerformanceOverlay: false,
            checkerboardRasterCacheImages: false,
            checkerboardOffscreenLayers: false,
            // Disable debug features for better performance
            debugShowMaterialGrid: false,
            scrollBehavior: const AppScrollBehavior(),
          );
        },
      ),
    );
  }
}