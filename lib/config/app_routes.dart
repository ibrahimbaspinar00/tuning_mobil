import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../sayfalar/giris_sayfasi.dart';
import '../sayfalar/kayit_sayfasi.dart';
import '../sayfalar/main_screen.dart';
import '../sayfalar/urun_detay_sayfasi.dart';
import '../sayfalar/odeme_sayfasi.dart';
import '../sayfalar/siparisler_sayfasi.dart';
import '../sayfalar/siparis_detay_sayfasi.dart';
import '../sayfalar/profil_sayfasi.dart';
import '../sayfalar/adres_yonetimi_sayfasi.dart';
import '../sayfalar/odeme_yontemleri_sayfasi.dart';
import '../sayfalar/bildirimler_sayfasi.dart';
import '../sayfalar/bildirim_ayarlari_sayfasi.dart';
import '../sayfalar/para_yukleme_sayfasi.dart';
import '../model/product.dart';
import '../model/order.dart';
import '../services/product_service.dart';
import '../services/firebase_data_service.dart';

/// Uygulama route'larını tanımlar ve yönetir
class AppRoutes {
  // Route isimleri
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String home = '/home';
  static const String favorites = '/favorites';
  static const String cart = '/cart';
  static const String account = '/account';
  static const String categories = '/categories';
  static const String productDetail = '/product-detail';
  static const String payment = '/payment';
  static const String orders = '/orders';
  static const String orderDetail = '/order-detail';
  static const String profile = '/profile';
  static const String addressManagement = '/address-management';
  static const String paymentMethods = '/payment-methods';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notification-settings';
  static const String wallet = '/wallet';

  /// Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case splash:
      case main:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const GirisSayfasi(),
          settings: settings,
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const KayitSayfasi(),
          settings: settings,
        );

      case productDetail:
        // Deep link desteği: product-detail?productId=xxx veya args['productId']
        if (args is Map<String, dynamic>) {
          // Normal navigation (ürün objesi ile)
          if (args['product'] != null) {
            final onFavoriteToggle = args['onFavoriteToggle'] as Function(Product)?;
            final onAddToCart = args['onAddToCart'] as Function(Product)?;
            final onRemoveFromCart = args['onRemoveFromCart'] as Function(Product)?;
            
            return MaterialPageRoute(
              builder: (_) => UrunDetaySayfasi(
                product: args['product'] as Product,
                favoriteProducts: args['favoriteProducts'] as List<Product>? ?? [],
                cartProducts: args['cartProducts'] as List<Product>? ?? [],
                onFavoriteToggle: onFavoriteToggle ?? (_) {},
                onAddToCart: onAddToCart ?? (_) {},
                onRemoveFromCart: onRemoveFromCart ?? (_) {},
                forceHasPurchased: args['forceHasPurchased'] as bool? ?? false,
              ),
              settings: settings,
            );
          }
          // Deep link: productId ile ürün yükle
          else if (args['productId'] != null) {
            final productId = args['productId'] as String;
            final forceHasPurchased = args['forceHasPurchased'] as bool? ?? false;
            return MaterialPageRoute(
              builder: (_) => _ProductDetailFromIdPage(
                productId: productId,
                forceHasPurchased: forceHasPurchased,
              ),
              settings: settings,
            );
          }
        }
        // URL query parametreleri ile (tuningapp://product/{productId})
        else if (settings.arguments is String) {
          final productId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => _ProductDetailFromIdPage(
              productId: productId,
              forceHasPurchased: false, // Deep link için false
            ),
            settings: settings,
          );
        }
        // Route name'den productId çıkarma (tuningapp://product/123 -> /product-detail?productId=123)
        else if (settings.name?.contains('product') == true) {
          // URL parse ederek productId çıkar
          final uri = Uri.tryParse(settings.name ?? '');
          if (uri != null && uri.pathSegments.isNotEmpty) {
            try {
              final productId = uri.pathSegments.last;
              if (productId.isNotEmpty) {
                return MaterialPageRoute(
                  builder: (_) => _ProductDetailFromIdPage(
                    productId: productId,
                    forceHasPurchased: false, // Deep link için false
                  ),
                  settings: settings,
                );
              }
            } catch (e) {
              debugPrint('Error parsing productId from pathSegments: $e');
            }
          }
        }
        break;

      case payment:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => OdemeSayfasi(
              cartProducts: args['cartProducts'] as List<Product>,
              appliedCoupon: args['appliedCoupon'] as String? ?? '',
              couponDiscount: args['couponDiscount'] as double? ?? 0.0,
              isCouponApplied: args['isCouponApplied'] as bool? ?? false,
              orderId: args['orderId'] as String?,
            ),
            settings: settings,
          );
        }
        break;

      case orders:
        return MaterialPageRoute(
          builder: (_) => const SiparislerSayfasi(),
          settings: settings,
        );

      case orderDetail:
        if (args is Order) {
          return MaterialPageRoute(
            builder: (_) => SiparisDetaySayfasi(order: args),
            settings: settings,
          );
        }
        break;

      case profile:
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ProfilSayfasi(
              favoriteProducts: args['favoriteProducts'] as List<Product>? ?? [],
              cartProducts: args['cartProducts'] as List<Product>? ?? [],
              orders: args['orders'] as List<Order>? ?? [],
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const ProfilSayfasi(
            favoriteProducts: [],
            cartProducts: [],
            orders: [],
          ),
          settings: settings,
        );

      case addressManagement:
        return MaterialPageRoute(
          builder: (_) => const AdresYonetimiSayfasi(),
          settings: settings,
        );

      case paymentMethods:
        return MaterialPageRoute(
          builder: (_) => const OdemeYontemleriSayfasi(),
          settings: settings,
        );

      case notifications:
        return MaterialPageRoute(
          builder: (_) => const BildirimlerSayfasi(),
          settings: settings,
        );

      case notificationSettings:
        return MaterialPageRoute(
          builder: (_) => const BildirimAyarlariSayfasi(),
          settings: settings,
        );

      case wallet:
        return MaterialPageRoute(
          builder: (_) => const ParaYuklemeSayfasi(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
          settings: settings,
        );
    }

    // Fallback
    return MaterialPageRoute(
      builder: (_) => const MainScreen(),
      settings: settings,
    );
  }

  /// Navigate to product detail
  static Future<void> navigateToProductDetail(
    BuildContext context,
    Product product, {
    List<Product>? favoriteProducts,
    List<Product>? cartProducts,
    Function(Product)? onFavoriteToggle,
    Function(Product)? onAddToCart,
    Function(Product)? onRemoveFromCart,
  }) {
    return Navigator.pushNamed(
      context,
      productDetail,
      arguments: {
        'product': product,
        'favoriteProducts': favoriteProducts ?? [],
        'cartProducts': cartProducts ?? [],
        'onFavoriteToggle': onFavoriteToggle,
        'onAddToCart': onAddToCart,
        'onRemoveFromCart': onRemoveFromCart,
      },
    );
  }

  /// Navigate to payment
  static Future<void> navigateToPayment(
    BuildContext context,
    List<Product> cartProducts, {
    String? appliedCoupon,
    double? couponDiscount,
    bool? isCouponApplied,
    String? orderId,
  }) {
    return Navigator.pushNamed(
      context,
      payment,
      arguments: {
        'cartProducts': cartProducts,
        'appliedCoupon': appliedCoupon ?? '',
        'couponDiscount': couponDiscount ?? 0.0,
        'isCouponApplied': isCouponApplied ?? false,
        'orderId': orderId,
      },
    );
  }

  /// Navigate to order detail
  static Future<void> navigateToOrderDetail(
    BuildContext context,
    Order order,
  ) {
    return Navigator.pushNamed(
      context,
      orderDetail,
      arguments: order,
    );
  }

  /// Navigate to login
  static Future<void> navigateToLogin(BuildContext context) {
    return Navigator.pushReplacementNamed(context, login);
  }

  /// Navigate to register
  static Future<void> navigateToRegister(BuildContext context) {
    return Navigator.pushNamed(context, register);
  }

  /// Navigate to main screen
  static Future<void> navigateToMain(BuildContext context) {
    return Navigator.pushReplacementNamed(context, main);
  }

  /// Navigate back
  static void navigateBack(BuildContext context, [dynamic result]) {
    Navigator.pop(context, result);
  }

  /// Deep link ile ürün detay sayfasına git
  static Future<void> navigateToProductDetailById(
    BuildContext context,
    String productId, {
    bool forceHasPurchased = false, // Siparişlerden gelindiğinde true
  }) {
    return Navigator.pushNamed(
      context,
      productDetail,
      arguments: {
        'productId': productId,
        'forceHasPurchased': forceHasPurchased,
      },
    ).then((_) {});
  }
}

/// Product ID ile ürün detay sayfası (deep link için)
class _ProductDetailFromIdPage extends StatefulWidget {
  final String productId;
  final bool forceHasPurchased; // Siparişlerden gelindiğinde true

  const _ProductDetailFromIdPage({
    required this.productId,
    this.forceHasPurchased = false,
  });

  @override
  State<_ProductDetailFromIdPage> createState() => _ProductDetailFromIdPageState();
}

class _ProductDetailFromIdPageState extends State<_ProductDetailFromIdPage> {
  Product? _product;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final productService = ProductService();
      final product = await productService.getProductById(widget.productId);
      
      if (product != null) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Ürün bulunamadı';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ürün yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ürün Yükleniyor...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hata')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Ürün bulunamadı'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }

    // Deep link ile geldiğinde Firebase'den favorileri ve sepeti yükle
    return _ProductDetailWithData(
      product: _product!,
      forceHasPurchased: widget.forceHasPurchased,
    );
  }
}

/// Deep link ile gelen ürün detay sayfası (callback'lerle)
class _ProductDetailWithData extends StatefulWidget {
  final Product product;
  final bool forceHasPurchased; // Siparişlerden gelindiğinde true

  const _ProductDetailWithData({
    required this.product,
    this.forceHasPurchased = false,
  });

  @override
  State<_ProductDetailWithData> createState() => _ProductDetailWithDataState();
}

class _ProductDetailWithDataState extends State<_ProductDetailWithData> {
  List<Product> _favoriteProducts = [];
  List<Product> _cartProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final dataService = FirebaseDataService();
      final productService = ProductService();
      
      // Favorileri yükle
      final favoriteIds = await dataService.getFavoriteProductIds();
      _favoriteProducts = [];
      for (final id in favoriteIds) {
        final product = await productService.getProductById(id);
        if (product != null) {
          _favoriteProducts.add(product);
        }
      }
      
      // Sepeti yükle
      final cartItems = await dataService.getCartItems();
      _cartProducts = [];
      for (final item in cartItems) {
        final productId = item['productId'] as String? ?? item['id'] as String;
        final quantity = item['quantity'] as int? ?? 1;
        final product = await productService.getProductById(productId);
        if (product != null) {
          _cartProducts.add(product.copyWith(quantity: quantity));
        }
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading user data for deep link: $e');
      setState(() => _isLoading = false);
    }
  }

  void _toggleFavorite(Product product) {
    final dataService = FirebaseDataService();
    final index = _favoriteProducts.indexWhere((p) => p.id == product.id);
    
    if (index != -1) {
      setState(() => _favoriteProducts.removeAt(index));
      dataService.removeFromFavorites(product.id).catchError((e) {
        debugPrint('Error removing favorite: $e');
      });
    } else {
      setState(() => _favoriteProducts.add(product));
      dataService.addToFavorites(product.id).catchError((e) {
        debugPrint('Error adding favorite: $e');
      });
    }
  }

  Future<void> _addToCart(Product product) async {
    final dataService = FirebaseDataService();
    final index = _cartProducts.indexWhere((p) => p.id == product.id);
    
    if (index != -1) {
      final newQuantity = _cartProducts[index].quantity + 1;
      setState(() => _cartProducts[index] = product.copyWith(quantity: newQuantity));
      await dataService.updateCartQuantity(product.id, newQuantity);
    } else {
      setState(() => _cartProducts.add(product.copyWith(quantity: 1)));
      await dataService.addToCart(product.id, 1);
    }
  }

  void _removeFromCart(Product product) {
    final dataService = FirebaseDataService();
    setState(() => _cartProducts.removeWhere((p) => p.id == product.id));
    dataService.removeFromCart(product.id).catchError((e) {
      debugPrint('Error removing from cart: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yükleniyor...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return UrunDetaySayfasi(
      product: widget.product,
      favoriteProducts: _favoriteProducts,
      cartProducts: _cartProducts,
      onFavoriteToggle: _toggleFavorite,
      onAddToCart: _addToCart,
      onRemoveFromCart: _removeFromCart,
      forceHasPurchased: widget.forceHasPurchased, // Siparişlerden gelindiğinde true
    );
  }
}

