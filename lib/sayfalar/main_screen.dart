import 'package:flutter/material.dart';
import 'profil_sayfasi.dart';
import 'urunler_sayfasi.dart';
import 'favoriler_sayfasi.dart';
import 'sepet_sayfasi.dart';
import 'siparisler_sayfasi.dart';
import '../model/product.dart';
import '../model/order.dart';
import '../widgets/error_handler.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;

  final List<Product> favoriteProducts = [];
  final List<Product> cartProducts = [];
  final List<Order> orders = [];
  

  // Static olarak tanımlayarak her rebuild'de yeniden oluşturulmasını önleyelim
  static final List<Product> _dummyProducts = [
    Product(
        name: 'AUTOFresh Oto Bakım Seti',
        description:
            'Arabanızın iç ve dış temizliği için profesyonel bakım seti. Şampuan, cila, sünger ve mikrofiber bez dahil.',
        price: 299.99,
        imageUrl: 'assets/images/set.jpeg'),
    Product(
        name: 'Telefon Tutucu - Araç İçi',
        description:
            'Araç içi telefon tutucu. Vantuzlu montaj sistemi ile kolay kurulum. Ayarlanabilir açı ve güvenli kavrama.',
        price: 89.99,
        imageUrl: 'assets/images/telefon_tutucu.jpeg'),
    Product(
        name: 'Areon Bubble Gum Araç Kokusu',
        description:
            'Areon markasından bubble gum kokulu araç kokusu. Uzun süreli etkili ve hoş koku.',
        price: 45.50,
        imageUrl: 'assets/images/areon_arac_kokusu.jpeg'),
  ];

  
  @override
  bool get wantKeepAlive => true;


  @override
  void dispose() {
    // Memory leak önleme
    favoriteProducts.clear();
    cartProducts.clear();
    orders.clear();
    super.dispose();
  }

  List<Widget>? _pages;

  List<Widget> _getPages() {
    if (_pages != null) return _pages!;
    
    _pages = [
      UrunlerSayfasi(
        dummyProducts: _dummyProducts,
        onFavoriteToggle: _toggleFavorite,
        onAddToCart: _addToCart,
        favoriteProducts: favoriteProducts,
        cartProducts: cartProducts,
      ),
      FavorilerSayfasi(
        favoriteProducts: favoriteProducts,
        onFavoriteToggle: _toggleFavorite,
        onAddToCart: _addToCart,
        cartProducts: cartProducts,
      ),
      SepetSayfasi(
        cartProducts: cartProducts,
        onRemoveFromCart: _removeFromCart,
        onUpdateQuantity: _updateQuantity,
        onPlaceOrder: _placeOrder,
        favoriteProducts: favoriteProducts,
        onFavoriteToggle: _toggleFavorite,
        onAddToCart: _addToCart,
      ),
      SiparislerSayfasi(
        orders: orders,
        onOrderPlaced: _placeOrder,
      ),
      ProfilSayfasi(
        favoriteProducts: favoriteProducts,
        cartProducts: cartProducts,
        orders: orders,
      ),
    ];
    
    return _pages!;
  }

  void _toggleFavorite(Product product, {bool showMessage = true}) {
    if (!mounted) return;
    
    try {
      final existingIndex = favoriteProducts.indexWhere((p) => p.name == product.name);
      if (existingIndex != -1) {
        favoriteProducts.removeAt(existingIndex);
        if (mounted) {
          _pages = null; // Cache'i temizle
          setState(() {});
          if (showMessage) {
            ErrorHandler.showSilentInfo(context, '${product.name} favorilerden çıkarıldı');
          }
        }
      } else {
        favoriteProducts.add(product);
        if (mounted) {
          _pages = null; // Cache'i temizle
          setState(() {});
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

  void _addToCart(Product product, {bool showMessage = true}) {
    if (!mounted) return;
    
    try {
      final existingIndex = cartProducts.indexWhere((p) => p.name == product.name);
      
      if (existingIndex != -1) {
        cartProducts[existingIndex].quantity++;
        if (mounted) {
          _pages = null; // Cache'i temizle
          setState(() {});
          if (showMessage) {
            ErrorHandler.showSilentSuccess(context, '${product.name} miktarı artırıldı');
          }
        }
      } else {
        cartProducts.add(product.copyWith(quantity: 1));
        if (mounted) {
          _pages = null; // Cache'i temizle
          setState(() {});
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
        ErrorHandler.showError(context, 'Sepet işlemi sırasında hata oluştu');
      }
    }
  }

  void _removeFromCart(Product product) {
    if (!mounted) return;
    
    try {
      cartProducts.removeWhere((p) => p.name == product.name);
      if (mounted) {
        _pages = null; // Cache'i temizle
        setState(() {});
        ErrorHandler.showInfo(context, '${product.name} sepetten çıkarıldı');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Sepet işlemi sırasında hata oluştu');
      }
    }
  }

  void _updateQuantity(Product product, int newQuantity) {
    if (!mounted) return;
    
    try {
      final index = cartProducts.indexWhere((p) => p.name == product.name);
      if (index != -1) {
        if (newQuantity <= 0) {
          cartProducts.removeAt(index);
        if (mounted) {
          _pages = null; // Cache'i temizle
          setState(() {});
          ErrorHandler.showSilentInfo(context, '${product.name} sepetten çıkarıldı');
        }
        } else {
          // Yeni Product objesi oluştur
          cartProducts[index] = product.copyWith(quantity: newQuantity);
          if (mounted) {
            _pages = null; // Cache'i temizle
            setState(() {});
            ErrorHandler.showSilentSuccess(context, '${product.name} miktarı güncellendi');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Miktar güncelleme sırasında hata oluştu');
      }
    }
  }

  void _placeOrder(List<Product> products) {
    if (!mounted || products.isEmpty) return;
    
    try {
      final order = Order(
        id: 'ORD${DateTime.now().millisecondsSinceEpoch}',
        products: List<Product>.from(products),
        totalAmount: products.fold(0.0, (sum, p) => sum + p.totalPrice),
        orderDate: DateTime.now(),
        status: OrderStatus.pending,
        customerName: 'Misafir Kullanıcı',
        customerEmail: 'guest@tuning.com',
        shippingAddress: 'Teslimat adresi belirtilmedi',
      );
      
      orders.insert(0, order);
      cartProducts.clear();
      _selectedIndex = 3;
      
      if (mounted) {
        setState(() {});
        ErrorHandler.showSuccess(context, 'Siparişiniz başarıyla verildi!');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Sipariş verilirken hata oluştu');
      }
    }
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
  }

      @override
      Widget build(BuildContext context) {
        super.build(context); // AutomaticKeepAliveClientMixin için gerekli
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: _getPages()[_selectedIndex],
          ),
          bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: NavigationBar(
            height: 70,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            animationDuration: const Duration(milliseconds: 400),
            labelBehavior:
                NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.directions_car, color: Colors.grey.shade400),
                selectedIcon: Icon(Icons.directions_car, color: Colors.blue),
                label: 'Ürünler',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border, color: Colors.grey.shade400),
                selectedIcon: Icon(Icons.favorite, color: Colors.red),
                label: 'Favoriler',
              ),
              NavigationDestination(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        color: Colors.grey.shade400),
                    if (cartProducts.isNotEmpty)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '${cartProducts.fold(0, (sum, p) => sum + p.quantity)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                selectedIcon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.green),
                    if (cartProducts.isNotEmpty)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '${cartProducts.fold(0, (sum, p) => sum + p.quantity)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Sepet',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined,
                    color: Colors.grey.shade400),
                selectedIcon: Icon(Icons.receipt_long, color: Colors.orange),
                label: 'Siparişler',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline, color: Colors.grey.shade400),
                selectedIcon: Icon(Icons.person, color: Colors.purple),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
