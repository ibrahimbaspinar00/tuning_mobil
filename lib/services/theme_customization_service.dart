import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCustomizationService {
  static final ThemeCustomizationService _instance = ThemeCustomizationService._internal();
  factory ThemeCustomizationService() => _instance;
  ThemeCustomizationService._internal();

  final SharedPreferences _prefs = SharedPreferences.getInstance() as SharedPreferences;
  
  // Tema anahtarları
  static const String _themeModeKey = 'theme_mode';
  static const String _primaryColorKey = 'primary_color';
  static const String _accentColorKey = 'accent_color';
  static const String _fontSizeKey = 'font_size';
  static const String _fontFamilyKey = 'font_family';
  static const String _customThemeKey = 'custom_theme';

  // Tema modları
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = Colors.blue;
  Color _accentColor = Colors.orange;
  double _fontSize = 14.0;
  String _fontFamily = 'Roboto';

  // Getters
  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  Color get accentColor => _accentColor;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;

  /// Tema servisini başlat
  Future<void> initialize() async {
    try {
      await _loadThemeSettings();
      debugPrint('ThemeCustomizationService initialized');
    } catch (e) {
      debugPrint('ThemeCustomizationService initialization error: $e');
    }
  }

  /// Tema ayarlarını yükle
  Future<void> _loadThemeSettings() async {
    try {
      // Tema modu
      final themeModeString = _prefs.getString(_themeModeKey);
      if (themeModeString != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }

      // Ana renk
      final primaryColorValue = _prefs.getInt(_primaryColorKey);
      if (primaryColorValue != null) {
        _primaryColor = Color(primaryColorValue);
      }

      // Vurgu rengi
      final accentColorValue = _prefs.getInt(_accentColorKey);
      if (accentColorValue != null) {
        _accentColor = Color(accentColorValue);
      }

      // Font boyutu
      _fontSize = _prefs.getDouble(_fontSizeKey) ?? 14.0;

      // Font ailesi
      _fontFamily = _prefs.getString(_fontFamilyKey) ?? 'Roboto';
    } catch (e) {
      debugPrint('Load theme settings error: $e');
    }
  }

  /// Tema modunu ayarla
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      _themeMode = mode;
      await _prefs.setString(_themeModeKey, mode.toString());
      debugPrint('Theme mode set to: $mode');
    } catch (e) {
      debugPrint('Set theme mode error: $e');
    }
  }

  /// Ana rengi ayarla
  Future<void> setPrimaryColor(Color color) async {
    try {
      _primaryColor = color;
      await _prefs.setInt(_primaryColorKey, color.value);
      debugPrint('Primary color set to: $color');
    } catch (e) {
      debugPrint('Set primary color error: $e');
    }
  }

  /// Vurgu rengini ayarla
  Future<void> setAccentColor(Color color) async {
    try {
      _accentColor = color;
      await _prefs.setInt(_accentColorKey, color.value);
      debugPrint('Accent color set to: $color');
    } catch (e) {
      debugPrint('Set accent color error: $e');
    }
  }

  /// Font boyutunu ayarla
  Future<void> setFontSize(double size) async {
    try {
      _fontSize = size;
      await _prefs.setDouble(_fontSizeKey, size);
      debugPrint('Font size set to: $size');
    } catch (e) {
      debugPrint('Set font size error: $e');
    }
  }

  /// Font ailesini ayarla
  Future<void> setFontFamily(String family) async {
    try {
      _fontFamily = family;
      await _prefs.setString(_fontFamilyKey, family);
      debugPrint('Font family set to: $family');
    } catch (e) {
      debugPrint('Set font family error: $e');
    }
  }

  /// Özel tema oluştur
  ThemeData createCustomTheme({bool isDark = false}) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    
    return ThemeData(
      brightness: brightness,
      primarySwatch: _createMaterialColor(_primaryColor),
      primaryColor: _primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          fontSize: _fontSize,
          fontFamily: _fontFamily,
        ),
        bodyMedium: TextStyle(
          fontSize: _fontSize - 2,
          fontFamily: _fontFamily,
        ),
        bodySmall: TextStyle(
          fontSize: _fontSize - 4,
          fontFamily: _fontFamily,
        ),
        titleLarge: TextStyle(
          fontSize: _fontSize + 6,
          fontFamily: _fontFamily,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          fontSize: _fontSize + 4,
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          fontSize: _fontSize + 2,
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        selectedItemColor: _primaryColor,
        unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Material color oluştur
  MaterialColor _createMaterialColor(Color color) {
    final List<double> strengths = <double>[.05];
    final Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (double strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  /// Önceden tanımlanmış temalar
  List<Map<String, dynamic>> getPredefinedThemes() {
    return [
      {
        'name': 'Mavi Tema',
        'primaryColor': Colors.blue,
        'accentColor': Colors.orange,
        'description': 'Klasik mavi ve turuncu kombinasyonu',
      },
      {
        'name': 'Yeşil Tema',
        'primaryColor': Colors.green,
        'accentColor': Colors.pink,
        'description': 'Doğal yeşil ve pembe kombinasyonu',
      },
      {
        'name': 'Mor Tema',
        'primaryColor': Colors.purple,
        'accentColor': Colors.teal,
        'description': 'Modern mor ve teal kombinasyonu',
      },
      {
        'name': 'Kırmızı Tema',
        'primaryColor': Colors.red,
        'accentColor': Colors.amber,
        'description': 'Enerjik kırmızı ve amber kombinasyonu',
      },
      {
        'name': 'Turuncu Tema',
        'primaryColor': Colors.orange,
        'accentColor': Colors.blue,
        'description': 'Sıcak turuncu ve mavi kombinasyonu',
      },
      {
        'name': 'Teal Tema',
        'primaryColor': Colors.teal,
        'accentColor': Colors.deepOrange,
        'description': 'Sakin teal ve turuncu kombinasyonu',
      },
    ];
  }

  /// Önceden tanımlanmış temayı uygula
  Future<void> applyPredefinedTheme(Map<String, dynamic> theme) async {
    try {
      await setPrimaryColor(theme['primaryColor'] as Color);
      await setAccentColor(theme['accentColor'] as Color);
      debugPrint('Predefined theme applied: ${theme['name']}');
    } catch (e) {
      debugPrint('Apply predefined theme error: $e');
    }
  }

  /// Font aileleri
  List<String> getAvailableFonts() {
    return [
      'Roboto',
      'Open Sans',
      'Lato',
      'Montserrat',
      'Poppins',
      'Nunito',
      'Source Sans Pro',
      'Raleway',
      'Ubuntu',
      'Playfair Display',
    ];
  }

  /// Font boyutları
  List<Map<String, dynamic>> getFontSizes() {
    return [
      {'name': 'Küçük', 'size': 12.0, 'description': 'Kompakt görünüm'},
      {'name': 'Normal', 'size': 14.0, 'description': 'Standart boyut'},
      {'name': 'Büyük', 'size': 16.0, 'description': 'Kolay okuma'},
      {'name': 'Çok Büyük', 'size': 18.0, 'description': 'Erişilebilirlik'},
    ];
  }

  /// Tema ayarlarını sıfırla
  Future<void> resetThemeSettings() async {
    try {
      await _prefs.remove(_themeModeKey);
      await _prefs.remove(_primaryColorKey);
      await _prefs.remove(_accentColorKey);
      await _prefs.remove(_fontSizeKey);
      await _prefs.remove(_fontFamilyKey);
      await _prefs.remove(_customThemeKey);
      
      // Varsayılan değerleri yükle
      _themeMode = ThemeMode.system;
      _primaryColor = Colors.blue;
      _accentColor = Colors.orange;
      _fontSize = 14.0;
      _fontFamily = 'Roboto';
      
      debugPrint('Theme settings reset');
    } catch (e) {
      debugPrint('Reset theme settings error: $e');
    }
  }

  /// Tema ayarlarını dışa aktar
  Future<Map<String, dynamic>> exportThemeSettings() async {
    try {
      return {
        'themeMode': _themeMode.toString(),
        'primaryColor': _primaryColor.value,
        'accentColor': _accentColor.value,
        'fontSize': _fontSize,
        'fontFamily': _fontFamily,
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Export theme settings error: $e');
      return {};
    }
  }

  /// Tema ayarlarını içe aktar
  Future<void> importThemeSettings(Map<String, dynamic> settings) async {
    try {
      if (settings.containsKey('themeMode')) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == settings['themeMode'],
          orElse: () => ThemeMode.system,
        );
        await _prefs.setString(_themeModeKey, _themeMode.toString());
      }
      
      if (settings.containsKey('primaryColor')) {
        _primaryColor = Color(settings['primaryColor']);
        await _prefs.setInt(_primaryColorKey, _primaryColor.value);
      }
      
      if (settings.containsKey('accentColor')) {
        _accentColor = Color(settings['accentColor']);
        await _prefs.setInt(_accentColorKey, _accentColor.value);
      }
      
      if (settings.containsKey('fontSize')) {
        _fontSize = settings['fontSize'].toDouble();
        await _prefs.setDouble(_fontSizeKey, _fontSize);
      }
      
      if (settings.containsKey('fontFamily')) {
        _fontFamily = settings['fontFamily'];
        await _prefs.setString(_fontFamilyKey, _fontFamily);
      }
      
      debugPrint('Theme settings imported');
    } catch (e) {
      debugPrint('Import theme settings error: $e');
    }
  }

  /// Tema önizlemesi
  Widget buildThemePreview(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tema Önizlemesi',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Bu metin tema ayarlarınızı gösterir.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                child: const Text('Buton'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Çerçeveli'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
