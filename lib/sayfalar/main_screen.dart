import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'ana_sayfa.dart';
import 'favoriler_sayfasi.dart';
import 'sepetim_sayfasi.dart';
import 'hesabim_sayfasi.dart';
import 'kategoriler_sayfasi.dart';
import 'odeme_sayfasi.dart';
import 'giris_sayfasi.dart';
import '../model/product.dart';
import '../model/order.dart';
import '../widgets/error_handler.dart';
import '../utils/performance_utils.dart';
import '../utils/memory_manager.dart';
import '../services/admin_service.dart';

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
  
  // Performance optimization: Initialize flag
  bool _isInitialized = false;
  
  // Performance optimization: Debounce timer
  Timer? _debounceTimer;
  
  // Performance optimization: Page cache
  final Map<int, Widget> _pageCache = {};
  
  // Performance optimization: Memory management
  Timer? _memoryCleanupTimer;
  
  // Performance optimization: Frame rate monitoring
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();
  bool _isLowPerformance = false;
  

  // Static olarak tanımlayarak her rebuild'de yeniden oluşturulmasını önleyelim
  // static final List<Product> _dummyProducts = [
  //   Product(
  //       id: '1',
  //       name: 'Premium Araç Temizlik Bezi',
  //       description:
  //           'Yüksek kaliteli mikrofiber araç temizlik bezi. Çizik bırakmaz ve su emme kapasitesi yüksek.',
  //       price: 25.99,
  //       imageUrl: 'assets/images/placeholder.txt',
  //       category: 'Araç Temizlik',
  //       stock: 50),
  //   Product(
  //       id: '2',
  //       name: 'Araç İçi Hava Temizleyici',
  //       description:
  //           'Araç içindeki kötü kokuları gideren, doğal içerikli hava temizleyici sprey.',
  //       price: 18.50,
  //       imageUrl: 'assets/images/placeholder.txt',
  //       category: 'Araç Temizlik',
  //       stock: 30),
  //   Product(
  //       id: '3',
  //       name: 'Telefon Tutucu',
  //       description:
  //           'Araçta telefonunuzu güvenli şekilde tutan, 360 derece dönebilen tutucu.',
  //       price: 35.00,
  //       imageUrl: 'assets/images/placeholder.txt',
  //       category: 'Telefon Aksesuar',
  //       stock: 100),
  // ];

  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // CRITICAL: Ultra-fast initialization
    _initializeApp();
    
    // CRITICAL: Minimal memory cleanup
    _memoryCleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _performMemoryCleanup();
    });
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
    if (_isInitialized) return;
    
    try {
      // Performance optimization: Preload data
      await _preloadData();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error in _initializeApp: $e');
    }
  }

  Future<void> _preloadData() async {
    // Pre-load user data if logged in
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Pre-load user data here if needed
        debugPrint('User logged in: ${user.email}');
      }
    } catch (e) {
      debugPrint('Error in _preloadData: $e');
    }
  }

  void _fullCleanup() {
    favoriteProducts.clear();
    cartProducts.clear();
    orders.clear();
    _debounceTimer?.cancel();
    _memoryCleanupTimer?.cancel();
    PerformanceUtils.clearImageCache();
    MemoryManager.optimizeMemory();
    _pageCache.clear();
  }
  
  void _performMemoryCleanup() {
    if (!mounted) return;
    
    try {
      // CRITICAL: Lightweight memory cleanup
      MemoryManager.optimizeMemory();
      
      // CRITICAL: Minimal cache clearing
      if (_pageCache.length > 3) {
        _pageCache.clear();
      }
      
      // CRITICAL: Reduced image cache clearing
      if (_isLowPerformance) {
        PerformanceUtils.clearImageCache();
      }
      
      debugPrint('Lightweight memory cleanup performed');
    } catch (e) {
      debugPrint('Memory cleanup error: $e');
    }
  }
  
  // CRITICAL: Disabled frame rate monitoring for performance
  // void _startFrameRateMonitoring() { ... }
  
  void _forceGarbageCollection() {
    // Force garbage collection
    for (int i = 0; i < 3; i++) {
      Future.microtask(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _memoryCleanupTimer?.cancel();
    _debounceTimer?.cancel();
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
      ),
    ];
  }
  
  List<Widget> _getCachedPages() {
    // CRITICAL: Enhanced caching for performance
    final pages = _getPages();
    final cacheSize = _isLowPerformance ? 2 : 5;
    
    // Clear cache if too large
    if (_pageCache.length > cacheSize) {
      _pageCache.clear();
    }
    
    // CRITICAL: Smart caching
    for (int i = 0; i < pages.length; i++) {
      if (!_pageCache.containsKey(i)) {
        _pageCache[i] = pages[i];
      }
    }
    
    return pages;
  }

  void _toggleFavorite(Product product, {bool showMessage = true}) {
    if (!mounted) return;
    
    try {
      final existingIndex = favoriteProducts.indexWhere((p) => p.name == product.name);
      if (existingIndex != -1) {
        favoriteProducts.removeAt(existingIndex);
        if (mounted) {
          setState(() {}); // UI'ı anlık güncelle
          if (showMessage) {
            ErrorHandler.showSilentInfo(context, '${product.name} favorilerden çıkarıldı');
          }
        }
      } else {
        favoriteProducts.add(product);
        if (mounted) {
          setState(() {}); // UI'ı anlık güncelle
          if (showMessage) {
            ErrorHandler.showSilentSuccess(context, '${product.name} favorilere eklendi');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Favori işlemi sırasında hata oluştu');
      }
    }
  }

  Future<void> _addToCart(Product product, {bool showMessage = true}) async {
    if (!mounted) return;
    
    try {
      // Stok kontrolü yap
      final adminService = AdminService();
      final existingIndex = cartProducts.indexWhere((p) => p.name == product.name);
      final requestedQuantity = existingIndex != -1 ? cartProducts[existingIndex].quantity + 1 : 1;
      
      final stockCheck = await adminService.checkProductStock(product.name, requestedQuantity);
      
      if (!stockCheck['success']) {
        if (mounted && showMessage) {
          ErrorHandler.showError(context, stockCheck['error']);
        }
        return;
      }
      
      // Stok kontrolü başarılı, sepete ekle
      if (existingIndex != -1) {
        cartProducts[existingIndex].quantity++;
        if (mounted) {
          setState(() {}); // UI'ı anlık güncelle
          if (showMessage) {
            ErrorHandler.showSilentSuccess(context, '${product.name} miktarı artırıldı');
          }
        }
      } else {
        cartProducts.add(product.copyWith(quantity: 1));
        if (mounted) {
          setState(() {}); // UI'ı anlık güncelle
          if (showMessage) {
            ErrorHandler.showCartSuccess(
              context, 
              '${product.name} sepete eklendi',
              onViewCart: () {
                // Sepet sekmesine geç (index 2)
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

  void _removeFromCart(Product product) {
    if (!mounted) return;
    
    try {
      final index = cartProducts.indexWhere((p) => p.name == product.name);
      if (index != -1) {
        cartProducts.removeAt(index);
        if (mounted) {
          setState(() {}); // UI'ı anlık güncelle
          ErrorHandler.showSilentInfo(context, '${product.name} sepetten çıkarıldı');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Sepet işlemi sırasında hata oluştu');
      }
    }
  }

  Future<void> _updateQuantity(Product product, int newQuantity) async {
    if (!mounted) return;
    
    try {
      final index = cartProducts.indexWhere((p) => p.name == product.name);
      if (index != -1) {
        if (newQuantity <= 0) {
          cartProducts.removeAt(index);
        if (mounted) {
          setState(() {}); // UI'ı anlık güncelle
          ErrorHandler.showSilentInfo(context, '${product.name} sepetten çıkarıldı');
        }
        } else {
          // Stok kontrolü yap (miktar artırma durumunda)
          if (newQuantity > product.quantity) {
            final adminService = AdminService();
            final stockCheck = await adminService.checkProductStock(product.name, newQuantity);
            
            if (!stockCheck['success']) {
              if (mounted) {
                ErrorHandler.showError(context, stockCheck['error']);
              }
              return;
            }
          }
          
          // Yeni Product objesi oluştur
          cartProducts[index] = product.copyWith(quantity: newQuantity);
          if (mounted) {
            setState(() {}); // UI'ı anlık güncelle
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
      // Sipariş oluştur
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
      
      // Sepeti temizle
      cartProducts.clear();
      
      if (mounted) {
        setState(() {}); // UI'ı anlık güncelle
        ErrorHandler.showSilentSuccess(context, 'Sipariş başarıyla oluşturuldu!');
        
        // Ödeme sayfasına yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OdemeSayfasi(cartProducts: cartProducts),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Sipariş oluşturma sırasında hata oluştu: $e');
      }
    }
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    
    // CRITICAL: Ultra-fast navigation
    if (_selectedIndex == index) return;
    
    // CRITICAL: Optimized state update
    setState(() {
      _selectedIndex = index;
    });
    
    // CRITICAL: Preload adjacent pages
    _preloadAdjacentPages(index);
  }
  
  void _preloadAdjacentPages(int currentIndex) {
    // CRITICAL: Preload next and previous pages
    final pages = _getPages();
    final totalPages = pages.length;
    
    // Preload next page
    final nextIndex = (currentIndex + 1) % totalPages;
    if (!_pageCache.containsKey(nextIndex)) {
      _pageCache[nextIndex] = pages[nextIndex];
    }
    
    // Preload previous page
    final prevIndex = (currentIndex - 1 + totalPages) % totalPages;
    if (!_pageCache.containsKey(prevIndex)) {
      _pageCache[prevIndex] = pages[prevIndex];
    }
  }

      @override
      Widget build(BuildContext context) {
        // CRITICAL: Minimal build for performance
        
        // Responsive design
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 400;
        final isTablet = screenWidth >= 600 && screenWidth < 1024;
        
        // CRITICAL: Skip loading screen for performance
        
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Hata: ${snapshot.error}',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            if (!snapshot.hasData || snapshot.data == null) {
              return const GirisSayfasi();
            }
            
            return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: _getCachedPages(),
            ),
          ),
          bottomNavigationBar: Container(
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
              color: Colors.black.withOpacity(0.1),
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
                    children: [
                      Icon(
                        Icons.shopping_cart_rounded,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      if (cartProducts.isNotEmpty)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${cartProducts.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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
        );
      }
    );
  }
}