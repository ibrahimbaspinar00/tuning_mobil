import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'utils/advanced_memory_manager.dart';
import 'theme/professional_theme.dart';

void main() {
  // CRITICAL: Non-blocking initialization for performance
  WidgetsFlutterBinding.ensureInitialized();
  
  // CRITICAL: Silent error handling for performance
  if (kDebugMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Silent error handling - no UI blocking
    };
  }
  
  // CRITICAL: Immediate app start
  runApp(const MyApp());
  
  // CRITICAL: Background initialization
  _initializeApp();
}

Future<void> _initializeApp() async {
  try {
    // CRITICAL: Ultra-fast initialization
    unawaited(_initializeFirebase());
    unawaited(_initializeTheme());
    unawaited(_initializeNotifications());
    
    // Memory management - background
    unawaited(_initializeMemory());
  } catch (e) {
    debugPrint('App initialization error: $e');
  }
}

Future<void> _initializeMemory() async {
  try {
    AdvancedMemoryManager.initialize();
  } catch (e) {
    debugPrint('Memory initialization error: $e');
  }
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Tuning Store',
            theme: ProfessionalTheme.lightTheme,
            darkTheme: ProfessionalTheme.darkTheme,
            home: const SplashScreen(),
            // Performance optimizations
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: 1.0, // Disable text scaling for performance
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}