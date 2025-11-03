import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Klavye performansı için optimizasyonlar
class KeyboardOptimizer {
  /// TextField için optimize edilmiş ayarlar
  static Map<String, dynamic> getOptimizedTextFieldSettings() {
    return {
      'enableSuggestions': false,
      'autocorrect': false,
      'smartDashesType': SmartDashesType.disabled,
      'smartQuotesType': SmartQuotesType.disabled,
      'enableInteractiveSelection': true,
      'maxLines': 1,
    };
  }

  /// Klavye açılışını hızlandır
  static void optimizeKeyboardOpening(BuildContext context) {
    // TextInputAction ayarla
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    
    // Kısa bir delay sonra tekrar aç - klavye hızını artırır
    Future.delayed(const Duration(milliseconds: 50), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  /// Focus yönetimini optimize et
  static void requestFocusOptimized(FocusNode focusNode) {
    if (focusNode.canRequestFocus) {
      focusNode.requestFocus();
    }
  }

  /// Klavyeyi kapat
  static void dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }
}

