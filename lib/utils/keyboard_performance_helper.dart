import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Klavye performans optimizasyonları için helper sınıfı
class KeyboardPerformanceHelper {
  /// Klavye performansı için optimize edilmiş TextField özellikleri
  static const Map<String, dynamic> optimizedTextFieldProperties = {
    'enableSuggestions': false,
    'autocorrect': false,
    'smartDashesType': SmartDashesType.disabled,
    'smartQuotesType': SmartQuotesType.disabled,
    'textCapitalization': TextCapitalization.none,
    'maxLines': 1,
    'buildCounter': null,
    'maxLength': null,
  };

  /// Klavye performansı için optimize edilmiş InputDecoration
  static InputDecoration optimizedInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixPressed,
    bool isDense = true,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon != null && onSuffixPressed != null
          ? IconButton(
              icon: Icon(suffixIcon),
              onPressed: onSuffixPressed,
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          : null,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: isDense,
      isCollapsed: false,
    );
  }

  /// Klavye açıldığında gereksiz rebuild'leri önlemek için
  /// Scaffold'a resizeToAvoidBottomInset: false ekle
  static Widget wrapWithKeyboardOptimization(Widget child) {
    return RepaintBoundary(
      child: child,
    );
  }

  /// Klavye açıldığında scroll davranışını optimize et
  static ScrollPhysics getOptimizedScrollPhysics() {
    return const ClampingScrollPhysics();
  }

  /// Klavye açıldığında haptic feedback'i optimize et
  static void optimizedHapticFeedback() {
    // Light impact - daha az performans maliyeti
    HapticFeedback.lightImpact();
  }

  /// TextField için performans optimizasyonları
  static Widget optimizedTextField({
    required TextEditingController controller,
    required String hintText,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
    TextInputAction textInputAction = TextInputAction.search,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixPressed,
    String? key,
  }) {
    return RepaintBoundary(
      child: TextField(
        key: key != null ? ValueKey(key) : null,
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        enableSuggestions: false,
        autocorrect: false,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        enableInteractiveSelection: true,
        textCapitalization: TextCapitalization.none,
        maxLines: 1,
        buildCounter: null,
        maxLength: null,
        style: const TextStyle(),
        decoration: optimizedInputDecoration(
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          onSuffixPressed: onSuffixPressed,
        ),
      ),
    );
  }

  /// Klavye açıldığında MediaQuery'yi optimize et
  static MediaQueryData optimizeMediaQuery(MediaQueryData media) {
    return media.copyWith(
      viewInsets: EdgeInsets.zero, // Klavye açılışında rebuild önleme
      viewPadding: media.viewPadding,
      padding: media.padding,
    );
  }
}

