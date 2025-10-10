import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'sayfalar/main_screen.dart';
import 'services/theme_service.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlat
  await Firebase.initializeApp();
  
  await ThemeService.loadTheme();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Tema yüklenene kadar loading göster
          if (!themeProvider.isInitialized) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }
          
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Tuning Store',
            theme: AppTheme.lightTheme,
            // darkTheme: AppTheme.darkTheme, // Koyu tema devre dışı
            // themeMode: themeProvider.themeMode, // Tema değiştirme devre dışı
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}
