import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../model/product.dart';
import '../services/product_service.dart';
import '../widgets/optimized_image.dart';
import '../widgets/professional_components.dart';
import '../utils/professional_animations.dart';
import 'urun_detay_sayfasi.dart';
import 'bildirimler_sayfasi.dart';

class AnaSayfa extends StatefulWidget {
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;
  final Function(Product) onFavoriteToggle;
  final Function(Product) onAddToCart;
  final Function(Product) onRemoveFromCart;
  final VoidCallback? onNavigateToCart;

  const AnaSayfa({
    super.key,
    required this.favoriteProducts,
    required this.cartProducts,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    this.onNavigateToCart,
  });

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  // FocusNode kaldırıldı - klavye sorunu için
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Product> _popularProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  String _sortBy = 'Popülerlik';
  Timer? _searchDebounceTimer;
  Timer? _autoScrollTimer;
  Timer? _updateTimer;
  ScrollController _popularProductsScrollController = ScrollController();
  int _currentPopularIndex = 0;
  bool _isUserScrolling = false;
  
  // Services
  final ProductService _productService = ProductService();

  final List<String> _categories = [
    'Tümü',
    'Araç Temizlik',
    'Telefon Aksesuar',
    'Elektronik',
    'Araç Aksesuar',
    'Güvenlik',
    'Performans',
  ];

  final List<String> _sortOptions = [
    'Popülerlik',
    'Fiyat (Düşük-Yüksek)',
    'Fiyat (Yüksek-Düşük)',
    'Yeni',
    'Değerlendirme',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadSpecialProducts();
    _startContinuousUpdates();
    // Otomatik scroll kapatıldı - klavye sorunu için
    // _setupScrollListener();
    // _setupFocusListener();
    
    // Otomatik scroll tamamen kapatıldı
    // Timer(const Duration(seconds: 2), () {
    //   if (mounted) {
    //     _startAutoScroll();
    //   }
    // });
  }

  // _setupFocusListener kaldırıldı - klavye sorunu için

  @override
  void dispose() {
    _searchController.dispose();
    // FocusNode kaldırıldı - klavye sorunu için
    _searchDebounceTimer?.cancel();
    // Otomatik scroll kapatıldı
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // ProductService'den ürünleri yükle
      final products = await _productService.getAllProducts();
      
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _filteredProducts = List.from(products);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Hata durumunda boş liste
      _allProducts = [];
      _filteredProducts = [];
    }
  }

  Future<void> _loadSpecialProducts() async {
    try {
      // En çok alınan ve yorumu yüksek olan ürünleri yükle
      final popular = await _productService.getPopularProducts(limit: 10);
      
      if (mounted) {
        setState(() {
          _popularProducts = popular;
        });
        
        // Otomatik scroll kapatıldı - klavye sorunu için
      }
    } catch (e) {
      debugPrint('Error loading special products: $e');
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || _popularProducts.isEmpty) return;
      
      if (_popularProductsScrollController.hasClients) {
        _currentPopularIndex = (_currentPopularIndex + 1) % _popularProducts.length;
        
        // ListView için doğru scroll pozisyonu hesaplama
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 400;
        final itemWidth = (screenWidth - (isSmallScreen ? 24 : 32)) / (isSmallScreen ? 2 : 3);
        final spacing = 12.0;
        
        // Her item için scroll pozisyonunu hesapla
        final scrollPosition = _currentPopularIndex * (itemWidth + spacing);
        
        // Daha hızlı ve belirgin animasyon
        _popularProductsScrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startContinuousUpdates() {
    _updateTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (!mounted) return;
      _loadSpecialProducts();
    });
  }

  void _setupScrollListener() {
    _popularProductsScrollController.addListener(() {
      // Kullanıcı scroll yapıyorsa otomatik scroll'u durdur
      if (_popularProductsScrollController.position.isScrollingNotifier.value) {
        _isUserScrolling = true;
        _autoScrollTimer?.cancel();
        
        // 5 saniye sonra otomatik scroll'u tekrar başlat
        Timer(const Duration(seconds: 5), () {
          if (mounted && !_isUserScrolling) {
            _startAutoScroll();
          }
        });
      } else {
        // Scroll bittiğinde flag'i temizle
        Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            _isUserScrolling = false;
          }
        });
      }
    });
  }


  void _performSearch(String query) {
    // Önceki timer'ı iptal et
    _searchDebounceTimer?.cancel();
    
    // Yeni timer başlat (500ms debounce - daha uzun)
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
        _filterProducts();
      });
    });
  }

  void _navigateToCart() {
    // Sepet sayfasına yönlendir
    if (widget.onNavigateToCart != null) {
      widget.onNavigateToCart!();
    } else {
      // Fallback: SnackBar göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sepet sayfasına yönlendiriliyor...'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _filterProducts() {
    // Performance optimization: Use cached filtered list
    List<Product> filtered = List.from(_allProducts);

    // Kategori filtresi - optimize with early return
    if (_selectedCategory != 'Tümü') {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    // Arama filtresi - optimize with cached lowercase
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      if (query.isNotEmpty) {
        filtered = filtered.where((product) {
          final name = product.name.toLowerCase();
          final description = product.description.toLowerCase();
          return name.contains(query) || description.contains(query);
        }).toList();
      }
    }

    // Sıralama - optimize with stable sort
    switch (_sortBy) {
      case 'Popülerlik':
        // Popülerlik skoru = satış sayısı * 0.4 + yorum sayısı * 0.3 + ortalama puan * 10 * 0.3
        filtered.sort((a, b) {
          final scoreA = (a.salesCount * 0.4) + (a.reviewCount * 0.3) + (a.averageRating * 10 * 0.3);
          final scoreB = (b.salesCount * 0.4) + (b.reviewCount * 0.3) + (b.averageRating * 10 * 0.3);
          return scoreB.compareTo(scoreA);
        });
        break;
      case 'Fiyat (Düşük-Yüksek)':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Fiyat (Yüksek-Düşük)':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Yeni':
        // ID'ye göre sıralama (demo için - gerçek uygulamada createdAt kullanılmalı)
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'Değerlendirme':
        // Ortalama puana göre sıralama
        filtered.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
    }

    if (!mounted) return;
    setState(() {
      _filteredProducts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,
      appBar: ProfessionalComponents.createAppBar(
        title: 'Tuning Store',
        actions: [
          IconButton(
            onPressed: () {
              // Bildirimler sayfasına yönlendir
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BildirimlerSayfasi(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            onPressed: () {
              // Sepet sayfasına yönlendir (index 2)
              _navigateToCart();
            },
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart_outlined),
                if (widget.cartProducts.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${widget.cartProducts.length}',
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
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = MediaQuery.of(context).viewInsets;
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: (insets.bottom > 0 ? insets.bottom : 0) + 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  minWidth: constraints.maxWidth,
                ),
                child: Column(
                  children: [
            // Arama ve Filtreler
            _buildSearchAndFilters(),
            
            // Popüler Ürünler
            if (!_isLoading) ...[
              _buildSpecialProductsSection(),
            ],
            
            // Ürün Listesi
            if (_isLoading)
              ProfessionalComponents.createLoadingIndicator(
                message: 'Ürünler yükleniyor...',
              )
            else if (_filteredProducts.isEmpty)
              ProfessionalComponents.createEmptyState(
                title: 'Ürün Bulunamadı',
                message: 'Arama kriterlerinize uygun ürün bulunamadı.',
                icon: Icons.search_off,
                buttonText: 'Filtreleri Temizle',
                onButtonPressed: () {
                  if (!mounted) return;
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = 'Tümü';
                    _searchController.clear();
                    _filterProducts();
                  });
                },
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildProductGrid(),
              ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Arama çubuğu - En basit hali
          TextField(
            controller: _searchController,
            onChanged: _performSearch,
            decoration: InputDecoration(
              hintText: 'Ürün ara...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Kategori ve Sıralama
          Row(
            children: [
              // Kategori dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                   decoration: const InputDecoration(
                     labelText: 'Kategori',
                     border: OutlineInputBorder(),
                     contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     isDense: true,
                   ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                       child: Text(
                         category,
                         style: const TextStyle(fontSize: 12),
                         overflow: TextOverflow.ellipsis,
                       ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (!mounted) return;
                    setState(() {
                      _selectedCategory = value!;
                      _filterProducts();
                    });
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Sıralama dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                   decoration: const InputDecoration(
                     labelText: 'Sırala',
                     border: OutlineInputBorder(),
                     contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     isDense: true,
                   ),
                  items: _sortOptions.map((option) {
                    return DropdownMenuItem(
                      value: option,
                       child: Text(
                         option,
                         style: const TextStyle(fontSize: 12),
                         overflow: TextOverflow.ellipsis,
                       ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (!mounted) return;
                    setState(() {
                      _sortBy = value!;
                      _filterProducts();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final childAspectRatio = screenWidth > 600 ? 0.75 : 0.8;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final isFavorite = widget.favoriteProducts.any((p) => p.id == product.id);
    final inCart = widget.cartProducts.any((p) => p.id == product.id);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            ProfessionalAnimations.createScaleRoute(
              UrunDetaySayfasi(
                product: product,
                favoriteProducts: widget.favoriteProducts,
                onFavoriteToggle: widget.onFavoriteToggle,
                onAddToCart: widget.onAddToCart,
                onRemoveFromCart: widget.onRemoveFromCart,
                cartProducts: widget.cartProducts,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ürün resmi
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: OptimizedImage(
                    imageUrl: product.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Ürün bilgileri
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      '${product.price.toStringAsFixed(2)} ₺',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Butonlar
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Favori butonu - Animasyonlu
                        Expanded(
                          child: SizedBox(
                            height: isSmallScreen ? 28 : 32,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Haptic feedback
                                  HapticFeedback.lightImpact();
                                  // Anlık görsel geri bildirim
                                  setState(() {});
                                  // Favori işlemi
                                  widget.onFavoriteToggle(product);
                                },
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    key: ValueKey(isFavorite),
                                    size: isSmallScreen ? 14 : 16,
                                    color: isFavorite ? Colors.red : Colors.grey[700],
                                  ),
                                ),
                                label: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    isFavorite ? 'Favoride' : 'Favori',
                                    key: ValueKey(isFavorite),
                                    style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFavorite ? Colors.red[50] : Colors.grey[50],
                                  foregroundColor: isFavorite ? Colors.red : Colors.grey[700],
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 4),
                        
                        // Sepete ekle butonu - Animasyonlu
                        Expanded(
                          child: SizedBox(
                            height: isSmallScreen ? 28 : 32,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Haptic feedback
                                  HapticFeedback.lightImpact();
                                  // Anlık görsel geri bildirim
                                  setState(() {});
                                  // Sepet işlemi
                                  if (inCart) {
                                    widget.onRemoveFromCart(product);
                                  } else {
                                    widget.onAddToCart(product);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: inCart ? Colors.green[50] : Colors.blue[50],
                                  foregroundColor: inCart ? Colors.green : Colors.blue[700],
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      child: Icon(
                                        inCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                                        key: ValueKey(inCart),
                                        size: isSmallScreen ? 12 : 14,
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 2 : 4),
                                    Flexible(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        child: Text(
                                          inCart ? 'Sepette' : 'Sepete',
                                          key: ValueKey(inCart),
                                          style: TextStyle(fontSize: isSmallScreen ? 9 : 10),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialProductsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
            child: Text(
              '🔥 Popüler Ürünler',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // Ürünler - Basit ListView (otomatik scroll kapatıldı)
          SizedBox(
            height: _calculatePopularProductsHeight(),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _popularProducts.length,
              itemBuilder: (context, index) {
                final product = _popularProducts[index];
                final screenWidth = MediaQuery.of(context).size.width;
                final isSmallScreen = screenWidth < 400;
                final itemWidth = (screenWidth - (isSmallScreen ? 24 : 32)) / (isSmallScreen ? 2 : 3);
                
                return Container(
                  width: itemWidth,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildProductCard(product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  double _calculatePopularProductsHeight() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    // Ana ürün grid'i ile aynı hesaplama
    final crossAxisCount = isSmallScreen ? 2 : 3;
    final childAspectRatio = isSmallScreen ? 0.75 : 0.8;
    
    // Grid yüksekliğini hesapla
    final availableWidth = screenWidth - (isSmallScreen ? 24 : 32); // padding
    final itemWidth = (availableWidth - (crossAxisCount - 1) * 12) / crossAxisCount;
    final itemHeight = itemWidth / childAspectRatio;
    
    return itemHeight + 24; // padding için ekstra alan
  }



}
