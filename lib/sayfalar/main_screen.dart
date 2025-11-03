import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'ana_sayfa.dart';
import 'favoriler_sayfasi.dart';
import 'sepetim_sayfasi.dart';
import 'hesabim_sayfasi.dart';
import 'kategoriler_sayfasi.dart';
import '../config/app_routes.dart';
import '../model/product.dart';
import '../model/order.dart';
import '../widgets/error_handler.dart';
import '../utils/performance_utils.dart';
import '../utils/memory_manager.dart';
import '../services/firebase_data_service.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;

  final List<Product> favoriteProducts = [];
  final List<Product> cartProducts = [];
  final List<Order> orders = [];
  
  Timer? _memoryCleanupTimer;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
    _listenToDeepLinks();
    _memoryCleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _performMemoryCleanup();
    });
  }

  /// Deep link'leri dinle (uygulama açıkken)
  void _listenToDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });
  }

  /// Deep link'i işle
  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link alındı (MainScreen): $uri');
    debugPrint('Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
    
    String? productId;
    
    // HTTPS formatında deep link (https://tuning-app-789ce.web.app/product/{productId})
    if ((uri.scheme == 'https' || uri.scheme == 'http') && 
        (uri.host == 'tuning-app-789ce.web.app' || uri.host.contains('tuning-app'))) {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'product') {
        if (uri.pathSegments.length > 1) {
          productId = uri.pathSegments[1];
          debugPrint('Got productId from HTTPS link: $productId');
        }
      }
    }
    // Custom scheme formatında deep link (tuningapp://product/{productId})
    else if (uri.scheme == 'tuningapp' && uri.host == 'product') {
      debugPrint('Full URI: $uri');
      debugPrint('Path segments: ${uri.pathSegments}');
      debugPrint('Path: ${uri.path}');
      debugPrint('Query params: ${uri.queryParameters}');
      
      // Önce pathSegments'i kontrol et (en güvenilir)
      if (uri.pathSegments.isNotEmpty) {
        productId = uri.pathSegments.first;
        debugPrint('Got productId from pathSegments: $productId');
      }
      // Path'ten al (tuningapp://product/123 formatı için)
      else if (uri.path.isNotEmpty && uri.path != '/') {
        productId = uri.path.replaceFirst('/', '').replaceAll('/', '').trim();
        debugPrint('Got productId from path: $productId');
      }
      // Query parametrelerinden al (tuningapp://product?id=123 formatı için)
      else if (uri.queryParameters.containsKey('id')) {
        productId = uri.queryParameters['id']!;
        debugPrint('Got productId from query: $productId');
      }
      // Authority'den al (product:productId formatında ise)
      else if (uri.authority.contains(':')) {
        productId = uri.authority.split(':').last;
        debugPrint('Got productId from authority: $productId');
      }
      
      debugPrint('Final extracted productId: "$productId"');
    }
    
    // ProductId bulunduysa yönlendir
    if (productId != null && productId.isNotEmpty && productId != 'product' && productId != '/' && mounted) {
      debugPrint('✓ ProductId bulundu: $productId');
      debugPrint('✓ MainScreen context: ${context.hashCode}');
      debugPrint('✓ NavigateToProductDetailById çağrılıyor...');
      
      // Kısa bir gecikme ekle (UI'nin hazır olması için)
      final finalProductId = productId; // Null check için
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && finalProductId != null) {
          try {
            AppRoutes.navigateToProductDetailById(context, finalProductId);
            debugPrint('✓ Navigate işlemi tamamlandı');
          } catch (e, stackTrace) {
            debugPrint('✗ Navigate hatası: $e');
            debugPrint('Stack trace: $stackTrace');
          }
        }
      });
    } else {
      debugPrint('✗ Product ID bulunamadı veya geçersiz');
      debugPrint('  - productId: $productId');
      debugPrint('  - mounted: $mounted');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // App resumed - optimize memory
        MemoryManager.optimizeMemory();
        break;
      case AppLifecycleState.paused:
        // App paused - clear caches
        PerformanceUtils.clearImageCache();
        break;
      case AppLifecycleState.detached:
        // App detached - full cleanup
        _fullCleanup();
        break;
      default:
        break;
    }
  }

  Future<void> _initializeApp() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('User logged in: ${user.email}');
        // Firebase'den favorileri, sepeti ve siparişleri yükle
        await _loadFavoritesFromFirebase();
        await _loadCartFromFirebase();
        await _loadOrdersFromFirebase();
      }
    } catch (e) {
      debugPrint('Error in _initializeApp: $e');
    }
  }

  /// Firebase'den siparişleri yükle
  Future<void> _loadOrdersFromFirebase() async {
    if (!mounted) return;
    
    try {
      final orderService = OrderService();
      final userOrders = await orderService.getUserOrders();
      
      orders.clear();
      orders.addAll(userOrders);
      
      if (mounted) {
        setState(() {});
        debugPrint('Loaded ${orders.length} orders from Firebase');
      }
    } catch (e) {
      debugPrint('Error loading orders from Firebase: $e');
    }
  }

  /// Firebase'den favorileri yükle
  Future<void> _loadFavoritesFromFirebase() async {
    if (!mounted) return;
    
    try {
      final dataService = FirebaseDataService();
      final productService = ProductService();
      
      // Firebase'den favori ürün ID'lerini al
      final favoriteIds = await dataService.getFavoriteProductIds();
      
      if (favoriteIds.isEmpty) {
        debugPrint('No favorites found in Firebase');
        return;
      }
      
      // Her ürün ID'si için ürün bilgisini al ve ekle
      favoriteProducts.clear();
      for (final productId in favoriteIds) {
        try {
          final product = await productService.getProductById(productId);
          if (product != null) {
            favoriteProducts.add(product);
          }
        } catch (e) {
          debugPrint('Error loading favorite product $productId: $e');
        }
      }
      
      if (mounted) {
        setState(() {});
        debugPrint('Loaded ${favoriteProducts.length} favorites from Firebase');
      }
    } catch (e) {
      debugPrint('Error loading favorites from Firebase: $e');
    }
  }

  /// Firebase'den sepeti yükle
  Future<void> _loadCartFromFirebase() async {
    if (!mounted) return;
    
    try {
      final dataService = FirebaseDataService();
      final productService = ProductService();
      
      // Firebase'den sepet öğelerini al
      final cartItems = await dataService.getCartItems();
      
      if (cartItems.isEmpty) {
        debugPrint('Cart is empty in Firebase');
        return;
      }
      
      // Sepet öğelerini ürünlere dönüştür
      cartProducts.clear();
      for (final item in cartItems) {
        try {
          final productId = item['productId'] as String? ?? item['id'] as String;
          final quantity = item['quantity'] as int? ?? 1;
          
          final product = await productService.getProductById(productId);
          if (product != null) {
            cartProducts.add(product.copyWith(quantity: quantity));
          }
        } catch (e) {
          debugPrint('Error loading cart product: $e');
        }
      }
      
      if (mounted) {
        setState(() {});
        debugPrint('Loaded ${cartProducts.length} cart items from Firebase');
      }
    } catch (e) {
      debugPrint('Error loading cart from Firebase: $e');
    }
  }

  void _fullCleanup() {
    _memoryCleanupTimer?.cancel();
    MemoryManager.optimizeMemory();
  }
  
  void _performMemoryCleanup() {
    if (!mounted) return;
    try {
      MemoryManager.optimizeMemory();
    } catch (e) {
      debugPrint('Memory cleanup error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _memoryCleanupTimer?.cancel();
    _linkSubscription?.cancel();
    _fullCleanup();
    super.dispose();
  }

  List<Widget> _getPages() {
    return [
      // 0 - Ana Sayfa
      AnaSayfa(
        favoriteProducts: favoriteProducts,
        cartProducts: cartProducts,
        onFavoriteToggle: _toggleFavorite,
        onAddToCart: _addToCart,
        onRemoveFromCart: _removeFromCart,
      ),
      // 1 - Listelerim (FavorilerSayfasi ile aynı özellikler)
      FavorilerSayfasi(
        favoriteProducts: favoriteProducts,
        cartProducts: cartProducts,
        onFavoriteToggle: _toggleFavorite,
        onAddToCart: _addToCart,
      ),
      // 2 - Sepetim
      SepetimSayfasi(
        cartProducts: cartProducts,
        onRemoveFromCart: _removeFromCart,
        onUpdateQuantity: _updateQuantity,
        onPlaceOrder: _placeOrder,
      ),
      // 3 - Hesabım
      const HesabimSayfasi(),
      // 4 - Kategoriler
      KategorilerSayfasi(
        favoriteProducts: favoriteProducts,
        cartProducts: cartProducts,
        onFavoriteToggle: _toggleFavorite,
        onAddToCart: _addToCart,
        onRemoveFromCart: _removeFromCart,
      ),
    ];
  }
  
  List<Widget> _getCachedPages() {
    return _getPages();
  }

  void _toggleFavorite(Product product, {bool showMessage = true}) async {
    if (!mounted) return;
    
    try {
      final dataService = FirebaseDataService();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        if (showMessage && mounted) {
          ErrorHandler.showError(context, 'Favori eklemek için giriş yapmalısınız');
        }
        return;
      }
      
      final existingIndex = favoriteProducts.indexWhere((p) => p.id == product.id);
      if (existingIndex != -1) {
        // Favorilerden çıkar
        favoriteProducts.removeAt(existingIndex);
        // Firebase'den de kaldır
        try {
          await dataService.removeFromFavorites(product.id);
        } catch (e) {
          debugPrint('Error removing from favorites in Firebase: $e');
        }
        
        if (mounted) {
          setState(() {});
          if (showMessage) {
            ErrorHandler.showSilentInfo(context, '${product.name} favorilerden çıkarıldı');
          }
        }
      } else {
        // Favorilere ekle
        favoriteProducts.add(product);
        // Firebase'e de ekle
        try {
          await dataService.addToFavorites(product.id);
        } catch (e) {
          debugPrint('Error adding to favorites in Firebase: $e');
        }
        
        if (mounted) {
          setState(() {});
          if (showMessage) {
            ErrorHandler.showSilentSuccess(context, '${product.name} favorilere eklendi');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Favori işlemi sırasında hata oluştu: $e');
      }
    }
  }

  Future<void> _addToCart(Product product, {bool showMessage = true}) async {
    if (!mounted) return;
    
    try {
      final dataService = FirebaseDataService();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        if (showMessage && mounted) {
          ErrorHandler.showError(context, 'Sepete eklemek için giriş yapmalısınız');
        }
        return;
      }
      
      final existingIndex = cartProducts.indexWhere((p) => p.id == product.id);
      final requestedQuantity = existingIndex != -1 ? cartProducts[existingIndex].quantity + 1 : 1;
      
      // Stok kontrolü
      if (requestedQuantity > product.stock) {
        if (mounted && showMessage) {
          ErrorHandler.showError(context, 'Yeterli stok yok. Mevcut stok: ${product.stock}');
        }
        return;
      }
      
      // Sepete ekle veya miktarı artır
      if (existingIndex != -1) {
        cartProducts[existingIndex].quantity++;
        // Firebase'de güncelle
        try {
          await dataService.updateCartQuantity(product.id, cartProducts[existingIndex].quantity);
        } catch (e) {
          debugPrint('Error updating cart in Firebase: $e');
        }
        
        if (mounted) {
          setState(() {});
          if (showMessage) {
            ErrorHandler.showSilentSuccess(context, '${product.name} miktarı artırıldı');
          }
        }
      } else {
        final newProduct = product.copyWith(quantity: 1);
        cartProducts.add(newProduct);
        // Firebase'e ekle
        try {
          await dataService.addToCart(product.id, 1);
        } catch (e) {
          debugPrint('Error adding to cart in Firebase: $e');
        }
        
        if (mounted) {
          setState(() {});
          if (showMessage) {
            ErrorHandler.showCartSuccess(
              context, 
              '${product.name} sepete eklendi',
              onViewCart: () {
                _selectedIndex = 2;
                setState(() {});
              },
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Sepet işlemi sırasında hata oluştu: $e');
      }
    }
  }

  void _removeFromCart(Product product) async {
    if (!mounted) return;
    
    try {
      final dataService = FirebaseDataService();
      final index = cartProducts.indexWhere((p) => p.id == product.id);
      
      if (index != -1) {
        cartProducts.removeAt(index);
        // Firebase'den de kaldır
        try {
          await dataService.removeFromCart(product.id);
        } catch (e) {
          debugPrint('Error removing from cart in Firebase: $e');
        }
        
        if (mounted) {
          setState(() {});
          ErrorHandler.showSilentInfo(context, '${product.name} sepetten çıkarıldı');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Sepet işlemi sırasında hata oluştu: $e');
      }
    }
  }

  Future<void> _updateQuantity(Product product, int newQuantity) async {
    if (!mounted) return;
    
    try {
      final dataService = FirebaseDataService();
      final index = cartProducts.indexWhere((p) => p.id == product.id);
      
      if (index != -1) {
        if (newQuantity <= 0) {
          cartProducts.removeAt(index);
          // Firebase'den de kaldır
          try {
            await dataService.removeFromCart(product.id);
          } catch (e) {
            debugPrint('Error removing from cart in Firebase: $e');
          }
          
          if (mounted) {
            setState(() {});
            ErrorHandler.showSilentInfo(context, '${product.name} sepetten çıkarıldı');
          }
        } else {
          // Stok kontrolü yap (miktar artırma durumunda)
          if (newQuantity > product.quantity) {
            // Stok kontrolü - product.stock kullanılıyor
            if (newQuantity > product.stock) {
              if (mounted) {
                ErrorHandler.showError(context, 'Yeterli stok yok. Mevcut stok: ${product.stock}');
              }
              return;
            }
          }
          
          // Yeni Product objesi oluştur
          cartProducts[index] = product.copyWith(quantity: newQuantity);
          // Firebase'de güncelle
          try {
            await dataService.updateCartQuantity(product.id, newQuantity);
          } catch (e) {
            debugPrint('Error updating cart quantity in Firebase: $e');
          }
          
          if (mounted) {
            setState(() {});
            ErrorHandler.showSilentSuccess(context, '${product.name} miktarı güncellendi');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Miktar güncelleme sırasında hata oluştu: $e');
      }
    }
  }

  Future<void> _placeOrder() async {
    if (!mounted || cartProducts.isEmpty) return;
    
    try {
      final dataService = FirebaseDataService();
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        products: List.from(cartProducts),
        totalAmount: cartProducts.fold(0.0, (sum, product) => sum + (product.price * product.quantity)),
        orderDate: DateTime.now(),
        status: 'Beklemede',
        customerName: 'Müşteri',
        customerEmail: 'musteri@example.com',
        customerPhone: '555-0123',
        shippingAddress: 'Adres bilgisi',
      );
      
      orders.add(order);
      
      // Sepeti temizle (hem local hem Firebase)
      cartProducts.clear();
      try {
        await dataService.clearCart();
      } catch (e) {
        debugPrint('Error clearing cart in Firebase: $e');
      }
      
      if (mounted) {
        setState(() {});
        ErrorHandler.showSilentSuccess(context, 'Sipariş başarıyla oluşturuldu!');
        AppRoutes.navigateToPayment(context, cartProducts);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Sipariş oluşturma sırasında hata oluştu: $e');
      }
    }
  }

  void _onItemTapped(int index) {
    if (!mounted || _selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    
    return Scaffold(
          backgroundColor: Colors.grey[50],
          resizeToAvoidBottomInset: false, // Klavye performansı için
          body: SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: _getCachedPages(),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              margin: EdgeInsets.fromLTRB(
                isSmallScreen ? 4 : isTablet ? 8 : 12, 
                0, 
                isSmallScreen ? 4 : isTablet ? 8 : 12, 
                isSmallScreen ? 4 : isTablet ? 8 : 12
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  selectedItemColor: Colors.blue[600],
                  unselectedItemColor: Colors.grey[500],
                  selectedLabelStyle: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: isSmallScreen ? 9 : 11,
                    fontWeight: FontWeight.w500,
                  ),
                  items: [
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 0 ? Colors.blue[50] : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.home_rounded,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    label: 'Ana Sayfa',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 1 ? Colors.green[50] : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    label: 'Listelerim',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 2 ? Colors.orange[50] : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.shopping_cart_rounded,
                            size: isSmallScreen ? 20 : 24,
                          ),
                          if (cartProducts.isNotEmpty)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  cartProducts.length > 99 ? '99+' : '${cartProducts.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    label: 'Sepetim',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 3 ? Colors.purple[50] : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    label: 'Hesabım',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 4 ? Colors.red[50] : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.category_rounded,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    label: 'Kategoriler',
                  ),
                ],
              ),
            ),
            ),
          ),
        );
  }
}
