import 'package:flutter/material.dart';
import '../model/product.dart';
import '../services/product_service.dart';
import '../widgets/optimized_image.dart';
import '../widgets/professional_components.dart';
import '../config/app_routes.dart';

class KategorilerSayfasi extends StatefulWidget {
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;
  final Function(Product) onFavoriteToggle;
  final Function(Product) onAddToCart;
  final Function(Product) onRemoveFromCart;

  const KategorilerSayfasi({
    super.key,
    required this.favoriteProducts,
    required this.cartProducts,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    required this.onRemoveFromCart,
  });

  @override
  State<KategorilerSayfasi> createState() => _KategorilerSayfasiState();
}

class _KategorilerSayfasiState extends State<KategorilerSayfasi> {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tümü';
  String _sortBy = 'Popülerlik';
  double _minPrice = 0;
  double _maxPrice = 10000;
  bool _showFilters = false;

  final List<CategoryItem> _categories = [
    CategoryItem(
      name: 'Tümü',
      icon: Icons.all_inclusive,
      color: Colors.blue,
      productCount: 0,
    ),
    CategoryItem(
      name: 'Araç Temizlik',
      icon: Icons.car_repair,
      color: Colors.green,
      productCount: 15,
    ),
    CategoryItem(
      name: 'Koku',
      icon: Icons.air,
      color: Colors.purple,
      productCount: 8,
    ),
    CategoryItem(
      name: 'Telefon Aksesuar',
      icon: Icons.phone_android,
      color: Colors.orange,
      productCount: 12,
    ),
    CategoryItem(
      name: 'Organizatör',
      icon: Icons.inventory,
      color: Colors.teal,
      productCount: 6,
    ),
    CategoryItem(
      name: 'Güvenlik',
      icon: Icons.security,
      color: Colors.red,
      productCount: 4,
    ),
  ];

  final List<String> _sortOptions = [
    'Popülerlik',
    'Fiyat (Düşük-Yüksek)',
    'Fiyat (Yüksek-Düşük)',
    'Yeni',
    'Değerlendirme',
    'Stok Durumu',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final productService = ProductService();
      final products = await productService.getAllProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _filteredProducts = List.from(_allProducts);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Firebase hatası durumunda boş liste
      _allProducts = [];
      _filteredProducts = [];
    }
  }

  void _filterProducts() {
    List<Product> filtered = _allProducts;

    // Kategori filtresi
    if (_selectedCategory != 'Tümü') {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    // Fiyat filtresi
    filtered = filtered.where((product) => 
        product.price >= _minPrice && product.price <= _maxPrice).toList();

    // Stok filtresi
    filtered = filtered.where((product) => product.stock > 0).toList();

    // Sıralama
    switch (_sortBy) {
      case 'Fiyat (Düşük-Yüksek)':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Fiyat (Yüksek-Düşük)':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Yeni':
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'Değerlendirme':
        filtered.shuffle(); // Demo için
        break;
      case 'Stok Durumu':
        filtered.sort((a, b) => b.stock.compareTo(a.stock));
        break;
    }

    if (!mounted) return;
    setState(() {
      _filteredProducts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    
    return Scaffold(
      resizeToAvoidBottomInset: false, // Klavye performansı için
      backgroundColor: Colors.grey[50],
      appBar: ProfessionalComponents.createAppBar(
        title: 'Kategoriler',
        actions: [
          IconButton(
            onPressed: () {
              if (!mounted) return;
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            tooltip: _showFilters ? 'Filtreleri Gizle' : 'Filtreleri Göster',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Kategori seçimi
                _buildCategorySelector(isSmallScreen, isTablet),
                
                // Filtreler
                if (_showFilters) 
                  Flexible(
                    child: SingleChildScrollView(
                      child: _buildFilters(isSmallScreen, isTablet, constraints.maxWidth),
                    ),
                  ),
                
                // Ürün listesi
                Expanded(
                  child: _isLoading
                      ? ProfessionalComponents.createLoadingIndicator(
                          message: 'Ürünler yükleniyor...',
                        )
                      : _filteredProducts.isEmpty
                          ? SingleChildScrollView(
                              child: ProfessionalComponents.createEmptyState(
                                title: 'Ürün Bulunamadı',
                                message: 'Seçilen kriterlere uygun ürün bulunamadı.',
                                icon: Icons.search_off,
                                buttonText: 'Filtreleri Temizle',
                                onButtonPressed: _clearFilters,
                              ),
                            )
                          : _buildProductGrid(isSmallScreen, isTablet, isDesktop),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isSmallScreen, bool isTablet) {
    return Container(
      height: isSmallScreen ? 100 : isTablet ? 115 : 120,
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category.name == _selectedCategory;
          
          // Responsive genişlik hesaplama
          final screenWidth = MediaQuery.of(context).size.width;
          double itemWidth;
          if (isSmallScreen) {
            itemWidth = (screenWidth - 48) / 4.5; // 4.5 kategori görünür
          } else if (isTablet) {
            itemWidth = (screenWidth - 64) / 5.5;
          } else {
            itemWidth = 110;
          }
          itemWidth = itemWidth.clamp(75.0, 120.0);
          
          return GestureDetector(
            onTap: () {
              if (!mounted) return;
              setState(() {
                _selectedCategory = category.name;
                _filterProducts();
              });
            },
            child: Container(
              width: itemWidth,
              margin: EdgeInsets.only(right: isSmallScreen ? 8 : 12),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 10,
                vertical: isSmallScreen ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: isSelected ? category.color : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? category.color : Colors.grey[300]!,
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    color: isSelected ? Colors.white : category.color,
                    size: isSmallScreen ? 24 : isTablet ? 28 : 30,
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Flexible(
                    child: Text(
                      category.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: isSmallScreen ? 10 : isTablet ? 11 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isSmallScreen) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${category.productCount}',
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.grey[600],
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters(bool isSmallScreen, bool isTablet, double maxWidth) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : isTablet ? 14 : 16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtreler',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 16 : 18,
                  color: Colors.grey[800],
                ),
              ),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  'Temizle',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Sıralama
          Text(
            'Sırala:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 13 : 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _sortBy,
            isDense: true,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 10 : 12,
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: _sortOptions.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (!mounted || value == null) return;
              setState(() {
                _sortBy = value;
                _filterProducts();
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // Fiyat aralığı
          Text(
            'Fiyat Aralığı',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 13 : 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    '${_minPrice.toInt()}₺',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.green[700],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    '${_maxPrice.toInt()}₺',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.green[700],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 10000,
            divisions: 100,
            labels: RangeLabels(
              '${_minPrice.toInt()}₺',
              '${_maxPrice.toInt()}₺',
            ),
            onChanged: (values) {
              if (!mounted) return;
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
                _filterProducts();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(bool isSmallScreen, bool isTablet, bool isDesktop) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = isDesktop ? 4 : isTablet ? 3 : 2;
    final bool veryNarrow = screenWidth < 360;
    
    // Responsive aspect ratio
    final double aspect = isDesktop
        ? 0.88
        : isTablet
            ? 0.82
            : veryNarrow
                ? 0.68
                : isSmallScreen
                    ? 0.75
                    : 0.78;

    return GridView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 8 : isTablet ? 12 : 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspect,
        crossAxisSpacing: isSmallScreen ? 6 : isTablet ? 10 : 12,
        mainAxisSpacing: isSmallScreen ? 6 : isTablet ? 10 : 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product, isSmallScreen, isTablet);
      },
    );
  }

  Widget _buildProductCard(Product product, bool isSmallScreen, bool isTablet) {
    final isFavorite = widget.favoriteProducts.any((p) => p.id == product.id);
    final inCart = widget.cartProducts.any((p) => p.id == product.id);

    return ProfessionalComponents.createCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ürün resmi
          Expanded(
            flex: 3,
            child: AspectRatio(
              aspectRatio: 1,
              child: GestureDetector(
                onTap: () {
                  AppRoutes.navigateToProductDetail(
                    context,
                    product,
                    favoriteProducts: widget.favoriteProducts,
                    cartProducts: widget.cartProducts,
                    onFavoriteToggle: widget.onFavoriteToggle,
                    onAddToCart: widget.onAddToCart,
                    onRemoveFromCart: widget.onRemoveFromCart,
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    OptimizedImage(
                      imageUrl: product.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // Stok durumu
                    if (product.stock < 10)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: ProfessionalComponents.createStatusBadge(
                          text: 'Az Stok',
                          type: StatusType.warning,
                          isSmall: true,
                        ),
                      ),
                    // Favori butonu
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        onPressed: () => widget.onFavoriteToggle(product),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.white,
                          size: isSmallScreen ? 18 : 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                          minimumSize: Size(isSmallScreen ? 32 : 36, isSmallScreen ? 32 : 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 6 : 8),
          
          // Ürün bilgileri
          Flexible(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 4 : 6,
                vertical: 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ürün adı
                  Flexible(
                    child: Text(
                      product.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : isTablet ? 14 : 15,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 3 : 4),
                  
                  // Fiyat
                  Text(
                    '${product.price.toStringAsFixed(2)} ₺',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : isTablet ? 15 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  
                  // Sepete ekle butonu
                  SizedBox(
                    width: double.infinity,
                    child: ProfessionalComponents.createButton(
                      text: inCart ? 'Sepette' : 'Sepete Ekle',
                      onPressed: () => widget.onAddToCart(product),
                      type: inCart ? ButtonType.success : ButtonType.primary,
                      size: isSmallScreen ? ButtonSize.small : ButtonSize.medium,
                      icon: inCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    if (!mounted) return;
    setState(() {
      _selectedCategory = 'Tümü';
      _sortBy = 'Popülerlik';
      _minPrice = 0;
      _maxPrice = 10000;
      _filterProducts();
    });
  }
}

class CategoryItem {
  final String name;
  final IconData icon;
  final Color color;
  final int productCount;

  CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.productCount,
  });
}
