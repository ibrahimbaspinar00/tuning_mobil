import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/product.dart';
import '../widgets/optimized_image.dart';
import '../widgets/animated_button.dart';
import '../widgets/error_handler.dart';
import '../utils/debounce.dart';
import '../widgets/recommended_products.dart';
import 'urun_detay_sayfasi.dart';

class FavorilerSayfasi extends StatefulWidget {
  final List<Product> favoriteProducts;
  final Function(Product, {bool showMessage}) onFavoriteToggle;
  final Function(Product, {bool showMessage})? onAddToCart;
  final List<Product>? cartProducts;

  const FavorilerSayfasi({
    super.key,
    required this.favoriteProducts,
    required this.onFavoriteToggle,
    this.onAddToCart,
    this.cartProducts,
  });

  @override
  State<FavorilerSayfasi> createState() => _FavorilerSayfasiState();
}

class _FavorilerSayfasiState extends State<FavorilerSayfasi> with TickerProviderStateMixin {
  String _searchQuery = '';
  String _sortBy = 'name';
  late Debounce _searchDebounce;
  late TabController _tabController;
  String _collectionSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchDebounce = Debounce(delay: const Duration(milliseconds: 500));
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1); // Koleksiyonlarım sekmesinde başla
    _tabController.addListener(() {
      setState(() {
        // Sekme değiştiğinde arama kutusunu temizle
        _searchQuery = '';
        _collectionSearchQuery = '';
      });
    });
    // FocusNode'u hemen aktif et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
        _searchFocusNode.unfocus();
      }
    });
  }

  @override
  void didUpdateWidget(FavorilerSayfasi oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Favori ürünler değiştiğinde UI'ı güncelle
    if (widget.favoriteProducts.length != oldWidget.favoriteProducts.length ||
        widget.favoriteProducts != oldWidget.favoriteProducts) {
      setState(() {});
    }
  }


  @override
  void dispose() {
    _searchDebounce.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Product> get _filteredProducts {
    var products = widget.favoriteProducts;
    
    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      products = products.where((product) =>
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Sıralama
    switch (_sortBy) {
      case 'name':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_asc':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'date':
        // Tarih sıralaması için demo
        products = products.reversed.toList();
        break;
    }
    
    return products;
  }

  List<Map<String, dynamic>> get _filteredCollections {
    // Demo koleksiyonlar
    final collections = [
      {
        'id': '1',
        'name': 'Araç Temizlik Ürünleri',
        'description': 'Araç temizliği için gerekli tüm ürünler',
        'productCount': 5,
        'color': Colors.blue,
        'icon': Icons.car_repair,
      },
      {
        'id': '2',
        'name': 'Telefon Aksesuarları',
        'description': 'Telefon için kullanışlı aksesuarlar',
        'productCount': 3,
        'color': Colors.green,
        'icon': Icons.phone_android,
      },
      {
        'id': '3',
        'name': 'Güvenlik Ürünleri',
        'description': 'Araç güvenliği için önemli ürünler',
        'productCount': 2,
        'color': Colors.red,
        'icon': Icons.security,
      },
    ];

    var filteredCollections = collections;
    
    // Koleksiyon arama filtresi
    if (_collectionSearchQuery.isNotEmpty) {
      filteredCollections = collections.where((collection) =>
          collection['name'].toString().toLowerCase().contains(_collectionSearchQuery.toLowerCase()) ||
          collection['description'].toString().toLowerCase().contains(_collectionSearchQuery.toLowerCase())
      ).toList();
    }
    
    return filteredCollections;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'Listelerim',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : isTablet ? 18 : 20,
          ),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Beğendiklerim',
            ),
            Tab(
              icon: Icon(Icons.collections),
              text: 'Koleksiyonlarım',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Arama çubuğu
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
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
            ),
            // TabBarView
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue[50]!, Colors.grey[50]!],
                  ),
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Beğendiklerim sekmesi
                    _buildFavoritesTab(),
                    // Koleksiyonlarım sekmesi
                    _buildCollectionsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Column(
      children: [
        // Arama çubuğu
        Container(
          margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              _searchDebounce(() {
                setState(() {
                  _searchQuery = value;
                });
              });
            },
            decoration: InputDecoration(
              hintText: 'Favori ürünlerinizde ara...',
              hintStyle: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.blue,
                size: isSmallScreen ? 18 : 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.blue,
                        size: isSmallScreen ? 16 : 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 8 : 12,
              ),
            ),
          ),
        ),
        
        // Ürün sayısı
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _searchQuery.isNotEmpty
                    ? '${_filteredProducts.length} arama sonucu'
                    : '${widget.favoriteProducts.length} favori ürün',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : isTablet ? 14 : 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_searchQuery.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    try {
                      setState(() {
                        _searchQuery = '';
                      });
                      ErrorHandler.showSilentInfo(
                        context, 
                        'Arama temizlendi'
                      );
                    } catch (e) {
                      ErrorHandler.showError(
                        context, 
                        'Arama temizlenirken hata oluştu'
                      );
                    }
                  },
                  icon: Icon(
                    Icons.clear,
                    size: isSmallScreen ? 14 : 18,
                  ),
                  label: Text(
                    'Temizle',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                  ),
                ),
            ],
          ),
        ),
        
        SizedBox(height: isSmallScreen ? 4 : 8),
        
        // Ürün listesi
        Expanded(
          child: _filteredProducts.isEmpty
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      // Boş favori mesajı
                      SizedBox(
                        height: isSmallScreen ? 200 : isTablet ? 250 : 300,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: isSmallScreen ? 60 : isTablet ? 80 : 100,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 20),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Arama kriterlerinize uygun ürün bulunamadı'
                                    : 'Henüz favori ürününüz yok',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : isTablet ? 16 : 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_searchQuery.isEmpty) ...[
                                SizedBox(height: isSmallScreen ? 8 : 12),
                                Text(
                                  'Beğendiğiniz ürünleri favorilere ekleyin',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : isTablet ? 14 : 16,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Önerilen ürünler
                      if (_searchQuery.isEmpty)
                        RecommendedProducts(
                          products: widget.favoriteProducts,
                          onToggleFavorite: widget.onFavoriteToggle,
                          onAddToCart: widget.onAddToCart ?? (p) {},
                          favoriteProducts: widget.favoriteProducts,
                        ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isSmallScreen ? 2 : isTablet ? 3 : 4,
                    childAspectRatio: isSmallScreen ? 0.75 : isTablet ? 0.8 : 0.85,
                    crossAxisSpacing: isSmallScreen ? 8 : 12,
                    mainAxisSpacing: isSmallScreen ? 8 : 12,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return _buildProductCard(product, isSmallScreen, isTablet);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product, bool isSmallScreen, bool isTablet) {
    final inCart = widget.cartProducts?.any((p) => p.name == product.name) ?? false;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UrunDetaySayfasi(
                product: product,
                onFavoriteToggle: widget.onFavoriteToggle,
                onAddToCart: widget.onAddToCart ?? (p) {},
                favoriteProducts: widget.favoriteProducts,
                cartProducts: widget.cartProducts ?? [],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ürün resmi
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: OptimizedImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            
            // Ürün bilgileri
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ürün adı
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : isTablet ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Fiyat
                    Text(
                      '${product.price.toStringAsFixed(2)} ₺',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : isTablet ? 13 : 15,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Butonlar
                    Row(
                      children: [
                        // Favori butonu
                        Expanded(
                          child: AnimatedButton(
                            onPressed: () => widget.onFavoriteToggle(product),
                            child: Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Sepete ekle butonu
                        Expanded(
                          child: AnimatedButton(
                            onPressed: () {
                              if (widget.onAddToCart != null) {
                                widget.onAddToCart!(product);
                              }
                            },
                            child: Icon(
                              inCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                              color: inCart ? Colors.green : Colors.blue,
                              size: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionsTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Column(
      children: [
        // Arama çubuğu
        Container(
          margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            onChanged: (value) {
              _searchDebounce(() {
                setState(() {
                  _collectionSearchQuery = value;
                });
              });
            },
            decoration: InputDecoration(
              hintText: 'Koleksiyonlarınızda ara...',
              hintStyle: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.blue,
                size: isSmallScreen ? 18 : 20,
              ),
              suffixIcon: _collectionSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.blue,
                        size: isSmallScreen ? 16 : 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _collectionSearchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 8 : 12,
              ),
            ),
          ),
        ),
        
        // Arama sonucu sayısı
        if (_collectionSearchQuery.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredCollections.length} arama sonucu',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : isTablet ? 14 : 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _collectionSearchQuery = '';
                    });
                  },
                  icon: Icon(
                    Icons.clear,
                    size: isSmallScreen ? 14 : 18,
                  ),
                  label: Text(
                    'Temizle',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        
        SizedBox(height: isSmallScreen ? 4 : 8),
        
        // Hızlı aksiyonlar
        Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _createNewCollection,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Yeni Koleksiyon'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showCollectionOptions,
                  icon: const Icon(Icons.more_horiz, size: 18),
                  label: const Text('Seçenekler'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: isSmallScreen ? 8 : 12),
        
        // Koleksiyon istatistikleri
        _buildCollectionStats(),
        
        SizedBox(height: isSmallScreen ? 8 : 12),
        
        // Koleksiyonlar listesi
        Expanded(
          child: _buildCollectionsList(),
        ),
      ],
    );
  }

  Widget _buildCollectionsList() {
    final collections = _filteredCollections;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    if (collections.isEmpty && _collectionSearchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Arama kriterlerinize uygun koleksiyon bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı anahtar kelimeler deneyin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final collection = collections[index];
        return Card(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: InkWell(
            onTap: () => _openCollection(collection['id'] as String),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    (collection['color'] as Color).withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: isSmallScreen ? 45 : 55,
                    height: isSmallScreen ? 45 : 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (collection['color'] as Color).withOpacity(0.2),
                          (collection['color'] as Color).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: (collection['color'] as Color).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      collection['icon'] as IconData,
                      color: collection['color'] as Color,
                      size: isSmallScreen ? 22 : 28,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection['name'] as String,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 15 : 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 3 : 4),
                        Text(
                          collection['description'] as String,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 6 : 8,
                                vertical: isSmallScreen ? 2 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: (collection['color'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${collection['productCount']} ürün',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  color: collection['color'] as Color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey[400],
                              size: isSmallScreen ? 14 : 16,
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
      },
    );
  }

  void _createNewCollection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Koleksiyon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Koleksiyon Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Koleksiyon oluşturuldu!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _openCollection(String collectionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Koleksiyon Detayı'),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.collections,
                  size: 80,
                  color: Colors.blue[300],
                ),
                const SizedBox(height: 20),
                Text(
                  'Koleksiyon ID: $collectionId',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Bu koleksiyonun detayları yakında eklenecek!',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCollectionOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Koleksiyonları Sırala'),
              onTap: () {
                Navigator.pop(context);
                _showSortOptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text('Filtrele'),
              onTap: () {
                Navigator.pop(context);
                _showFilterOptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.import_export),
              title: const Text('Dışa Aktar'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dışa aktarma özelliği yakında!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ayarlar'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Koleksiyon ayarları yakında!'),
                    backgroundColor: Colors.grey,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sıralama Seçenekleri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Ada Göre (A-Z)'),
              value: 'name_asc',
              groupValue: 'name_asc',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('Ada Göre (Z-A)'),
              value: 'name_desc',
              groupValue: 'name_asc',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('Tarihe Göre (Yeni)'),
              value: 'date_desc',
              groupValue: 'name_asc',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('Ürün Sayısına Göre'),
              value: 'product_count',
              groupValue: 'name_asc',
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sıralama uygulandı!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtre Seçenekleri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Boş Koleksiyonlar'),
              value: false,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Son 7 Gün'),
              value: false,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Favori Koleksiyonlar'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Temizle'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filtreler uygulandı!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionStats() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Toplam',
              '${_filteredCollections.length}',
              Icons.collections,
              Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.blue[200],
          ),
          Expanded(
            child: _buildStatItem(
              'Ürünler',
              '12',
              Icons.inventory,
              Colors.green,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.blue[200],
          ),
          Expanded(
            child: _buildStatItem(
              'Favori',
              '3',
              Icons.favorite,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }


}