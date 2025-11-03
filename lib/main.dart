import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'config/app_routes.dart';
import 'services/theme_service.dart';
import 'providers/theme_provider.dart';
import 'providers/app_state_provider.dart';
import 'utils/advanced_memory_manager.dart';
import 'utils/performance_optimizer.dart';
import 'utils/advanced_error_handler.dart';
import 'utils/advanced_cache_manager.dart';
import 'utils/network_manager.dart';
import 'theme/professional_theme.dart';
import 'services/campaign_notification_service.dart';
import 'services/enhanced_notification_service.dart';

/// Background message handler - Uygulama kapalıyken çalışır
/// Bu fonksiyon top-level olmalı (main dışında, class dışında)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase'i initialize et (background'da çalışıyoruz)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  debugPrint('📱 Background mesaj alındı: ${message.messageId}');
  debugPrint('📱 Mesaj başlığı: ${message.notification?.title}');
  debugPrint('📱 Mesaj içeriği: ${message.notification?.body}');
  
  // EnhancedNotificationService ile bildirimi göster
  final notificationService = EnhancedNotificationService();
  await notificationService.handleBackgroundMessage(message);
}

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
  WidgetsFlutterBinding.ensureInitialized();
  
  // Background message handler'ı kaydet (main() içinde - kritik!)
  // Bu, background handler'ın doğru şekilde çalışması için gerekli
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Error handling
  if (kDebugMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    };
    
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Platform Error: $error');
      debugPrint('Stack trace: $stack');
      return true;
    };
  }
  
  // Firebase initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    debugPrint('Firebase initialized successfully');
    
    // Firestore offline persistence'i devre dışı bırak (sadece online çalışsın)
    try {
      final firestore = FirebaseFirestore.instance;
      firestore.settings = const Settings(
        persistenceEnabled: false, // Offline persistence kapalı
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('Firestore offline persistence disabled');
    } catch (e) {
      debugPrint('Error disabling Firestore persistence: $e');
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  // Initialize app systems
  _optimizeApp();
  
  // Start app
  runApp(const MyApp());
  
  // Background initialization
  _initializeApp();
}

void _optimizeApp() {
  PerformanceOptimizer.initialize();
  GlobalErrorHandler.initialize();
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  
  // Image cache optimization
  PaintingBinding.instance.imageCache.maximumSize = 50;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 25 << 20; // 25MB
}

Future<void> _initializeApp() async {
  try {
    unawaited(_initializeTheme());
    unawaited(_initializeNotifications());
    unawaited(_initializeAdvancedSystems());
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
    // EnhancedNotificationService kullan (background desteği ile)
    await EnhancedNotificationService().initialize();
    debugPrint('Enhanced notification service initialized');
    
    // Kampanya bildirim servisini başlat
    CampaignNotificationService().start();
    debugPrint('Campaign notification service started');
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
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
            home: const SplashScreen(),
            builder: (context, child) {
              // Klavye performansı için builder'ı minimuma indir
              // MediaQuery'yi sadece bir kez al ve cache'le
              final media = MediaQuery.of(context);
              final width = media.size.width;
              final height = media.size.height;

              // Sabit scale değerleri - hesaplama optimize edildi
              final targetScale = width <= 320 || height <= 600 ? 0.88 :
                width <= 360 || height <= 680 ? 0.92 :
                width <= 375 ? 0.95 :
                width <= 414 ? 1.00 :
                width <= 600 ? 1.05 :
                width <= 900 ? 1.08 : 1.10;

              // Klavye performansı için minimum widget tree
              return RepaintBoundary(
                child: MediaQuery(
                  // viewInsets'i sıfırla - klavye açılışını hızlandır
                  data: media.copyWith(
                    textScaler: TextScaler.linear(targetScale),
                    viewInsets: EdgeInsets.zero, // Kritik: rebuild'leri önle
                    viewPadding: media.viewPadding, // Padding'i koru
                    padding: media.padding, // Padding'i koru
                  ),
                  child: child ?? const SizedBox(),
                ),
              );
            },
            showPerformanceOverlay: false,
            scrollBehavior: const AppScrollBehavior(),
          );
        },
      ),
    );
  }
}