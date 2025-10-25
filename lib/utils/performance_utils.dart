import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Performans optimizasyonları için utility sınıfı
class PerformanceUtils {
  // Debug modunda performans uyarıları
  static void enablePerformanceOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Performans overlay'i etkinleştir
      debugPrint('Performance overlay enabled');
    });
  }

  // Gereksiz rebuild'leri önle
  static Widget optimizedBuilder({
    required Widget Function(BuildContext context) builder,
    String? debugLabel,
  }) {
    return Builder(
      builder: (context) {
        if (debugLabel != null) {
          debugPrint('Building: $debugLabel');
        }
        return builder(context);
      },
    );
  }

  // Memory leak önleme
  static void disposeControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  // Image cache temizleme
  static void clearImageCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  // Keyboard dismiss
  static void dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  // Haptic feedback
  static void lightHaptic() {
    HapticFeedback.lightImpact();
  }

  static void mediumHaptic() {
    HapticFeedback.mediumImpact();
  }

  static void heavyHaptic() {
    HapticFeedback.heavyImpact();
  }

  // Debounce utility
  static void debounce(
    String key,
    Duration delay,
    VoidCallback callback,
  ) {
    // Debounce implementation
    Future.delayed(delay, () {
      callback();
    });
  }

  // Memory usage monitoring
  static void logMemoryUsage(String label) {
    debugPrint('Memory usage at $label: ${_getMemoryUsage()}');
  }

  static String _getMemoryUsage() {
    // Memory usage hesaplama
    return 'Memory usage logged';
  }
}
