import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/product.dart';
import '../model/collection.dart';
import '../widgets/optimized_image.dart';
import '../widgets/error_handler.dart';
import '../utils/debounce.dart';
import '../widgets/recommended_products.dart';
import '../utils/professional_animations.dart';
import '../services/collection_service.dart';
import 'urun_detay_sayfasi.dart';
import 'koleksiyon_detay_sayfasi.dart';

class FavorilerSayfasi extends StatefulWidget {
  final List<Product> favoriteProducts;
  final Function(Product, {bool showMessage}) onFavoriteToggle;
  final Function(Product, {bool showMessage})? onAddToCart;
  final List<Product>? cartProducts;
  final VoidCallback? onNavigateToMainPage;

  const FavorilerSayfasi({
    super.key,
    required this.favoriteProducts,
    required this.onFavoriteToggle,
    this.onAddToCart,
    this.cartProducts,
    this.onNavigateToMainPage,
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
  
  final CollectionService _collectionService = CollectionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Collection> _collections = [];
  bool _isLoadingCollections = false;

  @override
  void initState() {
    super.initState();
    _searchDebounce = Debounce(delay: const Duration(milliseconds: 500));
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {
        _searchQuery = '';
        _collectionSearchQuery = '';
      });
      if (_tabController.index == 1) {
        _loadCollections();
      }
    });
    _loadCollections();
    
    // Klavye performansı için TextField'ı önceden hazırla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // FocusNode'u önceden hazırla - klavye açılışını hızlandırır
        _searchFocusNode.canRequestFocus;
      }
    });
  }

  Future<void> _loadCollections() async {
    if (_auth.currentUser == null) {
      setState(() => _collections = []);
      return;
    }

    setState(() => _isLoadingCollections = true);
    try {
      final collections = await _collectionService.getUserCollections();
      setState(() {
        _collections = collections;
        _isLoadingCollections = false;
      });
    } catch (e) {
      setState(() => _isLoadingCollections = false);
      if (mounted) {
        ErrorHandler.showError(context, 'Koleksiyonlar yüklenirken hata oluştu: $e');
      }
    }
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

  List<Collection> get _filteredCollections {
    var filtered = _collections;
    
    if (_collectionSearchQuery.isNotEmpty) {
      filtered = _collections.where((collection) =>
          collection.name.toLowerCase().contains(_collectionSearchQuery.toLowerCase()) ||
          collection.description.toLowerCase().contains(_collectionSearchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  Color _getCollectionColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  IconData _getCollectionIcon(int index) {
    final icons = [
      Icons.collections,
      Icons.favorite,
      Icons.star,
      Icons.bookmark,
      Icons.inventory_2,
      Icons.category,
      Icons.shopping_bag,
      Icons.local_offer,
    ];
    return icons[index % icons.length];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: false,
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
              child: RepaintBoundary(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _performSearch,
                  onTap: () {
                    // Klavye anında açılsın
                    _searchFocusNode.requestFocus();
                  },
                  textInputAction: TextInputAction.search,
                  keyboardType: TextInputType.text,
                  enableSuggestions: false,
                  autocorrect: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  enableInteractiveSelection: true,
                  textCapitalization: TextCapitalization.none,
                  maxLines: 1,
                  style: const TextStyle(),
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
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
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
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: RepaintBoundary(
            child: TextField(
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.none,
              enableSuggestions: false,
              autocorrect: false,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              enableInteractiveSelection: true,
              maxLines: 1,
              style: const TextStyle(),
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
          child: RefreshIndicator(
            onRefresh: () async {
              // Favorileri yenile
              setState(() {});
            },
            child: _filteredProducts.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                                  SizedBox(height: isSmallScreen ? 16 : 20),
                                  ElevatedButton.icon(
                                    onPressed: widget.onNavigateToMainPage,
                                    icon: const Icon(Icons.shopping_cart),
                                    label: const Text('Ürünlere Gözat'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
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
                  physics: const AlwaysScrollableScrollPhysics(),
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
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product, bool isSmallScreen, bool isTablet) {
    final isFavorite = widget.favoriteProducts.any((p) => p.id == product.id);
    final inCart = widget.cartProducts?.any((p) => p.id == product.id) ?? false;

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
                onFavoriteToggle: (p) => widget.onFavoriteToggle(p, showMessage: true),
                onAddToCart: (p) => widget.onAddToCart?.call(p, showMessage: true) ?? (_) {},
                onRemoveFromCart: (p) {},
                cartProducts: widget.cartProducts ?? [],
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
                    // Butonlar (Ana sayfadaki stil)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: isSmallScreen ? 28 : 32,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() {});
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
                        const SizedBox(width: 4),
                        Expanded(
                          child: SizedBox(
                            height: isSmallScreen ? 28 : 32,
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() {});
                                if (widget.onAddToCart != null) {
                                  widget.onAddToCart!(product);
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
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: RepaintBoundary(
            child: TextField(
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.none,
              enableSuggestions: false,
              autocorrect: false,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              enableInteractiveSelection: true,
              maxLines: 1,
              style: const TextStyle(),
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
          child: RefreshIndicator(
            onRefresh: _loadCollections,
            child: _buildCollectionsList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionsList() {
    final collections = _filteredCollections;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    if (_isLoadingCollections) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_auth.currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_bookmark_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Koleksiyonları görmek için giriş yapın',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (collections.isEmpty && _collectionSearchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_bookmark_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Henüz koleksiyonunuz yok',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni koleksiyon oluşturarak başlayın',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewCollection,
              icon: const Icon(Icons.add),
              label: const Text('Yeni Koleksiyon Oluştur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

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
        final color = _getCollectionColor(index);
        final icon = _getCollectionIcon(index);
        final productCount = collection.productIds.length;

        return Card(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: InkWell(
            onTap: () => _openCollection(collection.id),
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
                    color.withValues(alpha: 0.05),
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
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: isSmallScreen ? 22 : 28),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.name,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 15 : 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 3 : 4),
                        Text(
                          collection.description.isNotEmpty
                              ? collection.description
                              : 'Açıklama yok',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.grey[600],
                            fontStyle: collection.description.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
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
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$productCount ürün',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  color: color,
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
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Koleksiyon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Koleksiyon Adı',
                border: OutlineInputBorder(),
                hintText: 'Örn: Araç Aksesuarları',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama (İsteğe bağlı)',
                border: OutlineInputBorder(),
                hintText: 'Koleksiyonunuz hakkında kısa bir açıklama',
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
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ErrorHandler.showError(context, 'Koleksiyon adı boş olamaz');
                return;
              }

              Navigator.pop(context);

              try {
                final user = _auth.currentUser;
                if (user == null) {
                  ErrorHandler.showError(context, 'Koleksiyon oluşturmak için giriş yapmalısınız');
                  return;
                }

                final collection = Collection(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  description: descriptionController.text.trim(),
                  userId: user.uid,
                  productIds: [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await _collectionService.createCollection(collection);
                await _loadCollections();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"$name" koleksiyonu oluşturuldu!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ErrorHandler.showError(context, 'Koleksiyon oluşturulurken hata oluştu: $e');
                }
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _openCollection(String collectionId) async {
    final collection = _collections.firstWhere(
      (c) => c.id == collectionId,
      orElse: () => Collection(
        id: collectionId,
        name: '',
        description: '',
        userId: '',
        productIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KoleksiyonDetaySayfasi(collection: collection),
      ),
    );

    if (result == true) {
      _loadCollections();
    }
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
    final totalCollections = _collections.length;
    final totalProducts = _collections.fold<int>(
      0,
      (sum, collection) => sum + collection.productIds.length,
    );
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
              '$totalCollections',
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
              '$totalProducts',
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
              '${widget.favoriteProducts.length}',
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