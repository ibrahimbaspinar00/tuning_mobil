import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/product.dart';
import '../services/admin_service.dart';
import '../widgets/optimized_image.dart';
import '../widgets/professional_components.dart';
import '../utils/professional_animations.dart';
import 'urun_detay_sayfasi.dart';

class AnaSayfa extends StatefulWidget {
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;
  final Function(Product) onFavoriteToggle;
  final Function(Product) onAddToCart;

  const AnaSayfa({
    super.key,
    required this.favoriteProducts,
    required this.cartProducts,
    required this.onFavoriteToggle,
    required this.onAddToCart,
  });

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  String _sortBy = 'Popülerlik';

  final List<String> _categories = [
    'Tümü',
    'Araç Temizlik',
    'Koku',
    'Telefon Aksesuar',
    'Organizatör',
    'Güvenlik',
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
    // FocusNode'u hemen aktif et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
        _searchFocusNode.unfocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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


  void _performSearch(String query) {
    if (!mounted) return;
    setState(() {
      _searchQuery = query;
      _filterProducts();
    });
  }

  void _filterProducts() {
    List<Product> filtered = _allProducts;

    // Kategori filtresi
    if (_selectedCategory != 'Tümü') {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) =>
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

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
        // Demo için rastgele sıralama
        filtered.shuffle();
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
              // Bildirimler
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            onPressed: () {
              // Sepet
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
      body: Column(
        children: [
          // Arama ve Filtreler
          _buildSearchAndFilters(),
          
          // Ürün Listesi
          Expanded(
            child: _isLoading
                ? ProfessionalComponents.createLoadingIndicator(
                    message: 'Ürünler yükleniyor...',
                  )
                : _filteredProducts.isEmpty
                    ? ProfessionalComponents.createEmptyState(
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
                    : _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Arama çubuğu
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _performSearch,
            onTap: () {
              // Focus'u zorla koru
              _searchFocusNode.requestFocus();
              // Klavye açılmasını zorla
              SystemChannels.textInput.invokeMethod('TextInput.show');
            },
            decoration: InputDecoration(
              hintText: 'Ürün ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
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
    final childAspectRatio = screenWidth > 600 ? 0.7 : 0.75;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
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
                onFavoriteToggle: widget.onFavoriteToggle,
                onAddToCart: widget.onAddToCart,
                favoriteProducts: widget.favoriteProducts,
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
                      children: [
                        // Favori butonu
                        Expanded(
                          child: SizedBox(
                            height: isSmallScreen ? 28 : 32,
                            child: ElevatedButton.icon(
                              onPressed: () => widget.onFavoriteToggle(product),
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                size: isSmallScreen ? 14 : 16,
                              ),
                              label: Text(
                                isFavorite ? 'Favoride' : 'Favori',
                                style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
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
                        
                        const SizedBox(width: 4),
                        
                        // Sepete ekle butonu
                        Expanded(
                          child: SizedBox(
                            height: isSmallScreen ? 28 : 32,
                            child: ElevatedButton.icon(
                              onPressed: () => widget.onAddToCart(product),
                              icon: Icon(
                                inCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                                size: isSmallScreen ? 14 : 16,
                              ),
                              label: Text(
                                inCart ? 'Sepette' : 'Sepete',
                                style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: inCart ? Colors.green[50] : Colors.blue[50],
                                foregroundColor: inCart ? Colors.green : Colors.blue[700],
                                elevation: 0,
                                padding: EdgeInsets.zero,
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
}
