import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'lib/firebase_options.dart';
import 'lib/web_admin/web_admin_main.dart' as admin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Bu dosya sadece web platformu için çalışır
  // Chrome'da çalıştırdığınızda admin paneli açılır
  if (kIsWeb) {
    // Web için admin paneli başlat
    runApp(admin.WebAdminApp());
  } else {
    // Bu durum teorik olarak gerçekleşmez çünkü bu dosya sadece web için
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Bu uygulama sadece web platformunda çalışır'),
          ),
        ),
      ),
    );
  }
}
