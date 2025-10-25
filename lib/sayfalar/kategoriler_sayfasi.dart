import 'package:flutter/material.dart';
import '../model/product.dart';
import '../services/admin_service.dart';
import '../widgets/optimized_image.dart';
import '../widgets/professional_components.dart';
import '../utils/professional_animations.dart';
import 'urun_detay_sayfasi.dart';

class KategorilerSayfasi extends StatefulWidget {
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;
  final Function(Product) onFavoriteToggle;
  final Function(Product) onAddToCart;

  const KategorilerSayfasi({
    super.key,
    required this.favoriteProducts,
    required this.cartProducts,
    required this.onFavoriteToggle,
    required this.onAddToCart,
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
      final products = await AdminService().getProducts().first;
      if (!mounted) return;
      setState(() {
        _allProducts = products.map((adminProduct) => Product(
          id: adminProduct.id,
          name: adminProduct.name,
          price: adminProduct.price,
          description: adminProduct.description,
          imageUrl: adminProduct.imageUrl,
          category: adminProduct.category,
          stock: adminProduct.stock,
        )).toList();
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
    return Scaffold(
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
          ),
        ],
      ),
      body: Column(
        children: [
          // Kategori seçimi
          _buildCategorySelector(),
          
          // Filtreler
          if (_showFilters) _buildFilters(),
          
          // Ürün listesi
          Expanded(
            child: _isLoading
                ? ProfessionalComponents.createLoadingIndicator(
                    message: 'Ürünler yükleniyor...',
                  )
                : _filteredProducts.isEmpty
                    ? ProfessionalComponents.createEmptyState(
                        title: 'Ürün Bulunamadı',
                        message: 'Seçilen kriterlere uygun ürün bulunamadı.',
                        icon: Icons.search_off,
                        buttonText: 'Filtreleri Temizle',
                        onButtonPressed: _clearFilters,
                      )
                    : _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category.name == _selectedCategory;
          
          return GestureDetector(
            onTap: () {
              if (!mounted) return;
              setState(() {
                _selectedCategory = category.name;
                _filterProducts();
              });
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? category.color : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? category.color : Colors.grey[300]!,
                  width: 2,
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
                children: [
                  Icon(
                    category.icon,
                    color: isSelected ? Colors.white : category.color,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.productCount}',
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Sıralama
          Row(
            children: [
               const Text('Sırala:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
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
          
          const SizedBox(height: 16),
          
          // Fiyat aralığı
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fiyat: ${_minPrice.toInt()}₺ - ${_maxPrice.toInt()}₺',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: 10000,
                divisions: 100,
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
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: screenWidth > 600 ? 0.7 : 0.75,
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

    return ProfessionalComponents.createCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ürün resmi
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  ProfessionalAnimations.createScaleRoute(
                    UrunDetaySayfasi(
                      product: product,
                      onFavoriteToggle: widget.onFavoriteToggle,
                      onAddToCart: widget.onAddToCart,
                      favoriteProducts: widget.favoriteProducts,
                      cartProducts: widget.cartProducts,
                    ),
                  ),
                );
              },
              child: Stack(
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
                      top: 8,
                      left: 8,
                      child: ProfessionalComponents.createStatusBadge(
                        text: 'Az Stok',
                        type: StatusType.warning,
                        isSmall: true,
                      ),
                    ),
                  // Favori butonu
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => widget.onFavoriteToggle(product),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Ürün bilgileri
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  '${product.price.toStringAsFixed(2)} ₺',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Sepete ekle butonu
                SizedBox(
                  width: double.infinity,
                  child: ProfessionalComponents.createButton(
                    text: inCart ? 'Sepette' : 'Sepete Ekle',
                    onPressed: () => widget.onAddToCart(product),
                    type: inCart ? ButtonType.success : ButtonType.primary,
                    size: ButtonSize.small,
                    icon: inCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                  ),
                ),
              ],
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