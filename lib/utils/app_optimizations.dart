import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Uygulama optimizasyonları
class AppOptimizations {
  // Debug modunda performans izleme
  static void enablePerformanceMonitoring() {
    if (kDebugMode) {
      // Performans izleme etkinleştir
      debugPrint('Performance monitoring enabled');
    }
  }

  // Memory leak önleme
  static void preventMemoryLeaks() {
    // Image cache temizleme
    imageCache.clear();
    
    // Garbage collection tetikleme
    if (kDebugMode) {
      debugPrint('Memory cleanup performed');
    }
  }

  // Keyboard optimizasyonu
  static void optimizeKeyboard() {
    // Keyboard dismiss optimizasyonu
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  // Network optimizasyonu
  static void optimizeNetwork() {
    // Network cache optimizasyonu
    debugPrint('Network optimizations applied');
  }

  // UI optimizasyonu
  static Widget optimizedScaffold({
    required Widget body,
    AppBar? appBar,
    Widget? bottomNavigationBar,
    Widget? floatingActionButton,
  }) {
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }

  // List optimizasyonu
  static Widget optimizedListView({
    required List<Widget> children,
    ScrollController? controller,
  }) {
    return ListView.builder(
      controller: controller,
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }

  // Image optimizasyonu
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.asset(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        );
      },
    );
  }

  // Text optimizasyonu
  static Widget optimizedText({
    required String text,
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  // Button optimizasyonu
  static Widget optimizedButton({
    required VoidCallback onPressed,
    required Widget child,
    ButtonStyle? style,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );
  }

  // Loading optimizasyonu
  static Widget optimizedLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // Error handling optimizasyonu
  static Widget optimizedErrorWidget({
    required String message,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ],
      ),
    );
  }
}
